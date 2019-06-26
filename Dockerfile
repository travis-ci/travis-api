FROM ruby:2.5.1

LABEL maintainer Travis CI GmbH <support+travis-app-docker-images@travis-ci.com>

# required for envsubst tool
RUN ( \
   apt-get update ; \
   apt-get install -y --no-install-recommends  gettext-base ; \
   groupadd -r travis && useradd -m -r -g travis travis ; \
   mkdir -p /usr/src/app ; \
   chown -R travis:travis /usr/src/app \
)

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

USER travis
WORKDIR /usr/src/app

COPY Gemfile      /usr/src/app
COPY Gemfile.lock /usr/src/app

RUN bundler install --verbose --retry=3

COPY . /usr/src/app

CMD /bin/bash