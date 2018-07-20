#!/usr/bin/env python3
import csv
import json
import sys

if len(sys.argv) == 2:
  csvfile = sys.argv[1]
else:
  print('Incorrect number of arguments, must provide a csv file')
  sys.exit(1)  # abort because of error

release_types = open('data/release_types.json')
inputfile = csv.reader(open(csvfile,'r'))
outputfile = open('./build/data/releases_by_pipeline.csv','w')
outputfile2 = open('./build/data/releases_by_substance.csv','w')
releases = {}
totals = {}
keyIndex = {}
TYPES = json.loads(release_types.read())

# save the value in the releases dictionary
def storeValue(id, t, val):
  if id in releases:
    if t in releases[id]:
      releases[id][t] += val
    else:
      releases[id][t] = val
    releases[id]['count'] += 1
    releases[id]['total'] += val
  else:
    releases[id] = {}
    releases[id]['count'] = 1
    releases[id]['total'] = val
    releases[id][t] = val
  if t in totals:
    totals[t] += val
  else:
    totals[t] = val

# takes a type and row data to store in the releases dictionary
def collectType(t, r):
  index = -1
  if r[7] == TYPES[t]:
    index = 7
  elif r[10] == TYPES[t]:
    index = 10
  elif r[13] == TYPES[t]:
    index = 13
  elif r[16] == TYPES[t]:
    index = 16
  if index > 0:
    volume = normalizeVolume(r[index+1],r[index+2])
    if volume > -1:
      storeValue(r[0], t, round(volume,2))

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

# get the header row for the csv
def getHeaderRow():
  headerRow = [ 'ORIG_LICNO' ]
  i=1
  for k, v in TYPES.items():
    keyIndex[k] = i
    headerRow.append(k)
    i+=1
  headerRow.append('count')
  headerRow.append('total_release')
  return headerRow

# gets a row for the csv based on the data
def getRow(id, data):
  row = [None] * (len(TYPES)+3)
  row[0] = id
  total = 0
  for k, v in data.items():
    if k != 'count' and k != 'total':
      row[keyIndex[k]] = v
  row[len(row)-2] = data['count']
  row[len(row)-1] = data['total']
  return row

i=0
for row in inputfile:
  for k, v in TYPES.items():
    collectType(k, row)
  i+=1
wr = csv.writer(outputfile, quoting=csv.QUOTE_MINIMAL)
wr.writerow(getHeaderRow())
for k, v in releases.items():
  row = getRow(k, v)
  wr.writerow(row)
outputfile.close()

wr = csv.writer(outputfile2, quoting=csv.QUOTE_MINIMAL)
wr.writerow([ 'id', 'substance', 'amount_released' ])
for k, v in totals.items():
  wr.writerow([ k, TYPES[k], v])
outputfile2.close()

json = json.dumps(releases)
f = open("./build/data/releases.json","w")
f.write(json)
f.close()
