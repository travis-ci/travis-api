FROM ruby:2.5.0

RUN apt-get update && \
    apt-get install sudo && \
    apt-get install -y postgresql-9.6

WORKDIR /travis

COPY . /travis

ENV BUNDLE_PATH /bundle-cache
