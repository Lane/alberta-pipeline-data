#!/usr/bin/env python3
import csv
import json
import sys
import argparse
import datetime
import pytz

# epoch is the beginning of time in the UTC timestamp world
epoch = datetime.datetime(1970,1,1,0,0,0,tzinfo=pytz.UTC)

parser = argparse.ArgumentParser(description='Merges json data into GeoJSON features')
parser.add_argument('-i','--input', dest='csv', required=True, help='CSV file to generate GeoJSON from')
parser.add_argument('-o','--output', dest='output', default=False, help='output GeoJSON file')

args = parser.parse_args()
csvfile = args.csv
inputfile = csv.reader(open(csvfile,'r'))

collect_types = [
  "Process Water",
  "Salt (Inorganic)",
  "Hydrotest Fluids (Methanol)",
  "Corrosion Inhibited Water",
  "Crude Oil",
  "Drilling Mud  (Water Based)",
  "Oily Sludge",
  "Crude Bitumen",
  "Condensate",
  "Waste",
  "Salt/Produced Water",
  "Gasoline",
  "Diesel Oil",
  "Liquid Petroleum Gas",
  "Chemicals",
  "Synthetic Crude Oil",
  "Drilling Mud (HC Based)"
]

ROWMAP = {
  "id": 1,
  "pipeline_id": 0,
  "lat": 2,
  "lon": 3,
  "date": 4,
  "source": 5,
  "subs1": 7,
  "subs2": 10,
  "subs3": 13,
  "subs4": 16,
}
release_types = open('data/release_types.json')
TYPES = json.loads(release_types.read())

def getTimestamp(d):
  time = datetime.datetime.strptime(d, '%Y-%m-%d')

  # add proper timezone for the date
  pst = pytz.timezone('America/Los_Angeles')
  time = pst.localize(time)

  # convert to UTC timezone 
  utc = pytz.UTC 
  time = time.astimezone(utc)
  ts = (time - epoch).total_seconds()
  return(int(ts))

# converts the value to m^3
def normalizeVolume(val, unit):
  try:
    if unit == '103m3':
      volume = float(val) * 1000
    elif unit == 'm3':
      volume = float(val) * 1
    else:
      volume = float(val) * 1
  except ValueError:
      volume = -1
  return(volume)

def getSubstanceId(substance):
  for k,v in TYPES.items():
    if v == substance:
      return(k)
  return('none')

def collectSubstance(subs, vol, unit):
  substance = {}
  sub_id = getSubstanceId(subs)
  volume = normalizeVolume(vol, unit)
  if volume > 0:
    substance[sub_id] = normalizeVolume(vol, unit)
  return(substance)

def hasValidReleaseType(r):
  subs_indxs = [ ROWMAP['subs1'], ROWMAP['subs2'], ROWMAP['subs3'], ROWMAP['subs4'] ]
  for i in subs_indxs:
    val = " ".join(r[i].split())
    if val != '' and val in collect_types:
      return(True)
  return(False)

def getFeatureProperties(r):
  subs_indxs = [ ROWMAP['subs1'], ROWMAP['subs2'], ROWMAP['subs3'], ROWMAP['subs4'] ]
  substances = {
    "id": r[ROWMAP['id']],
    "pipeline_id": r[ROWMAP['pipeline_id']],
    "date": getTimestamp(r[ROWMAP['date']]),
    "source": r[ROWMAP['source']],
  }
  for i in subs_indxs:
    if r[i] != '':
      sub = collectSubstance(r[i], r[i+1], r[i+2])
      substances.update(sub)
  return(substances)

def getFeature(row):
  try:
    coords = [ float(row[ROWMAP['lon']]), float(row[ROWMAP['lat']]) ]
  except ValueError:
    print('error parsing coordinates on row: ',row)
    return(None)
  feature = {
    'type': "Feature",
    'geometry': { 
      'type': "Point",
      'coordinates': coords
    },
    'properties': getFeatureProperties(row)
  }
  return(feature)

geos=[]
i=0
for row in inputfile:
  if i > 0 and hasValidReleaseType(row) == True:
    point = getFeature(row)
    if point:
      geos.append(point)
  i+=1

geometries = {
  'type': 'FeatureCollection',
  'features': geos
}

json = json.dumps(geometries)
f = open("./build/geojson/releases.geojson","w")
f.write(json)
f.close()
