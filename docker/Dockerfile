FROM ubuntu
RUN apt-get update \
 && apt-get install -y libdigest-md5-perl \
                       libyaml-perl \
                       libhash-merge-perl \
                       libtime-parsedate-perl \
 && rm -rf /var/lib/apt/lists/*
COPY lib/      /usr/share/perl5
COPY bin/verse /usr/bin/verse
