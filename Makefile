
bucket_url = https://s3.amazonaws.com/alberta-pipelines/etl/

.PHONY: all clean tiles data geojson

all: data tiles

data: build/data/releases_by_pipeline.csv build/data/pipeline_substances.csv

tiles: build/pipelines.mbtiles

geojson: build/geojson/pipelines.geojson

clean:
	rm -rf ./tmp
	rm -rf ./build

build/pipelines.mbtiles: build/geojson/pipelines.geojson
	tippecanoe -o ./build/pipelines.mbtiles \
		--drop-smallest-as-needed \
		--simplification=5 ./build/geojson/pipelines.geojson

build/geojson/pipelines.geojson: tmp/shape-pipelines.tar.gz build/data/releases_by_pipeline.csv
	mkdir -p build/geojson
	tar xvf tmp/shape-pipelines.tar.gz -C ./tmp
	mapshaper -i ./tmp/pipelines/*.shp \
		-proj wgs84 \
		-drop fields=LINE_NO,LIC_LI_NO,PL_SPEC_ID,FRM_LOC,TO_LOC,PIPTECHSTD,PLLICSEGID,BA_CODE,SEG_LENGTH,COMP_NAME,IS_NEB,H2S_CONTNT,OUT_DIAMET,WALL_THICK,PIPE_TYPE,PIPE_GRADE,PIP_MATERL,PIPE_MAOP,STRESSLEVL,JOINTMETHD,INT_PROTEC,CROSS_TYPE,FLD_CTR_NM,ORIGPSPPID,ORIGLIN_NO,TEMPSURFPL,GEOM_SRCE,SHAPE_LEN \
		-rename-fields to=TO_FAC,from=FROM_FAC,status=SEG_STATUS,appr=PERMT_APPR,exp=PERMT_EXPI,issued=ORG_ISSUED,substance=SUBSTANCE,lic_app=LICAPPDATE \
		-o ./build/geojson/pipelines-tmp.geojson format=geojson precision=0.001
	python3 ./scripts/merge_release_data.py
	rm ./build/geojson/pipelines-tmp.geojson

build/data/releases.csv: tmp/data-incidents.tar.gz
	mkdir -p build/data
	tar xOvf tmp/data-incidents.tar.gz | \
		csvcut -c LicenceNumber,IncidentNumber,Latitude,Longitude,IncidentDate,Source,LicenseeID,"Substance Released","Volume Released","Volume Units","Substance Released 2","Volume Released 2","Volume Units 2","Substance Released 3","Volume Released 3","Volume Units 3","Substance Released 4","Volume Released 4","Volume Units 4" | \
		sed '1s/.*/ORIG_LICNO,inc_no,lat,lng,date,source,lic_id,s1_type,s1_vol,s1_unit,s2_type,s2_vol,s2_unit,s3_type,s3_vol,s3_unit,s4_type,s4_vol,s4_unit/' | \
		csvsql --query "SELECT * FROM stdin WHERE source LIKE '%Pipeline%' AND ORIG_LICNO != '' AND s1_type != ''" \
		> ./build/data/releases.csv

# Create a file with releases by pipeline
build/data/releases_by_pipeline.csv: build/data/releases.csv
	mkdir -p build/data	
	python3 ./scripts/create_releases_data.py ./build/data/releases.csv

# Collect all pipelines by type, with kilometers and count
build/data/pipeline_substances.csv: tmp/data-pipelines.tar.gz
	mkdir -p build/data
	tar xOvf tmp/data-pipelines.tar.gz > ./tmp/data-pipelines.csv
	python3 ./scripts/create_pipelines_data.py ./tmp/data-pipelines.csv

.SECONDARY:
tmp/%.tar.gz:
	mkdir -p tmp
	curl $(bucket_url)$*.tar.gz -o $@