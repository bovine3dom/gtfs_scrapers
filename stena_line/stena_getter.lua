local json = require("dkjson")
local utils = require("gtfs_utils")

local BASE_URL = "https://www.stenaline.co.uk"
local USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/122.0.0.0"

local fetch = utils.make_fetcher(USER_AGENT)

local function discover_routes()
    io.stderr:write("Step 1: Finding seed route...\n")
    local code, main_html = fetch(BASE_URL .. "/routes")
    if code ~= 200 or not main_html then error("Failed to fetch /routes") end

    local seed_slug = main_html:match('href="[^"]-/routes/([%a%-]+)"')
    io.stderr:write("Step 2: Probing " .. seed_slug .. " for master list...\n")

    local code, route_html = fetch(BASE_URL .. "/routes/" .. seed_slug)
    if code ~= 200 or not route_html then error("Failed to fetch seed page") end

    local unique_routes = {}

    for code, label in route_html:gmatch('<option value="([%w]+)"[^>]*>([^<]+)</option>') do
        if code ~= "selectRoute" and not unique_routes[code] then
            unique_routes[code] = {
                code = code,
                name = label,
                slug = utils.slugify(label)
            }
        end
    end

    local final_list = {}
    for _, data in pairs(unique_routes) do table.insert(final_list, data) end

    table.sort(final_list, function(a, b) return a.code < b.code end)

    return final_list
end

local function scrape(start_date, end_date)
    local routes = discover_routes()
    local dates = utils.get_date_range(start_date, end_date)
    local results = {}

    io.stderr:write(string.format("Step 3: Crawling %d unique routes...\n", #routes))

    for _, route in ipairs(routes) do
        results[route.code] = {
            name = route.name,
            slug = route.slug,
            sailings = {}
        }

        for _, date in ipairs(dates) do
            local api_url = string.format("%s/routes/%s/_jcr_content.timetable.%s.%s.json",
                BASE_URL, route.slug, route.code, date)

            io.stderr:write(string.format("  Fetching %s (%s) for %s\n", route.slug, route.code, date))

            local code, raw = fetch(api_url)

            if code == 404 then
                local swapped_name = utils.swap_route(route.name)
                local slug2 = utils.slugify(swapped_name)
                local url2 = string.format("%s/routes/%s/_jcr_content.timetable.%s.%s.json", BASE_URL, slug2, route.code,
                    date)

                io.stderr:write(string.format("  [404] Retrying %s with swapped slug: %s\n", route.code, slug2))
                local code2, raw2 = fetch(url2)

                -- remember our victories
                if code2 == 200 then
                    route.slug = slug2
                    raw = raw2
                end
            end

            if raw then
                local data, _, err = json.decode(raw)
                if not err and type(data) == "table" and #data > 0 then
                    results[route.code].sailings[date] = data
                    io.stderr:write(string.format("  [OK] %s (%s)\n", route.code, date))
                else
                    io.stderr:write(string.format("  [EMPTY] %s (%s)\n", route.code, date))
                end
            end
            os.execute("sleep 0.2")
        end
    end

    print(json.encode(results, { indent = true }))
end

local START = arg[1] or "2026-02-13"
local END   = arg[2] or "2026-02-21"

scrape(START, END)
