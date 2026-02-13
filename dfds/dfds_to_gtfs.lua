package.path = package.path .. ";./common/?.lua"
local json = require("dkjson")
local utils = require("gtfs_utils")
local config = dofile("dfds/dfds_config.lua")

local OUTPUT_DIR = "dfds_out"

local function run_conversion(input_path, out_dir)
    out_dir = out_dir or OUTPUT_DIR or "./gtfs_out"
    utils.ensure_dir(out_dir)

    local data = json.decode(utils.read_file(input_path))
    if not data then error("Invalid JSON input: " .. tostring(input_path)) end

    local function open_gtfs(filename)
        local path = out_dir:gsub("/$", "") .. "/" .. filename
        local f, err = io.open(path, "w")
        if not f then error("Could not open " .. path .. ": " .. err) end
        return f
    end

    local files = {
        agency = open_gtfs("agency.txt"),
        stops = open_gtfs("stops.txt"),
        routes = open_gtfs("routes.txt"),
        trips = open_gtfs("trips.txt"),
        stop_times = open_gtfs("stop_times.txt"),
        calendar_dates = open_gtfs("calendar_dates.txt")
    }

    utils.write_csv(files.agency, { "agency_id", "agency_name", "agency_url", "agency_timezone" })
    utils.write_csv(files.stops, { "stop_id", "stop_name", "stop_lat", "stop_lon" })
    utils.write_csv(files.routes, { "route_id", "agency_id", "route_long_name", "route_type" })
    utils.write_csv(files.trips, { "route_id", "service_id", "trip_id", "trip_headsign" })
    utils.write_csv(files.stop_times, { "trip_id", "arrival_time", "departure_time", "stop_id", "stop_sequence" })
    utils.write_csv(files.calendar_dates, { "service_id", "date", "exception_type" })

    utils.write_csv(files.agency, { config.agency.id, config.agency.name, config.agency.url, config.agency.timezone })

    local stops_written = {}
    local routes_written = {}
    local services_written = {}

    for _, dep in ipairs(data) do
        local origin     = dep.route.departurePort
        local dest       = dep.route.arrivalPort

        local route_id   = origin.code .. dest.code
        local route_name = origin.name .. " — " .. dest.name

        -- Write stops
        for _, port in ipairs({ origin, dest }) do
            local port_id = port.code
            if not stops_written[port_id] then
                local coords = config.stops[port.name]
                if coords then
                    utils.write_csv(files.stops, { port_id, port.name, coords.lat, coords.lon })
                    stops_written[port_id] = true
                else
                    io.stderr:write("WARNING: Missing coordinates for: [" .. port.name .. "]\n")
                end
            end
        end

        -- Write route
        if not routes_written[route_id] then
            utils.write_csv(files.routes, { route_id, config.agency.id, route_name, "4" })
            routes_written[route_id] = true
        end

        -- Write service/calendar_dates
        local dep_date = dep.scheduledDepartureTime:match("^(%d%d%d%d%-%d%d%-%d%d)")
        local service_id = "SVC-" .. dep_date:gsub("-", "")
        if not services_written[service_id] then
            utils.write_csv(files.calendar_dates, { service_id, dep_date:gsub("-", ""), "1" })
            services_written[service_id] = true
        end

        -- Write trip
        local trip_id = dep.departureId
        utils.write_csv(files.trips, { route_id, service_id, trip_id, "" })

        -- Write stop times
        local dep_time = utils.format_gtfs_time(dep.scheduledDepartureTime, dep_date)
        local arr_time = utils.format_gtfs_time(dep.scheduledArrivalTime, dep_date)

        utils.write_csv(files.stop_times, { trip_id, dep_time, dep_time, origin.code, "1" })
        utils.write_csv(files.stop_times, { trip_id, arr_time, arr_time, dest.code, "2" })
    end

    for _, f in pairs(files) do f:close() end
    print("GTFS bundle generated in directory: " .. out_dir)
end

-- usage: lua dfds_to_gtfs.lua [input.json] [output_directory]
local input_file = arg[1] or "dfds_data.json"
local output_dir = arg[2]
run_conversion(input_file, output_dir)
