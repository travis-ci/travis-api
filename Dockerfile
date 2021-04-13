FROM ruby:2.6.5-slim

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

RUN gem install bundler -v '2.1.4'
RUN bundle config set without 'development test'
RUN bundler install --verbose --retry=3
RUN gem install --user-install executable-hooks

COPY . /app
RUN bundle config unset frozen
RUN cd /usr/local/bundle/bundler/gems/s3-386361c1b0ed && bundle update
RUN cd /usr/local/bundle/bundler/gems/travis-lock-b418401c79e0 && sed "s/'activerecord'/'activerecord','~>4.2'/g" Gemfile -i && bundle update activerecord && bundle update redlock
RUN cd /usr/local/bundle/bundler/gems/travis-settings-debef595a6a5 && echo "gem 'activesupport','~> 5.2'" >> Gemfile && bundle update activemodel

RUN bundle config set frozen true
CMD ./script/server-buildpacks
