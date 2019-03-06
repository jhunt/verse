FROM ubuntu:18.04
MAINTAINER James Hunt <james@huntprod.com>

RUN apt-get update \
 && apt-get install -y \
      curl \
      make \
      git \
      libclone-perl \
 && rm -rf /var/lib/apt/lists/* \
 && curl -sLo /usr/bin/spruce https://github.com/geofffranks/spruce/releases/download/v1.18.2/spruce-linux-amd64 \
 && chmod 0755 /usr/bin/spruce \
 && curl -sLo /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 \
 && chmod 0755 /usr/bin/jq

COPY verse /usr/bin/verse
