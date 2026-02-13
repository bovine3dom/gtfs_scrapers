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
                    utils.write_csv(files.stops, { port_id, port_name, s.lat, s.lon })
                    stops_written[port_id] = true
                end
            end

            utils.write_csv(files.routes, { code, config.agency.id, route.name, "4" })

            for date, sailings in pairs(route.sailings) do
                local service_id = "SVC-" .. date:gsub("-", "")
                if not services_written[service_id] then
                    utils.write_csv(files.calendar_dates, { service_id, date:gsub("-", ""), "1" })
                    services_written[service_id] = true
                end

                for _, sailing in ipairs(sailings) do
                    local trip_id = sailing.departureId
                    utils.write_csv(files.trips, { code, service_id, trip_id, sailing.ferryName })

                    local dep_time = utils.format_gtfs_time(sailing.localDepartureTime, date)
                    local arr_time = utils.format_gtfs_time(sailing.localArrivalTime, date)

                    utils.write_csv(files.stop_times, { trip_id, dep_time, dep_time, origin_id, "1" })
                    utils.write_csv(files.stop_times, { trip_id, arr_time, arr_time, dest_id, "2" })
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
