#!/usr/bin/env python3

###
# join_geojson_data.py
###
# Adds json data from a file into matching features property
# in the provided GeoJSON file.
###
# Options
# -i, --input: the input geojson
# -j, --join: the join data file
# -k, --key: the key to match against in the GeoJSON properties
# -o, --output: the GeoJSON output file
###
# e.g.
# Input GeoJSON:
# {
#   'properties': { 'id': 'foo' },
#   'geometry': { ... }
# }
#
# Input Join Data:
# {
#   'foo': { 'data': 'sample', 'color': 'red' }
# }
#
# Key: 'id'
#
# Output: 
# {
#   'properties': { 'id': 'foo', 'data': 'sample', 'color': 'red' },
#   'geometry': { ... }
# }
###
import json
import sys
import argparse

parser = argparse.ArgumentParser(description='Merges json data into GeoJSON features')
parser.add_argument('-i','--input', dest='geojson', required=True, help='a GeoJSON file to merge data into')
parser.add_argument('-k','--key', dest='key', required=True, help='The GeoJSON feature\'s properties object key to use for the join')
parser.add_argument('-j','--join', dest='join', required=True, help='the JSON file that contains the data to merge into the GeoJSON properties')
parser.add_argument('-o','--output', dest='output', default=False, help='output GeoJSON file')

args = parser.parse_args()

input_geojson = args.geojson
input_join = args.join
output_geojson = args.output
join_key = args.key

pipelines_file = open(input_geojson)
pipelines = json.loads(pipelines_file.read())

releases_file = open(input_join)
releases = json.loads(releases_file.read())

fc = {
  'type': 'FeatureCollection',
  'features': []
}

# Join the data from the file
for f in pipelines['features']:
  feat = f
  if join_key in f['properties']:
    if f['properties'][join_key] in releases:
      feat['properties'].update(releases[f['properties'][join_key]])
  fc['features'].append(feat)

# Output JSON
json = json.dumps(fc)
if output_geojson == False:
  print(json)
else:
  outputfile = open(output_geojson,'w')
  outputfile.write(json)
  outputfile.close()
