FROM debian:13 AS base
ENV LANG=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
COPY scripts /scripts
RUN bash /scripts/setup.sh && \
    date > /ovasbase-date
ENTRYPOINT ["/bin/bash"] 


FROM base AS builder
RUN mkdir /build.d
RUN bash /scripts/build-prereqs.sh && \
    date > /ovasbase-builder-date
ENTRYPOINT ["/bin/bash"] 
