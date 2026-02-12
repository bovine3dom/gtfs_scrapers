local json = require("dkjson")
local config = dofile("stop_config.lua")

local OUTPUT_DIR = "out"

local function ensure_dir(path)
    os.execute("mkdir -p " .. path) -- it'lll probably work on wsl right
end

local function canonicalize_id(text)
    if not text then return "UNKNOWN" end

    -- apparently this doesn't exist in the standard library!?
    local replacements = {
        ["ą"]="a", ["ć"]="c", ["ę"]="e", ["ł"]="l", ["ń"]="n", ["ó"]="o", ["ś"]="s", ["ź"]="z", ["ż"]="z",
        ["Ą"]="A", ["Ć"]="C", ["Ę"]="E", ["Ł"]="L", ["Ń"]="N", ["Ó"]="O", ["Ś"]="S", ["Ź"]="Z", ["Ż"]="Z",
        ["ā"]="a", ["č"]="c", ["ē"]="e", ["ģ"]="g", ["ī"]="i", ["ķ"]="k", ["ļ"]="l", ["ņ"]="n", ["š"]="s", ["ū"]="u", ["ž"]="z",
        ["Ā"]="A", ["Č"]="C", ["Ē"]="E", ["Ģ"]="G", ["Ī"]="I", ["Ķ"]="K", ["Ļ"]="L", ["Ņ"]="N", ["Š"]="S", ["Ū"]="U", ["Ž"]="Z",
        ["į"]="i", ["ų"]="u", ["Į"]="I", ["Ų"]="U",
        ["ä"]="a", ["ö"]="o", ["ü"]="u", ["ß"]="ss", ["å"]="a", ["æ"]="ae", ["ø"]="o",
        ["Ä"]="A", ["Ö"]="O", ["Ü"]="U", ["Å"]="A", ["Æ"]="AE", ["Ø"]="O",
        ["á"]="a", ["é"]="e", ["í"]="i", ["ó"]="o", ["ú"]="u", ["ñ"]="n",
        ["Á"]="A", ["É"]="E", ["Í"]="I", ["Ó"]="O", ["Ú"]="U", ["Ñ"]="N"
    }

    local s = text
    for k, v in pairs(replacements) do
        s = s:gsub(k, v)
    end

    s = s:upper()
    s = s:gsub("[^A-Z0-9]", "_")
    s = s:gsub("_+", "_")
    s = s:gsub("^_", "")
    s = s:gsub("_$", "")
    
    return s
end

local function read_file(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    return content
end

local function escape_csv(val)
    val = tostring(val or "")
    if val:find('[,"]') then
        return '"' .. val:gsub('"', '""') .. '"'
    end
    return val
end

local function write_csv(f, columns)
    local row = {}
    for i, col in ipairs(columns) do row[i] = escape_csv(col) end
    f:write(table.concat(row, ",") .. "\n")
end

local function format_gtfs_time(iso_str, base_date)
    local date_part, time_part = iso_str:match("([^T]+)T([^%.]+)")
    local h, m, s = time_part:match("(%d+):(%d+):(%d+)")
    if date_part ~= base_date then h = tonumber(h) + 24 end
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function split_route_name(name)
    local origin, dest = name:match("^(.-) \226\134\146 (.-)$") -- magic utf code for arrow
    if not origin then
        origin, dest = name:match("^(.-) %-> (.-)$")
    end
    return origin, dest
end

local function run_conversion(input_path, out_dir)
    out_dir = out_dir or OUPUT_DIR or "./gtfs_out"
    ensure_dir(out_dir)
    
    local data = json.decode(read_file(input_path))
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

    write_csv(files.agency, {"agency_id", "agency_name", "agency_url", "agency_timezone"})
    write_csv(files.stops, {"stop_id", "stop_name", "stop_lat", "stop_lon"})
    write_csv(files.routes, {"route_id", "agency_id", "route_long_name", "route_type"})
    write_csv(files.trips, {"route_id", "service_id", "trip_id", "trip_headsign"})
    write_csv(files.stop_times, {"trip_id", "arrival_time", "departure_time", "stop_id", "stop_sequence"})
    write_csv(files.calendar_dates, {"service_id", "date", "exception_type"})

    write_csv(files.agency, {config.agency.id, config.agency.name, config.agency.url, config.agency.timezone})

    local stops_written = {}
    local services_written = {}

    for code, route in pairs(data) do
        local origin, dest = split_route_name(route.name)
        
        if origin and dest then
            local origin_id = canonicalize_id(origin)
            local dest_id   = canonicalize_id(dest)
            for _, port_info in ipairs({{id=origin_id, name=origin}, {id=dest_id, name=dest}}) do
                local port_name = port_info.name
                local port_id   = port_info.id

                if not config.stops[port_name] then
                    io.stderr:write("WARNING: Missing coordinates for: [" .. port_name .. "]\n")
                elseif not stops_written[port_id] then
                    local s = config.stops[port_name]
                    write_csv(files.stops, {port_id, port_name, s.lat, s.lon})
                    stops_written[port_id] = true
                end
            end

            write_csv(files.routes, {code, config.agency.id, route.name, "4"})

            for date, sailings in pairs(route.sailings) do
                local service_id = "SVC-" .. date:gsub("-", "")
                if not services_written[service_id] then
                    write_csv(files.calendar_dates, {service_id, date:gsub("-", ""), "1"})
                    services_written[service_id] = true
                end

                for _, sailing in ipairs(sailings) do
                    local trip_id = sailing.departureId
                    write_csv(files.trips, {code, service_id, trip_id, sailing.ferryName})

                    local dep_time = format_gtfs_time(sailing.localDepartureTime, date)
                    local arr_time = format_gtfs_time(sailing.localArrivalTime, date)

                    write_csv(files.stop_times, {trip_id, dep_time, dep_time, origin_id, "1"})
                    write_csv(files.stop_times, {trip_id, arr_time, arr_time, dest_id, "2"})
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
