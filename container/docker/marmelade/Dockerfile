FROM nginx:perl

RUN apt-get update && \
    apt-get -y cpanminus libmoose-perl libmojolicious-perl \
        libjson-xs-perl libproc-fork-perl libdatetime-perl \
        libuuid-tiny-perl libredis-perl libyaml-perl && \
    apt-get clean

RUN mkdir /butter
COPY . /butter


