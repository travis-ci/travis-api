FROM ruby:2.7.5-slim

LABEL maintainer Travis CI GmbH <support+travis-api-docker-images@travis-ci.com>

# packages required for bundle install
RUN ( \
   apt-get update ; \
   # update to deb 10.8 
   apt-get upgrade -y ; \
   apt-get install -y --no-install-recommends git make gcc g++ libpq-dev libjemalloc-dev \
   && rm -rf /var/lib/apt/lists/* \
)

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1
RUN bundle config set deployment 'true'

RUN mkdir -p /app
WORKDIR /app

COPY Gemfile      /app
COPY Gemfile.lock /app

RUN gem install bundler -v '2.3.6'
RUN bundle config set without 'development test'
RUN bundler install --verbose --retry=3
RUN gem install --user-install executable-hooks

COPY . /app

RUN bundle config set frozen true
CMD ./script/server-buildpacks
