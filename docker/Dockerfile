FROM ubuntu
MAINTAINER James Hunt <james@huntprod.com>
RUN apt-get update \
 && apt-get install -y curl make \
 && apt-get install -y libclone-perl \
 && rm -rf /var/lib/apt/lists/*
COPY verse /usr/bin/verse
