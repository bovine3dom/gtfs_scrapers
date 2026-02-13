# GTFS Scrapers

A collection of ferry schedule scrapers and GTFS converters. that i really didn't want to write. hey guys please obey eu law? that would be nice? https://transport.ec.europa.eu/transport-themes/smart-mobility/road/its-directive-and-action-plan/national-access-points_en

## Data for your convenience

see release/. cc0.

## Setup

```bash
luarocks install luasocket
luarocks install luasec
luarocks install dkjson
```

which should in theory generate you a local lua environment. with ./lua and ./luarocks.

## Running Scrapers

### Stena Line

To scrape data:
```bash
./lua stena_line/stena_getter.lua 2026-02-13 2026-02-20 > stena_data.json
```

To convert to GTFS:
```bash
./lua stena_line/stena_to_gtfs.lua stena_data.json stena_gtfs/
```

### DFDS

To scrape data:
```bash
./lua dfds/dfds_getter.lua 2026-02-13 2026-02-20 > dfds_data.json
```

NB: large windows will be capped at 500 departures

To convert to GTFS:
```bash
./lua dfds/dfds_to_gtfs.lua dfds_data.json dfds_gtfs/
```

## Project Structure

- `common/`: Shared Lua utilities for scraping and GTFS conversion.
- `lua`: Shell wrapper for the local Lua environment (includes `common` and `lua_modules` in path).
- `luarocks`: Shell wrapper for LuaRocks targeting the local `lua_modules`.
- `stena_line/`: Stena Line specific scraper and converter.
- `dfds/`: DFDS specific scraper.
