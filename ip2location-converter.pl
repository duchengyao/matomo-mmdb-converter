#!/usr/bin/env perl

# Maxmind DB Docs:
# https://maxmind.github.io/MaxMind-DB/
# https://metacpan.org/pod/MaxMind::DB::Writer::Tree#DATA-TYPES

use strict;
use warnings;
use feature qw(say);
use local::lib 'local';
use MaxMind::DB::Writer::Tree;
use Net::Works::Network;
use Data::Printer;
use Text::CSV_XS;

my ($inputFile, $outputFile, $ipver) = @ARGV;

my $blocks_csv = Text::CSV_XS->new(
    {
        binary => 1,
    });

open my $fh, "<:encoding(utf8)", $inputFile or die "$inputFile: $!";

say("converting " . $inputFile . " into " . $outputFile);

my $ip_from;
my $ip_to;
my $country_code;
my $country_name;
my $region_name;
my $city_name;
my $latitude;
my $longitude;
my $zip_code;
my $time_zone;

if (not defined $inputFile) {
    die("Missing input file");
}

if (not defined $outputFile) {
    die("Missing output file");
}

my $ip_version = 6;
if (not defined $ipver) {
    say("No ip version specified, using IPv6");
}
else {
    if ($ipver == '4') {
        $ip_version = 4;
    }
}

$blocks_csv->bind_columns(
    \$ip_from,
    \$ip_to,
    \$country_code,
    \$country_name,
    \$region_name,
    \$city_name,
    \$latitude,
    \$longitude,
    \$zip_code,
    \$time_zone);

# Our top level data structure will always be a map (hash).  The MMDB format
# is strongly typed. Describe your data types here.
# See https://metacpan.org/pod/MaxMind::DB::Writer::Tree#DATA-TYPES

my %types = (
    city                 => 'map',
    continent            => 'map',
    country              => 'map',
    location             => 'map',
    subdivisions         => 'map',
    postal               => 'map',
    names                => 'map',
    en                   => 'utf8_string',
    code                 => 'utf8_string',
    geoname_id           => 'uint32',
    iso_code             => 'utf8_string',
    latitude             => 'double',
    longitude            => 'double',
    time_zone            => 'utf8_string',
    is_in_european_union => 'boolean'
);

my $tree = MaxMind::DB::Writer::Tree->new(
    # "database_type" is some arbitrary string describing the database.  At
    # MaxMind we use strings like 'GeoIP2-City', 'GeoIP2-Country', etc.
    database_type         => 'GeoIP2-City',

    # "description" is a hashref where the keys are language names and the
    # values are descriptions of the database in that language.
    description           =>
        { en => 'Combined GeoIP Data' },

    # "ip_version" can be either 4 or 6
    ip_version            => $ip_version,

    # add a callback to validate data going in to the database
    map_key_type_callback => sub {$types{ $_[0] }},

    # "record_size" is the record size in bits.  Either 24, 28 or 32.
    # This is the max size of the pointer that should be able to point anywhere in the resulting file.
    # Max supported file sizes:
    # 24: 16.7MB
    # 28: 268MB
    # 32: 4.2GB
    record_size           => 28,

    merge_strategy        => "recurse"
);

while ($blocks_csv->getline($fh)) {
    $tree->insert_range($ip_from, $ip_to, {
        city         => {
            names => {
                en => $city_name
            }
        },

        subdivisions => {
            names => {
                en => $region_name
            }
        },

        country      => {
            iso_code => $country_code,

            names    => {
                en => $country_name
            }
        },
        location     => {
            latitude  => $latitude,
            longitude => $longitude,
            time_zone => $time_zone
        },
        postal       => {
            code => $zip_code
        }
    });
}

# Checking for End-of-file
if (not $blocks_csv->eof) {
    $blocks_csv->error_diag();
}
close $fh;

# Write the database to disk.
open $fh, '>:raw', $outputFile;
$tree->write_tree($fh);
close $fh;