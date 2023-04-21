import maxminddb

with maxminddb.open_database('sample-range.mmdb') as reader:
    print(reader.get('1.0.80.254'))
