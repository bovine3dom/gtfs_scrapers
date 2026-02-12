local https = require("ssl.https")
local ltn12 = require("ltn12")
local json = require("dkjson")

local BASE_URL = "https://www.stenaline.co.uk"
local USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/122.0.0.0"

local function fetch(url)
    local chunks = {}
    local res, code, headers, status = https.request({
        url = url,
        method = "GET",
        headers = { ["User-Agent"] = USER_AGENT },
        sink = ltn12.sink.table(chunks)
    })
    return code, (code == 200 and table.concat(chunks) or nil)
end

local function slugify(text)
    if not text then return "" end
    local s = text:lower()
    local mapping = {
        ["ä"]="a", ["ö"]="o", ["ü"]="u", ["å"]="a", ["æ"]="ae", ["ø"]="o",
        ["ā"]="a", ["ē"]="e", ["ī"]="i", ["ļ"]="l", ["ņ"]="n", ["š"]="s", ["ž"]="z",
        ["ą"]="a", ["ć"]="c", ["ę"]="e", ["ł"]="l", ["ń"]="n", ["ó"]="o", ["ś"]="s", ["ź"]="z", ["ż"]="z"
    }
    for utf8_char, ascii_char in pairs(mapping) do
        s = s:gsub(utf8_char, ascii_char)
    end
    s = s:gsub(" \226\134\146 ", "-")
    s = s:gsub(" %-> ", "-")
    s = s:gsub("[^%a%d]", "-")
    s = s:gsub("%-+", "-")
    s = s:gsub("^%-", ""):gsub("%-$", "")
    return s
end

-- some stena routes redirect <->. but not all. :). :). :).
local function swap_direction(name)
    local a, b = name:match("^(.-) \226\134\146 (.-)$")
    if not a then return name end
    return b .. " \226\134\146 " .. a
end

local function get_date_range(start_str, end_str)
    local function parse(d) 
        local y, m, day = d:match("(%d+)-(%d+)-(%d+)")
        return os.time({year=y, month=m, day=day}) 
    end
    local current, ending = parse(start_str), parse(end_str)
    local dates = {}
    while current <= ending do
        table.insert(dates, os.date("%Y-%m-%d", current))
        current = current + 86400
    end
    return dates
end

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
                slug = slugify(label)
            }
        end
    end

    local final_list = {}
    for _, data in pairs(unique_routes) do table.insert(final_list, data) end
    
    table.sort(final_list, function(a,b) return a.code < b.code end)
    
    return final_list
end

local function scrape(start_date, end_date)
    local routes = discover_routes()
    local dates = get_date_range(start_date, end_date)
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
                local swapped_name = swap_direction(route.name)
                local slug2 = slugify(swapped_name)
                local url2 = string.format("%s/routes/%s/_jcr_content.timetable.%s.%s.json", BASE_URL, slug2, route.code, date)
                
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
