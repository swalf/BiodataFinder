wd:
/mnt/home/bonnalraoul/Projects/BiodataFinder/docker

build:
docker build -t helios/biodatafinder .

run:

docker run -P -v /tmp/es/db:/usr/share/elasticsearch/db -v /tmp/es/tmp:/var/opt/elasticsearch/tmp -v /tmp/es/log:/var/opt/elasticsearch/log -i -t swalf/biodatafinder


