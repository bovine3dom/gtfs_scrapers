local json = require("dkjson")
local utils = require("gtfs_utils")
local script_dir = arg[0]:match("(.*[/\\])") or ""
local config = dofile(script_dir .. "stop_config.lua")

local OUTPUT_DIR = "out"

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
    local services_written = {}

    for code, route in pairs(data) do
        local origin, dest = utils.split_route(route.name)

        if origin and dest then
            local origin_id = utils.canonicalize_id(origin)
            local dest_id   = utils.canonicalize_id(dest)
            for _, port_info in ipairs({ { id = origin_id, name = origin }, { id = dest_id, name = dest } }) do
                local port_name = port_info.name
                local port_id   = port_info.id

                if not config.stops[port_name] then
                    io.stderr:write("WARNING: Missing coordinates for: [" .. port_name .. "]\n")
                elseif not stops_written[port_id] then
                    local s = config.stops[port_name]
                    utils.write_gtfs_row(files.stops, "stops", {
                        stop_id = port_id,
                        stop_name = port_name,
                        stop_lat = s.lat,
                        stop_lon = s.lon
                    }, source_name)
                    stops_written[port_id] = true
                end
            end

            utils.write_gtfs_row(files.routes, "routes", {
                route_id = code,
                agency_id = config.agency.id,
                route_long_name = route.name,
                route_type = "4"
            }, source_name)

            for date, sailings in pairs(route.sailings) do
                local date_clean = date:gsub("-", "")
                local service_id = "SVC-" .. date_clean
                if not services_written[service_id] then
                    utils.write_gtfs_row(files.calendar_dates, "calendar_dates", {
                        service_id = service_id,
                        date = date_clean,
                        exception_type = "1"
                    }, source_name)
                    services_written[service_id] = true
                end

                for _, sailing in ipairs(sailings) do
                    local trip_id = sailing.departureId
                    utils.write_gtfs_row(files.trips, "trips", {
                        route_id = code,
                        service_id = service_id,
                        trip_id = trip_id,
                        trip_headsign = sailing.ferryName
                    }, source_name)

                    local dep_time = utils.format_gtfs_time(sailing.localDepartureTime, date)
                    local arr_time = utils.format_gtfs_time(sailing.localArrivalTime, date)

                    utils.write_gtfs_row(files.stop_times, "stop_times", {
                        trip_id = trip_id,
                        arrival_time = dep_time,
                        departure_time = dep_time,
                        stop_id = origin_id,
                        stop_sequence = "1"
                    }, source_name)
                    utils.write_gtfs_row(files.stop_times, "stop_times", {
                        trip_id = trip_id,
                        arrival_time = arr_time,
                        departure_time = arr_time,
                        stop_id = dest_id,
                        stop_sequence = "2"
                    }, source_name)
                end
            end
        end
    end

    for _, f in pairs(files) do f:close() end
    print("GTFS bundle generated in directory: " .. out_dir)
end

-- usage: lua stena_to_gtfs.lua [input.json] [output_directory]
local input_file = arg[1] or "stena_data.json"
local output_dir = arg[2]
run_conversion(input_file, output_dir)
