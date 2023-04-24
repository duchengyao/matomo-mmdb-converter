# Matomo mmdb Converter

Convert various geolocation formats to the MMDB (MaxMind GeoIP2 DB) format natively supported by Matomo.

## Installation

* `sudo apt-get install cpanminus`
* `cpanm MaxMind::DB::Writer`
* `cpanm IP::QQWry`
* `cpanm Text::CSV_XS`

## ip2location

> [ip2location-piwik](https://github.com/ip2location/ip2location-piwik) plugin of Matomo
> does not support Org and ISP display, use native `DBIP / GeoIP` plugin to attach Org and ISP database.

1. convert official csv from **ip number** to **ip address**: `$python ip2location-csv-converter.py -range -replace sample.csv sample-range.csv`
2. convert csv to mmdb: `$perl ip2location-converter.pl sample-range.csv sample-range.mmdb`   
3. test mmdb: `$python test-mmdb.py`

## TODO

* [x] ip2location to mmdb.
* [ ] qqwry to mmdb.
