# Alberta Pipelines Data

This repository contains an ETL pipeline for fetching and transforming Alberta pipeline data and generating vector map tiles and CSV files based on the data.

## Getting Started

### Run using Docker

Clone the repository, build the docker image, then run it to execute the pipeline.

```bash
$: docker build -t "alberta-pipelines" .
$: docker run -i -v ${PWD}:/App alberta-pipelines
```

## Output

### Data

#### `incidents.csv`

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

#### `releases_by_pipeline.csv`

### Map Tiles