FROM perl:5.30 AS build
ARG VERSION
WORKDIR /build

RUN cpan Clone
RUN mkdir /dist \
 && curl -sLo /dist/spruce https://github.com/geofffranks/spruce/releases/download/v1.18.2/spruce-linux-amd64 \
 && curl -sLo /dist/jq     https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64

COPY . .
RUN ./pack $VERSION && cp verse-* /dist/verse \
 && chmod 0755 /dist/*

FROM ubuntu:18.04
MAINTAINER James Hunt <james@huntprod.com>

RUN apt-get update \
 && apt-get install -y make cpanminus build-essential git curl \
 && cpanm Digest::SHA1 Clone TimeDate MIME::Base64 \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /dist/* /usr/bin/

EXPOSE  4000
VOLUME  /web
WORKDIR /web
ENV HOME=/home

RUN verse inflate
ENTRYPOINT ["verse"]
