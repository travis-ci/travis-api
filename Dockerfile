FROM ruby:2.7.1-slim

LABEL maintainer Travis CI GmbH <support+travis-admin-v2-docker-images@travis-ci.com>

# packages required for bundle install
RUN ( \
  apt-get update ; \
  apt-get install -y --no-install-recommends git make gcc g++ libpq-dev nodejs \
  && rm -rf /var/lib/apt/lists/* \
)

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /app
WORKDIR /app

COPY Gemfile      /app
COPY Gemfile.lock /app

RUN ( \
  bundle config set deployment 'true'; \
  bundle config set without 'development test'; \
  bundler install --verbose --retry=3; \
)

COPY . /app

RUN ( \
  bundle exec rake assets:precompile; \
)

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]