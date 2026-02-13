--- Common utilities for GTFS scraping projects.
local M = {}

--- Canonical GTFS column definitions as expected by the SQL scripts.
M.COLUMNS = {
    agency = {
        "source", "agency_id", "agency_name", "agency_url", "agency_timezone",
        "agency_email", "agency_fare_url", "agency_lang", "agency_phone"
    },
    stops = {
        "source", "stop_id", "stop_code", "stop_name", "stop_desc",
        "stop_lat", "stop_lon", "zone_id", "stop_url", "location_type",
        "parent_station", "stop_timezone", "wheelchair_boarding", "level_id", "platform_code"
    },
    routes = {
        "source", "route_id", "agency_id", "route_short_name", "route_long_name",
        "route_desc", "route_type", "route_url", "route_color", "route_text_color",
        "route_sort_order", "continuous_pickup", "continuous_drop_off"
    },
    trips = {
        "source", "route_id", "service_id", "trip_id", "trip_headsign",
        "trip_short_name", "direction_id", "block_id", "shape_id",
        "wheelchair_accessible", "bikes_allowed"
    },
    stop_times = {
        "source", "trip_id", "arrival_time", "departure_time", "stop_id",
        "stop_sequence", "stop_headsign", "pickup_type", "drop_off_type",
        "continuous_pickup", "continuous_drop_off", "shape_dist_traveled",
        "timepoint", "local_zone_id"
    },
    calendar = {
        "source", "service_id", "monday", "tuesday", "wednesday", "thursday",
        "friday", "saturday", "sunday", "start_date", "end_date"
    },
    calendar_dates = {
        "source", "service_id", "date", "exception_type"
    }
}

--- Default values for certain columns if not provided.
M.DEFAULTS = {
    stops = {
        location_type = "0",
        wheelchair_boarding = "1"
    },
    routes = {
        route_type = "4", -- Ferry
        route_color = "000000",
        route_text_color = "FFFFFF"
    },
    trips = {
        wheelchair_accessible = "1",
        bikes_allowed = "1"
    },
    stop_times = {
        pickup_type = "0",
        drop_off_type = "0",
        timepoint = "1"
    },
    agency = {
        agency_lang = "en"
    }
}

--- Mapping of accented/Unicode characters to their ASCII equivalents.
M.CHAR_MAPPING = {
    ["ą"] = "a",
    ["ć"] = "c",
    ["ę"] = "e",
    ["ł"] = "l",
    ["ń"] = "n",
    ["ó"] = "o",
    ["ś"] = "s",
    ["ź"] = "z",
    ["ż"] = "z",
    ["Ą"] = "A",
    ["Ć"] = "C",
    ["Ę"] = "E",
    ["Ł"] = "L",
    ["Ń"] = "N",
    ["Ó"] = "O",
    ["Ś"] = "S",
    ["Ź"] = "Z",
    ["Ż"] = "Z",
    ["ā"] = "a",
    ["č"] = "c",
    ["ē"] = "e",
    ["ģ"] = "g",
    ["ī"] = "i",
    ["ķ"] = "k",
    ["ļ"] = "l",
    ["ņ"] = "n",
    ["š"] = "s",
    ["ū"] = "u",
    ["ž"] = "z",
    ["Ā"] = "A",
    ["Č"] = "C",
    ["Ē"] = "E",
    ["Ģ"] = "G",
    ["Ī"] = "I",
    ["Ķ"] = "K",
    ["Ļ"] = "L",
    ["Ņ"] = "N",
    ["Š"] = "S",
    ["Ū"] = "U",
    ["Ž"] = "Z",
    ["į"] = "i",
    ["ų"] = "u",
    ["Į"] = "I",
    ["Ų"] = "U",
    ["ä"] = "a",
    ["ö"] = "o",
    ["ü"] = "u",
    ["ß"] = "ss",
    ["å"] = "a",
    ["æ"] = "ae",
    ["ø"] = "o",
    ["Ä"] = "A",
    ["Ö"] = "O",
    ["Ü"] = "U",
    ["Å"] = "A",
    ["Æ"] = "AE",
    ["Ø"] = "O",
    ["á"] = "a",
    ["é"] = "e",
    ["í"] = "i",
    ["ú"] = "u",
    ["ñ"] = "n",
    ["Á"] = "A",
    ["É"] = "E",
    ["Í"] = "I",
    ["Ú"] = "U",
    ["Ñ"] = "N"
}

--- Replaces accented characters with their base ASCII equivalents.
-- @param text string The text to process.
-- @return string The text with diacritics removed.
function M.strip_diacritics(text)
    if not text then return "" end
    local s = text
    for k, v in pairs(M.CHAR_MAPPING) do
        s = s:gsub(k, v)
    end
    return s
end

--- Converts a string into a canonical ID (uppercase, alphanumeric, underscores).
-- Useful for generating stop_ids from port names.
-- @param text string The input text (e.g., "Gdańsk").
-- @return string The canonical ID (e.g., "GDANSK").
function M.canonicalize_id(text)
    if not text then return "UNKNOWN" end
    local s = M.strip_diacritics(text)
    s = s:upper()
    s = s:gsub("[^A-Z0-9]", "_")
    s = s:gsub("_+", "_")
    s = s:gsub("^_", "")
    s = s:gsub("_$", "")
    return s
end

