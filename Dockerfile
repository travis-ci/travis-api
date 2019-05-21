FROM ruby:2.5.1

LABEL maintainer Travis CI GmbH <support+travis-app-docker-images@travis-ci.com>

# required for envsubst tool
RUN ( \
   apt-get update ; \
   apt-get install -y --no-install-recommends  gettext-base \
)

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY Gemfile      /usr/src/app
COPY Gemfile.lock /usr/src/app

RUN bundler install --verbose --retry=3

COPY . /usr/src/app

CMD ./script/server