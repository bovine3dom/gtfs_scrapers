local M = {}

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

function M.strip_diacritics(text)
    if not text then return "" end
    local s = text
    for k, v in pairs(M.CHAR_MAPPING) do
        s = s:gsub(k, v)
    end
    return s
end

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

function M.ensure_dir(path)
    os.execute("mkdir -p " .. path)
end

function M.read_file(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    return content
end

function M.escape_csv(val)
    val = tostring(val or "")
    if val:find('[,"]') then
        return '"' .. val:gsub('"', '""') .. '"'
    end
    return val
end

function M.write_csv(f, columns)
    local row = {}
    for i, col in ipairs(columns) do row[i] = M.escape_csv(col) end
    f:write(table.concat(row, ",") .. "\n")
end

function M.format_gtfs_time(iso_str, base_date)
    -- Expects ISO string like "2026-02-13T11:08:13"
    local date_part, time_part = iso_str:match("([^T]+)T([^%.]+)")
    if not date_part then return "00:00:00" end
    local h, m, s = time_part:match("(%d+):(%d+):(%d+)")
    if date_part ~= base_date then h = tonumber(h) + 24 end
    return string.format("%02d:%02d:%02d", h, m, s)
end

function M.split_route(name)
    local origin, dest = name:match("^(.-) \226\134\146 (.-)$") -- arrow
    if not origin then
        origin, dest = name:match("^(.-) %-> (.-)$")
    end
    return origin, dest
end

function M.swap_route(name)
    local a, b = M.split_route(name)
    if not a then return name end
    return b .. " \226\134\146 " .. a
end

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
