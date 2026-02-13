local M = {}

M.port_codes = {
    "AMS", "CQF", "DKK", "DPP", "DVR", "JER", "KAN", "KEL", "KLJ",
    "KPS", "NEW", "NHN", "PLA", "PME", "POO", "ROS", "STM", "TRG"
}

-- For GTFS conversion
M.agency = {
    id = "DFDS",
    name = "DFDS Seaways",
    url = "https://www.dfds.com",
    timezone = "Europe/London"
}

M.stops = {
    ["Rosslare"] = { lat = "52.25328689541537", lon = "-6.334779902411934" },
    ["Dunkirk"] = { lat = "51.020359424886635", lon = "2.1922982479533175" },
    ["Calais"] = { lat = "50.9667", lon = "1.8667" },
    ["Dover"] = { lat = "51.12664153974177", lon = "1.3300029576297447" },
    ["Amsterdam"] = { lat = "52.4631837", lon = "4.5861690" }, -- Felison Terminal (IJmuiden)
    ["Newcastle"] = { lat = "54.99211686211663", lon = "-1.450795138119446" },
    ["Dieppe"] = { lat = "49.93363", lon = "1.08805" },
    ["Newhaven"] = { lat = "50.7934543", lon = "0.0540304" },
    ["Klaipeda"] = { lat = "55.684167", lon = "21.144444" }, -- Central Terminal
    ["Kiel"] = { lat = "54.334093", lon = "10.174885" },     -- Ostuferhafen
    ["Travemünde"] = { lat = "53.940189257946535", lon = "10.852646845010023" },
    ["Karlshamn"] = { lat = "56.159804079572694", lon = "14.817635691844742" },
    ["St. Malo"] = { lat = "48.642572", lon = "-2.024215" },
    ["Jersey"] = { lat = "49.178419219362866", lon = "-2.1168741097119437" },
    ["Portsmouth"] = { lat = "50.811823", lon = "-1.088367" },
    ["Paldiski"] = { lat = "59.35007", lon = "24.04551" },
    ["Kapellskar"] = { lat = "59.7186414", lon = "19.0640070" },
    -- Add more as discovered
}

return M
