#!/usr/bin/env python3
import json
import sys

pipelines_file = open('./build/geojson/pipelines-tmp.geojson')
pipelines = json.loads(pipelines_file.read())

releases_file = open('./build/data/releases.json')
releases = json.loads(releases_file.read())

fc = {
  'type': 'FeatureCollection',
  'features': []
}

for f in pipelines['features']:
  feat = f
  if 'ORIG_LICNO' in f['properties']:
    if f['properties']['ORIG_LICNO'] in releases:
      feat['properties'].update(releases[f['properties']['ORIG_LICNO']])
  fc['features'].append(feat)

outputfile = open('./build/geojson/pipelines.geojson','w')
json = json.dumps(fc)
outputfile.write(json)
outputfile.close()
