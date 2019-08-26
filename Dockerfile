FROM ruby:2.5.1

LABEL maintainer Travis CI GmbH <support+travis-app-docker-images@travis-ci.com>

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /app
WORKDIR /app

COPY Gemfile      /app
COPY Gemfile.lock /app

RUN bundler install --verbose --retry=3

COPY . /app

CMD ./script/server-buildpacks