
bucket_url = https://s3.amazonaws.com/alberta-pipelines/etl/

# Shape files
shp_pipelines = shp/albeta-pipelines.tar.gz

# Data files
data_incidents = data/incidents.tar.gz
data_pipelines = data/pipelines.tar.gz

download_files = shape-pipelines data-incidents data-pipelines
COMPRESSED_FILES = $(foreach t, $(download_files), tmp/$(t).tar.gz)

.PHONY: all clean tiles data

all: data tiles

data: build/data/releases_by_pipeline.csv build/data/pipeline_substances.csv

tiles: build/pipelines.mbtiles build/data/releases_by_pipeline.csv
	tile-join -o ./build/tileset \
		--no-tile-size-limit \
		-c ./build/data/releases_by_pipeline.csv \
		./build/pipelines.mbtiles

clean:
	rm -rf ./tmp
	rm -rf ./build

build/pipelines.mbtiles: build/geojson/pipelines.geojson
	tippecanoe -o ./build/pipelines.mbtiles -zg --drop-densest-as-needed ./build/geojson/pipelines.geojson

build/geojson/pipelines.geojson: tmp/shape-pipelines.tar.gz
	mkdir -p build/geojson
	tar xvf tmp/shape-pipelines.tar.gz -C ./tmp
	mapshaper -i ./tmp/pipelines/*.shp \
		-proj wgs84 \
		-drop fields=LINE_NO,LIC_LI_NO,PL_SPEC_ID,FRM_LOC,TO_LOC,H2S_CNTNT,OUT_DIAMET,WALL_THICK,PIPE_TYPE,PIPE_GRADE,PIP_MATERL,PIPE_MAOP,STRESSLEVL,JOINTMETHD,INT_PROTEC,CROSS_TYPE,FLD_CTR_NM,ORIGPSPPID,ORIGLIN_NO,TEMPSURFPL,GEOM_SRCE,SHAPE_LEN \
		-o ./build/geojson/pipelines.geojson format=geojson

build/data/incidents.csv: tmp/data-incidents.tar.gz
	mkdir -p build/data
	tar xOvf tmp/data-incidents.tar.gz | \
		csvcut -c LicenceNumber,IncidentNumber,Latitude,Longitude,IncidentDate,Source,LicenseeID,"Substance Released","Volume Released","Volume Units","Substance Released 2","Volume Released 2","Volume Units 2","Substance Released 3","Volume Released 3","Volume Units 3","Substance Released 4","Volume Released 4","Volume Units 4" | \
		sed '1s/.*/ORIG_LICNO,inc_no,lat,lng,date,source,lic_id,s1_type,s1_vol,s1_unit,s2_type,s2_vol,s2_unit,s3_type,s3_vol,s3_unit,s4_type,s4_vol,s4_unit/' | \
		csvsql --query "SELECT * FROM stdin WHERE source LIKE '%Pipeline%' AND ORIG_LICNO != '' AND s1_type != ''" \
		> ./build/data/incidents.csv

# Create a file with releases by pipeline
build/data/releases_by_pipeline.csv: build/data/incidents.csv
	mkdir -p build/data	
	python3 ./scripts/create_releases_by_pipeline.py ./build/data/incidents.csv

# Collect all pipelines by type, with kilometers and count
build/data/pipeline_substances.csv: tmp/data-pipelines.tar.gz
	mkdir -p build/data
	tar xOvf tmp/data-pipelines.tar.gz > ./tmp/data-pipelines.csv
	python3 ./scripts/create_km_of_pipeline_by_substance.py ./tmp/data-pipelines.csv

.SECONDARY:
tmp/%.tar.gz:
	mkdir -p tmp
	curl $(bucket_url)$*.tar.gz -o $@