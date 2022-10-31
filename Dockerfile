FROM ruby:2.7.5-slim

LABEL maintainer Travis CI GmbH <support+travis-api-docker-images@travis-ci.com>

RUN ( \
   bundle config set no-cache 'true'; \
   bundle config --global frozen 1; \
   bundle config set deployment 'true'; \
   mkdir -p /app; \
)

WORKDIR /app

COPY Gemfile*      /app/

RUN ( \
   apt-get update ; \
   apt-get upgrade -y ; \
   apt-get install -y --no-install-recommends git make gcc g++ libpq-dev libjemalloc-dev xz-utils \
   && rm -rf /var/lib/apt/lists/*; \
   gem update --system; \
   bundle config set without 'development test'; \
   bundler install --verbose --retry=3; \
   bundle config set frozen true; \
   apt-get remove -y gcc g++ make git perl xz-utils && apt-get -y autoremove; \
   bundle clean && rm -rf /app/vendor/bundle/ruby/2.7.0/cache/*; \
   for i in `find /app/vendor/ -name \*.o -o -name \*.c -o -name \*.h`; do rm -f $i; done; \
)

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

COPY . /app

CMD ["./script/server-buildpacks"]
