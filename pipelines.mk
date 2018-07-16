
# Shape files
shp_pipelines = https://s3.amazonaws.com/alberta-pipelines/shp/albeta-pipelines.tar.gz

# Data files
data_incidents = https://s3.amazonaws.com/alberta-pipelines/data/incidents.tar.gz
data_pipelines = https://s3.amazonaws.com/alberta-pipelines/data/pipelines.tar.gz

all: geojson/pipelines.geojson

clean:
	rm -rf ./tmp

geojson/pipelines.geojson: tmp/pipelines.tar.gz
	mkdir -p geojson
	tar xvf tmp/pipelines.tar.gz -C ./tmp
	mapshaper -i ./tmp/pipelines/*.shp \
		-proj wgs84 \
		-drop fields=LINE_NO,LIC_LI_NO,PL_SPEC_ID,FRM_LOC,TO_LOC,H2S_CNTNT,OUT_DIAMET,WALL_THICK,PIPE_TYPE,PIPE_GRADE,PIP_MATERL,PIPE_MAOP,STRESSLEVL,JOINTMETHD,INT_PROTEC,CROSS_TYPE,FLD_CTR_NM,ORIGPSPPID,ORIGLIN_NO,TEMPSURFPL,GEOM_SRCE,SHAPE_LEN \
		-o geojson/pipelines.geojson format=geojson

data/incidents.csv: tmp/incidents.tar.gz
	tar xvf tmp/incidents.tar.gz -C ./data
	cat data/OPENDATA_spills.csv | \
		csvcut -c LicenceNumber,IncidentNumber,Latitude,Longitude,IncidentDate,Source,LicenseeID,"Substance Released","Volume Released","Volume Units","Substance Released 2","Volume Released 2","Volume Units 2","Substance Released 3","Volume Released 3","Volume Units 3","Substance Released 4","Volume Released 4","Volume Units 4" | \
		header -r ORIG_LICNO,inc_no,lat,lng,date,source,lic_id,s1_type,s1_vol,s1_unit,s2_type,s2_vol,s2_unit,s3_type,s3_vol,s3_unit,s4_type,s4_vol,s4_unit | \
		csvsql --query "SELECT * FROM stdin WHERE source LIKE '%Pipeline%' AND ORIG_LICNO != '' AND s1_type != ''" \
		> incidents.csv

data/incidents_by_pipeline.csv: data/incidents.csv
	cat ./data/incidents.csv | \
		tail -n +2 | \
		awk -F ',' '{c[$1]++} END{ for (i in c) printf("%s,%s\n",i,c[i]) }' | \
		header -a ORIG_LICNO,incidents > ./data/incidents_by_pipeline.csv

# Create a file with releases by pipeline
data/releases_by_pipeline.csv: data/incidents.csv
	python ./scripts/create_releases_by_pipeline ./data/incidents.csv

# Collect all pipelines by type, with kilometers and count
data/pipeline_types.csv: tmp/pipelines-data.tar.gz
	python ./scripts/create_releases_by_pipeline ./data/pipelines.csv

.SECONDARY:
tmp/pipelines.tar.gz:
	mkdir -p tmp
	curl $(shp_pipelines) -o tmp/pipelines.tar.gz

tmp/incidents.tar.gz:
	mkdir -p tmp
	curl $(data_incidents) -o tmp/incidents.tar.gz

tmp/pipelines-data.tar.gz:
	mkdir -p tmp
	curl $(data_pipelines) -o tmp/pipelines-data.tar.gz