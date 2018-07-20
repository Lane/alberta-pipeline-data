#!/usr/bin/env python3
import csv
import json
import sys

if len(sys.argv) == 2:
  csvfile = sys.argv[1]
else:
  print('Incorrect number of arguments, must provide a csv file')
  sys.exit(1)  # abort because of error

substance_types = open('data/pipeline_substances.json')
inputfile = csv.reader(open(csvfile,'r'))
outputfile = open('./build/data/pipeline_substances.csv','w')
substances = {}
types = json.loads(substance_types.read())
substanceCol = 27
kmCol = 8

def updateSubstance(t, row):
  try:
    index = types.index(t)
    if index in substances:
      substances[index]['km']+=float(row[kmCol])
      substances[index]['count']+=1
    else:
      substances[index] = { 'km': float(row[kmCol]), 'count': 1 }
  except ValueError:
    index = -1

# get the header row for the csv
def getHeaderRow():
  headerRow = [ 'substance', 'km', 'count' ]
  return headerRow

# gets a row for the csv based on the data
def getRow(t):
  try:
    index = types.index(t)
    row = [None] * 3
    row[0] = t
    row[1] = round(substances[index]['km'])
    row[2] = substances[index]['count']
  except ValueError:
    row = []
  return row

i=1
for row in inputfile:
  updateSubstance(row[substanceCol], row)
  i+=1
wr = csv.writer(outputfile, quoting=csv.QUOTE_MINIMAL)
wr.writerow(getHeaderRow())
for t in types:
  row = getRow(t)
  if len(row) == 3:
    wr.writerow(row)
outputfile.close()
