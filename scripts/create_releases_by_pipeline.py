#!/usr/bin/env python2
import csv
import json
import sys

if len(sys.argv) == 2:
  csvfile = sys.argv[1]
else:
  print 'Incorrect number of arguments, must provide a csv file'
  sys.exit(1)  # abort because of error

release_types = open('data/release_types.json')
inputfile = csv.reader(open(csvfile,'r'))
outputfile = open('releases_by_pipeline.csv','w')
releases = {}
keyIndex = {}
TYPES = json.loads(release_types.read())

# save the value in the releases dictionary
def storeValue(id, t, val):
  if id in releases:
    if t in releases[id]:
      releases[id][t] += val
    else:
      releases[id][t] = val
    releases['count'] += 1
  else:
    releases[id] = {}
    releases[id]['count'] = 1
    releases[id][t] = val

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
      storeValue(r[0], t, volume)

# converts the value to m^3
def normalizeVolume(val, unit):
  try:
    if unit == '103m3':
      volume = float(val) * 1000
    elif unit == 'm3':
      volume = float(val) * 1
    else:
      volume = float(val) * 1
  except ValueError,e:
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
  headerRow.append('total_release')
  return headerRow

# gets a row for the csv based on the data
def getRow(id, data):
  row = [None] * (len(TYPES)+2)
  row[0] = id
  total = 0
  for k, v in data.items():
    total += v
    row[keyIndex[k]] = v
  row[len(row)-1] = total
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