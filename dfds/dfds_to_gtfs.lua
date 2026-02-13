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
        calendar = open_gtfs("calendar.txt"),
        calendar_dates = open_gtfs("calendar_dates.txt")
    }

    local source_name = config.agency.id:lower()

    for k, f in pairs(files) do
        utils.write_gtfs_header(f, k)
    end

    utils.write_gtfs_row(files.agency, "agency", {
        agency_id = config.agency.id,
        agency_name = config.agency.name,
        agency_url = config.agency.url,
        agency_timezone = config.agency.timezone
    }, source_name)

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
                    utils.write_gtfs_row(files.stops, "stops", {
                        stop_id = port_id,
                        stop_name = port.name,
                        stop_lat = coords.lat,
                        stop_lon = coords.lon
                    }, source_name)
                    stops_written[port_id] = true
                else
                    io.stderr:write("WARNING: Missing coordinates for: [" .. port.name .. "]\n")
                end
            end
        end

        -- Write route
        if not routes_written[route_id] then
            utils.write_gtfs_row(files.routes, "routes", {
                route_id = route_id,
                agency_id = config.agency.id,
                route_long_name = route_name,
                route_type = "4"
            }, source_name)
            routes_written[route_id] = true
        end

        -- Write service/calendar_dates
        local dep_date = dep.scheduledDepartureTime:match("^(%d%d%d%d%-%d%d%-%d%d)")
        local date_clean = dep_date:gsub("-", "")
        local service_id = "SVC-" .. date_clean
        if not services_written[service_id] then
            utils.write_gtfs_row(files.calendar_dates, "calendar_dates", {
                service_id = service_id,
                date = date_clean,
                exception_type = "1"
            }, source_name)
            services_written[service_id] = true
        end

        -- Write trip
        local trip_id = dep.departureId
        utils.write_gtfs_row(files.trips, "trips", {
            route_id = route_id,
            service_id = service_id,
            trip_id = trip_id,
            trip_headsign = ""
        }, source_name)

        -- Write stop times
        local dep_time = utils.format_gtfs_time(dep.scheduledDepartureTime, dep_date)
        local arr_time = utils.format_gtfs_time(dep.scheduledArrivalTime, dep_date)

        utils.write_gtfs_row(files.stop_times, "stop_times", {
            trip_id = trip_id,
            arrival_time = dep_time,
            departure_time = dep_time,
            stop_id = origin.code,
            stop_sequence = "1"
        }, source_name)
        utils.write_gtfs_row(files.stop_times, "stop_times", {
            trip_id = trip_id,
            arrival_time = arr_time,
            departure_time = arr_time,
            stop_id = dest.code,
            stop_sequence = "2"
        }, source_name)
    end

    for _, f in pairs(files) do f:close() end
    print("GTFS bundle generated in directory: " .. out_dir)
end

-- usage: lua dfds_to_gtfs.lua [input.json] [output_directory]
local input_file = arg[1] or "dfds_data.json"
local output_dir = arg[2]
run_conversion(input_file, output_dir)
