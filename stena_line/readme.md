# Stena Line Scraper

This directory contains logic specifically for scraping Stena Line ferry schedules.

## Usage

Run these commands from the **project root** once the environment has been set up.

### 1. Scrape Schedule
```bash
./lua stena_line/stena_getter.lua 2026-02-13 2026-02-20 > stena_data.json
```

### 2. Convert to GTFS
```bash
./lua stena_line/stena_to_gtfs.lua stena_data.json stena_gtfs/
```

### 3. Package GTFS
```bash
cd stena_gtfs/
zip -r stena_bundle.zip *.txt
```

## Configuration
Stop coordinates and agency info are located in `stop_config.lua`.
