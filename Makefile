
bucket_url = https://s3.amazonaws.com/alberta-pipelines/etl/

.PHONY: all clean tiles data geojson deploy

all: data tiles

data: build/data/releases_by_pipeline.csv build/data/pipeline_substances.csv

tiles: build/pipelines.mbtiles build/incidents.mbtiles

geojson: build/geojson/pipelines.geojson build/geojson/releases.geojson

deploy: tiles

clean:
	rm -rf ./tmp
	rm -rf ./build
	
# Creates the pipelines vector tiles from GeoJSON
build/pipelines.mbtiles: build/geojson/pipelines.geojson
	tippecanoe -o ./build/pipelines.mbtiles \
		--name=oil-pipelines \
		--description='A tileset containing Alberta pipelines' \
		--named-layer=pipelines:./build/geojson/pipelines.geojson \
		--drop-smallest-as-needed

# Creates the incidents vector tiles from GeoJSON
build/incidents.mbtiles: build/geojson/releases.geojson
	tippecanoe -o ./build/incidents.mbtiles \
		--name=oil-incidents \
		--description='A tileset containing Alberta release incidents' \
		--named-layer=incidents:./build/geojson/releases.geojson \
		--drop-rate=1 --no-feature-limit

# Converts pipeline shapefiles into geojson
#   - Removes unneeded fields
#   - Filters out non-oil pipelines
#   - Sets a date when the pipeline license was approved (or permit was approved if not available)
#   - Renames fields
build/geojson/pipelines.geojson: tmp/shape-pipelines.tar.gz build/data/releases_by_pipeline.csv
	mkdir -p build/geojson
	tar xvf tmp/shape-pipelines.tar.gz -C ./tmp
	mapshaper -i ./tmp/pipelines/*.shp \
		-proj wgs84 \
		-drop fields=LINE_NO,LIC_LI_NO,PL_SPEC_ID,FRM_LOC,TO_LOC,PIPTECHSTD,PLLICSEGID,BA_CODE,SEG_LENGTH,COMP_NAME,IS_NEB,H2S_CONTNT,OUT_DIAMET,WALL_THICK,PIPE_TYPE,PIPE_GRADE,PIP_MATERL,PIPE_MAOP,STRESSLEVL,JOINTMETHD,INT_PROTEC,CROSS_TYPE,FLD_CTR_NM,ORIGPSPPID,ORIGLIN_NO,TEMPSURFPL,GEOM_SRCE,SHAPE_LEN \
		-filter '"crude oil,lvp products,salt water,fresh water,oil-well effluent".indexOf(SUBSTANCE.toLowerCase()) > -1' \
		-each 'app_date=(Date.parse(LICAPPDATE)>0?Date.parse(LICAPPDATE):Date.parse(PERMT_APPR))' \
		-rename-fields to=TO_FAC,from=FROM_FAC,status=SEG_STATUS,substance=SUBSTANCE \
		-o ./build/geojson/pipelines-tmp.geojson format=geojson precision=0.001
	python3 ./scripts/join_geojson_data.py -i ./build/geojson/pipelines-tmp.geojson -j ./build/data/releases.json -k 'ORIG_LICNO' -o ./build/geojson/pipelines.geojson
	rm ./build/geojson/pipelines-tmp.geojson

# Processes the Oil Spills data from: https://globalnews.ca/news/622513/open-data-alberta-oil-spills-1975-2013/
# 	- Filters to include only non-gas pipeline incidents 
#			where a pipeline license number exists
#			and a substance was released
build/data/releases.csv: tmp/data-incidents.tar.gz
	mkdir -p build/data
	tar xOvf tmp/data-incidents.tar.gz | \
		csvcut -c LicenceNumber,IncidentNumber,Latitude,Longitude,IncidentDate,Source,LicenseeID,"Substance Released","Volume Released","Volume Units","Substance Released 2","Volume Released 2","Volume Units 2","Substance Released 3","Volume Released 3","Volume Units 3","Substance Released 4","Volume Released 4","Volume Units 4" | \
		sed '1s/.*/ORIG_LICNO,inc_no,lat,lng,date,source,lic_id,s1_type,s1_vol,s1_unit,s2_type,s2_vol,s2_unit,s3_type,s3_vol,s3_unit,s4_type,s4_vol,s4_unit/' | \
		csvsql --query "SELECT * FROM stdin WHERE source LIKE '%Pipeline%' AND source NOT LIKE '%Gas%' AND ORIG_LICNO != '' AND s1_type != ''" \
		> ./build/data/releases.csv

# Create releases geojson
build/geojson/releases.geojson: build/data/releases.csv
	mkdir -p build/geojson
	python3 ./scripts/create_releases_geojson.py -i ./build/data/releases.csv

# Create a file with releases by pipeline
build/data/releases_by_pipeline.csv: build/data/releases.csv
	mkdir -p build/data	
	python3 ./scripts/create_releases_data.py ./build/data/releases.csv

# Collect all pipelines by type, with kilometers and count
build/data/pipeline_substances.csv: tmp/data-pipelines.tar.gz
	mkdir -p build/data
	tar xOvf tmp/data-pipelines.tar.gz | \
		csvsql --query "SELECT Substance,SUM(Segment_Length),COUNT(Licence_Number) FROM stdin GROUP BY Substance" | \
		sed '1s/.*/substance,km,count/' > ./build/data/pipeline_substances.csv

# Create longest oil pipelines
build/data/pipeline_by_length.csv: tmp/data-pipelines.tar.gz
	mkdir -p build/data
	tar xOvf tmp/data-pipelines.tar.gz | \
		csvcut -c Licence_Number,Segment_Length,Company_Name,Substance | \
		csvsql --query "SELECT * FROM stdin WHERE Substance LIKE '%Crude Oil%'" | \
		csvsort -r -c 2 > ./build/data/oil_pipelines_by_length.csv

.SECONDARY:
tmp/%.tar.gz:
	mkdir -p tmp
	curl $(bucket_url)$*.tar.gz -o $@