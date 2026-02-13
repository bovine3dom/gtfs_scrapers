package.path = package.path .. ";./common/?.lua"
local json = require("dkjson")
local utils = require("gtfs_utils")
local config = dofile("dfds/dfds_config.lua")

local API_BASE = "https://api.hellman.oxygen.dfds.cloud/prod/servicesunifiedbff/api/v2/departures"
local USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/122.0.0.0"

local fetch = utils.make_fetcher(USER_AGENT)

-- Note: DFDS API uses portCode as a filter. We'll iterate through all known ports.
-- Since one departure will show up for both the origin and destination port potentially,
-- we'll use a table keyed by departureId to deduplicate.

local function scrape(from_date, to_date)
    local all_departures = {}

    -- Format dates for API (YYYY-MM-DD -> YYYY-MM-DDT00:00:01Z)
    local from_iso       = from_date .. "T00:00:01Z"
    local to_iso         = to_date .. "T23:59:59Z"

    io.stderr:write(string.format("Scraping DFDS departures from %s to %s...\n", from_date, to_date))

    for _, port in ipairs(config.port_codes) do
        local url = string.format("%s?fromDate=%s&portCode=%s&toDate=%s",
            API_BASE, from_iso, port, to_iso)

        io.stderr:write(string.format("  Fetching port %s...\n", port))
        local code, raw = fetch(url)

        if code == 200 and raw then
            local data = json.decode(raw)
            if data and data.departures then
                for _, dep in ipairs(data.departures) do
                    all_departures[dep.departureId] = dep
                end
                io.stderr:write(string.format("    Found %d departures\n", #data.departures))
            end
        else
            io.stderr:write(string.format("    Failed to fetch port %s (code %s)\n", port, tostring(code)))
        end

        os.execute("sleep 0.1")
    end

    -- Convert de-duplicated map to list
    local final_list = {}
    for _, dep in pairs(all_departures) do
        table.insert(final_list, dep)
    end

    print(json.encode(final_list, { indent = true }))
end

local START = arg[1] or "2026-02-13"
local END   = arg[2] or "2026-02-21"

scrape(START, END)
