FROM ubuntu:18.04
MAINTAINER James Hunt <james@huntprod.com>

RUN apt-get update \
 && apt-get install -y make cpanminus build-essential \
 && cpanm Digest::SHA1 Clone TimeDate MIME::Base64 \
 && rm -rf /var/lib/apt/lists/*

# test dependencies
RUN cpanm Test::Deep Test::Exception Test::Output

WORKDIR /app
ENTRYPOINT ["/bin/sh", "-c", "prove -l t/*.t"]
