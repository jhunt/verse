FROM perl:5.30 AS build
RUN cpan Clone
WORKDIR /build
COPY . .
RUN mkdir /dist \
 && ./pack && cp verse-* /dist/verse \
 && curl -sLo /dist/spruce https://github.com/geofffranks/spruce/releases/download/v1.18.2/spruce-linux-amd64 \
 && curl -sLo /dist/jq     https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 \
 && chmod 0755 /dist/*

FROM ubuntu:18.04
MAINTAINER James Hunt <james@huntprod.com>

RUN apt-get update \
 && apt-get install -y make cpanminus build-essential \
 && cpanm Digest::SHA1 Clone TimeDate MIME::Base64 \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /dist/* /usr/bin/

EXPOSE  4000
VOLUME  /web
WORKDIR /web
ENV HOME=/tmp
ENTRYPOINT ["verse"]
