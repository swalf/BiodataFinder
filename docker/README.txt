wd:
/mnt/home/bonnalraoul/Projects/BiodataFinder/docker

build:
docker build -t helios/biodatafinder .

run:

docker run -P -v /tmp/es/db:/usr/share/elastisearch/db -v /tmp/es/tmp:/var/opt/elasticsearch/tmp -v /tmp/es/log:/var/opt/elasticsearch/log -i -t helios/biodatafinder
