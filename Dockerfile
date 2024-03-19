FROM ruby:3.2.2-slim

LABEL maintainer Travis CI GmbH <support+travis-api-docker-images@travis-ci.com>

RUN ( \
   mkdir -p /app/vendor /app/cache; \
   groupadd -r travis -g 1000 && \
   useradd -u 1000 -r -g travis -s /bin/sh -c "travis user" -d "/app" travis;\
   chown -R travis:travis /app; \
   apt-get update ; \
   apt-get install -y --no-install-recommends git make gcc g++ libpq-dev libjemalloc-dev libcurl4\
   && rm -rf /var/lib/apt/lists/* \
)

USER travis
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1
RUN bundle config set deployment 'true'
RUN bundle config set without 'development test'

RUN mkdir -p /app
WORKDIR /app

COPY Gemfile      /app
COPY Gemfile.lock /app

RUN gem install bundler -v '2.4.14'
RUN bundler install --verbose --retry=3
RUN gem install --user-install executable-hooks

COPY . /app

CMD ["./script/server-buildpacks"]
