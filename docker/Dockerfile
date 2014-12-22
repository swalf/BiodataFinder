# BioDataFinder:0.1.16.pre
#
# VERSION               0.0.2

FROM ruby:2.1.5
MAINTAINER Alessandro Bonfanti <a.bonfanti9@campus.unimib.it>

RUN apt-get -y update &&\
    apt-get -y upgrade
    
RUN apt-get install -y git

RUN apt-get install -y default-jre

RUN echo '2014-12-22 23:30' && git clone https://github.com/swalf/biodatafinder.git /temp/bdf/ 

RUN mkdir /root/.biodatafinder/ 
COPY bdf.conf /root/.biodatafinder/bdf.conf

RUN cat /root/.biodatafinder/bdf.conf &&\
    gem install /temp/bdf/biodatafinder-0.1.17.pre.gem
    
COPY elasticsearch-1.4.2 /elasticsearch1.4
         

         
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 1234 9200 9300

CMD ["/bin/bash"]



