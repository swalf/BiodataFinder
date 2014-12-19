# BioDataFinder:0.1.14.pre
#
# VERSION               0.0.1

FROM      ruby:2.1.5
MAINTAINER Alessandro Bonfanti <a.bonfanti9@campus.unimib.it>

RUN apt-get update &&\
    apt-get upgrade -y 

RUN apt-get install -y elasticsearch 

RUN apt-get install -y git

RUN git clone https://github.com/swalf/biodatafinder.git /temp/bdf/ 

RUN gem install /temp/bdf/biodatafinder-0.1.14.pre.gem &&\
    bdf-cli setdef --host=http://localhost:9200 &&\
    bdf-cli setdef --indexes=idx19dec14 &&\
    bdf-cli setdef --def_index=idx19dec14
     

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 1234 9200

CMD ["/bin/bash"]



