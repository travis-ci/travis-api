# Defining platform type
ARG PLATFORM_TYPE=hosted

# Building the hosted base image
FROM ruby:2.5.5-slim as builder-hosted
RUN ( \
   apt-get update ; \
   apt-get install -y --no-install-recommends gettext-base git make g++ libpq-dev openssh-server \
   && rm -rf /var/lib/apt/lists/* \
)
COPY . /app

# Building the enterprise base image
FROM builder-hosted as builder-enterprise

ARG RUBYENCODER_PROJECT_ID
ARG RUBYENCODER_PROJECT_KEY
ARG SSH_KEY
RUN ( \
   if test $RUBYENCODER_PROJECT_ID; then \
     chmod +x /app/bin/te-encode && \
     ./app/bin/te-encode && \
     rm -rf /root/.ssh/id_rsa; \
   fi; \
)

FROM builder-${PLATFORM_TYPE}
LABEL maintainer Travis CI GmbH <support+travis-admin-v2-docker-images@travis-ci.com>

# packages required for bundle install
RUN ( \
  apt-get update ; \
  apt-get install -y --no-install-recommends gettext-base git make gcc g++ libpq-dev nodejs \
  && rm -rf /var/lib/apt/lists/* \
)

RUN gem i bundler --no-document -v=2.1.4
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
COPY /app /app

RUN ( \
  bundle exec rake assets:precompile; \
)

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]