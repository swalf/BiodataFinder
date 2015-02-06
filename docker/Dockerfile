# BioDataFinder:0.1.16.pre
#
# VERSION               0.0.2

FROM ruby:2.1.5
MAINTAINER Alessandro Bonfanti <a.bonfanti9@campus.unimib.it>

RUN apt-get -y update &&\
    apt-get -y upgrade
    
RUN apt-get install -y git

RUN apt-get install -y default-jre

RUN apt-get install -y supervisor

RUN apt-get install -y vim

RUN echo '2015-02-06 15:40' && git clone --branch master https://github.com/swalf/biodatafinder.git /temp/bdf/ 

RUN mkdir /root/.biodatafinder/ 
COPY bdf.conf /root/.biodatafinder/bdf.conf

RUN cd /temp/bdf/ &&\
    gem build biodatafinder.gemspec
    
RUN cd /temp/bdf/ &&\
	ls    
    
RUN gem install /temp/bdf/biodatafinder-0.3.4.pre.gem
    
ADD https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.2.tar.gz /opt/
   
RUN cd /opt &&\
    tar xzvf /opt/elasticsearch-1.4.2.tar.gz &&\
    mv /opt/elasticsearch-1.4.2 /opt/elasticsearch

COPY elasticsearch.yml /opt/elasticsearch/config/

RUN mkdir -p /usr/share/elasticsearch/db &&\
    mkdir -p /var/opt/elasticsearch/tmp /var/opt/elasticsearch/log
         
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 1234 9200 9300

CMD ["/usr/bin/supervisord"]