--- Converts a string into a URL-friendly slug.
-- @param text string The input text.
-- @return string The slugified text.
function M.slugify(text)
    if not text then return "" end
    local s = M.strip_diacritics(text:lower())
    s = s:gsub(" \226\134\146 ", "-") -- arrow
    s = s:gsub(" %-> ", "-")
    s = s:gsub("[^%a%d]", "-")
    s = s:gsub("%-+", "-")
    s = s:gsub("^%-", ""):gsub("%-$", "")
    return s
end

--- Ensures a directory exists by running mkdir -p.
-- @param path string The directory path to ensure.
function M.ensure_dir(path)
    os.execute("mkdir -p " .. path)
end

--- Reads the entire contents of a file.
-- @param path string The path to the file.
-- @return string|nil The file contents, or nil if the file could not be opened.
function M.read_file(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    return content
end

--- Escapes a value for inclusion in a CSV file.
-- @param val any The value to escape.
-- @return string The CSV-safe string.
function M.escape_csv(val)
    val = tostring(val or "")
    if val:find('[,"]') then
        return '"' .. val:gsub('"', '""') .. '"'
    end
    return val
end

--- Writes a row of columns to a file in CSV format.
-- @param f file The file handle to write to.
-- @param columns table An array of values for the CSV columns.
function M.write_csv(f, columns)
    local row = {}
    for i, col in ipairs(columns) do row[i] = M.escape_csv(col) end
    f:write(table.concat(row, ",") .. "\n")
end

--- Writes the header for a GTFS file based on the canonical column definitions.
-- @param f file The file handle.
-- @param file_type string The GTFS file type (e.g., "stops").
function M.write_gtfs_header(f, file_type)
    local columns = M.COLUMNS[file_type]
    if not columns then error("Unknown GTFS file type: " .. tostring(file_type)) end
    M.write_csv(f, columns)
end

--- Writes a row to a GTFS file, ensuring all canonical columns are present.
-- @param f file The file handle.
-- @param file_type string The GTFS file type.
-- @param data table A table mapping column names to values.
-- @param source_name string The value for the "source" column.
function M.write_gtfs_row(f, file_type, data, source_name)
    local columns = M.COLUMNS[file_type]
    if not columns then error("Unknown GTFS file type: " .. tostring(file_type)) end
    local row = {}
    local defaults = M.DEFAULTS[file_type] or {}
    for i, col in ipairs(columns) do
        local val = data[col]
        if (val == nil or val == "") and defaults[col] then
            val = defaults[col]
        end
        if col == "source" then val = source_name end
        row[i] = val or ""
    end
    M.write_csv(f, row)
end

--- Formats an ISO-8601 datetime string into a GTFS-compliant HHH:MM:SS format.
-- Handles trips that cross midnight by comparing with the base_date.
-- @param iso_str string The ISO-8601 string (e.g., "2026-02-13T01:30:00").
-- @param base_date string The service date as YYYY-MM-DD.
-- @return string The GTFS time string (e.g., "25:30:00" for 1am the next day).
function M.format_gtfs_time(iso_str, base_date)
    local date_part, time_part = iso_str:match("([^T]+)T([^%.]+)")
    if not date_part then return "00:00:00" end
    local h, m, s = time_part:match("(%d+):(%d+):(%d+)")
    if date_part ~= base_date then h = tonumber(h) + 24 end
    return string.format("%02d:%02d:%02d", h, m, s)
end

--- Splits a route name into origin and destination.
-- Supports both UTF-8 arrows and "->" markers.
-- @param name string The route name (e.g., "London -> Paris").
-- @return string, string The origin and destination names.
function M.split_route(name)
    local origin, dest = name:match("^(.-) \226\134\146 (.-)$") -- arrow
    if not origin then
        origin, dest = name:match("^(.-) %-> (.-)$")
    end
    return origin, dest
end

--- Reverses the direction of a route name.
-- @param name string The route name.
-- @return string The reversed route name (or original if it couldn't be split).
function M.swap_route(name)
    local a, b = M.split_route(name)
    if not a then return name end
    return b .. " \226\134\146 " .. a
end

--- Generates a list of YYYY-MM-DD strings for a given range.
-- @param start_str string The start date (YYYY-MM-DD).
-- @param end_str string The end date (YYYY-MM-DD).
-- @return table An array of date strings.
function M.get_date_range(start_str, end_str)
    local function parse(d)
        local y, m, day = d:match("(%d+)-(%d+)-(%d+)")
        if not y then return os.time() end
        return os.time({ year = y, month = m, day = day })
    end
    local current, ending = parse(start_str), parse(end_str)
    local dates = {}
    while current <= ending do
        table.insert(dates, os.date("%Y-%m-%d", current))
        current = current + 86400
    end
    return dates
end

--- Returns a closure for fetching URLs with a specific User-Agent.
-- Requires luasec and luasocket to be installed.
-- @param user_agent string The User-Agent header to use.
-- @return function A function that takes a URL and returns (status_code, body).
function M.make_fetcher(user_agent)
    local https = require("ssl.https")
    local ltn12 = require("ltn12")
    return function(url)
        local chunks = {}
        local res, code, headers, status = https.request({
            url = url,
            method = "GET",
            headers = { ["User-Agent"] = user_agent },
            sink = ltn12.sink.table(chunks)
        })
        return code, (code == 200 and table.concat(chunks) or nil)
    end
end

return M
