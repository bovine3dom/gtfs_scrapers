# Install dependencies
```
luarocks install luasocket
luarocks install luasec
luarocks install dkjson
```

# Run and save to file
```
./lua stena_scraper.lua 2026-02-13 2026-02-20 > ferry_times.json
./lua stena_to_gtfs.lua ferry_times.json gtfs_out/
cd gtfs_out/
7za a pls.zip *
```
