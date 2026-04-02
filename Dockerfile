FROM apache/apisix:3.15.0-debian

USER root
RUN apt-get update && \
    apt-get install -y luarocks && \
    luarocks install busted && \
    apt-get clean
