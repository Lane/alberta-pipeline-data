# Alberta Pipelines Data

This repository contains an ETL pipeline for fetching and transforming Alberta pipeline data and generating vector map tiles and CSV files based on the data.

## Getting Started

### Run using Docker

Clone the repository build the docker image, then run it to execute the pipeline.

```bash
$: docker build -t "alberta-pipelines" .
$: docker run -i -v ${PWD}:/App alberta-pipelines
```

### Data

To build the data, run `make data`.  Or, if using the Docker image, run:

```bash
$: docker run -i -v ${PWD}:/App alberta-pipelines data
```

#### `releases.csv`

Contains all pipeline "release" incidents from 1975 - 2013

  - `ORIG_LICNO` - Original license number for the pipeline
  - `inc_no` - incident number
  - `lat` - latitude of incident
  - `lng` - longitude of incident
  - `date` - date of incident
  - `source` - source of incident (e.g. pipeline)
  - `lic_id` - licensee ID
  - `s1_type` - Substance 1 type 
  - `s1_vol` - Substance 1 volume
  - `s1_unit` - Substance 1 unit (m^3 or 10^3m^3)


#### `pipelines_substances.csv`

Contains an overview of pipelines in Alberta, brokend down by substance type.

  - `substance` - type of substance carried by the pipeline
  - `km` - how many kilometers of that type of pipeline in Alberta
  - `count` - number of pipelines of that substance in Alberta

#### `releases_by_pipeline.csv`

Contains releases broken down by pipelines measured in m^3.

#### `releases_by_substance.csv`

Contains releases broken down by substance measured in m^3.

### GeoJSON

To build the data, run `make geojson`.  Or, if using the Docker image, run:

```bash
$: docker run -i -v ${PWD}:/App alberta-pipelines data
```

#### `pipelines.geojson`

GeoJSON file of Alberta pipelines

#### `releases.geojson`

GeoJSON file of Alberta pipelines incidents from 1975-2013

### Map Tiles

To build the vector tiles, run `make tiles`.  Or, if using the Docker image, run:

```bash
$: docker run -i -v ${PWD}:/App alberta-pipelines tiles
```

#### `incidents.mbtiles`

Tileset generated from releases.geojson

#### `pipelines.mbtiles`

Tileset generated from pipelines.geojson

### Deploy

TODO

## Data Unknowns

- What is the difference between licence number (`LICENCE_NO`) and original licence number (`ORIG_LICNO`)?
- Why do multiple features in the shapefiles have the same licence number, but different geometries, approval dates, and other dates?
- Should pipelines with the same licence number be counted as the same pipeline, or as different pipelines?
  - Looking at the data a bit closer, it seems like licences have multiple lines, and the unique identifier would be {{LICENCE_NO}}-{{LINE_NO}}, which is used in the field `LIC_LI_NO`.  Releases have no line number associated with them, so we can't highlight the specific line that leaked.
- Why are several dates missing for pipelines?