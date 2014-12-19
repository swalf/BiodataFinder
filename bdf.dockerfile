# BioDataFinder:0.1.14.pre
#
# VERSION               0.0.1

FROM      ruby:2.1.5
MAINTAINER Alessandro Bonfanti <a.bonfanti9@campus.unimib.it>

RUN 
    apt-get update &&\
    apt-get -y ugrade 

RUN apt-get -y install elasticsearch 

RUN apt-get -y install git

RUN git clone https://github.com/swalf/biodatafinder.git /temp/bdf/

RUN gem install /temp/bdf/biodatafinder-0.1.14.pre.gem

RUN apt-get -y install supervisor

RUN mkdir -p /var/log/supervisor

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 3000

CMD ["/usr/bin/supervisord"]



