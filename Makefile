SHELL := bash

VERSION_VALUE ?= $(shell git describe --always --dirty --tags 2>/dev/null)
VERSION_VALUE_LATEST ?= latest
DOCKER_IMAGE_REPO ?= travisci/travis-api
DOCKER_DEST ?= $(DOCKER_IMAGE_REPO):$(VERSION_VALUE)
QUAY ?= quay.io
QUAY_IMAGE ?= $(QUAY)/$(DOCKER_IMAGE_REPO)

ifdef $$QUAY_ROBOT_HANDLE
	QUAY_ROBOT_HANDLE := $$QUAY_ROBOT_HANDLE
endif
ifdef $$QUAY_ROBOT_TOKEN
	QUAY_ROBOT_TOKEN := $$QUAY_ROBOT_TOKEN
endif
ifndef $$TRAVIS_BRANCH
	TRAVIS_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)
endif

DOCKER ?= docker

.PHONY: docker-build
docker-build:
	$(DOCKER) build -t $(DOCKER_DEST) .

.PHONY: docker-push
docker-push:
	$(DOCKER) login -u=$(QUAY_ROBOT_HANDLE) -p=$(QUAY_ROBOT_TOKEN) $(QUAY)
	$(DOCKER) tag $(DOCKER_DEST) $(QUAY_IMAGE):$(VERSION_VALUE)
	$(DOCKER) push $(QUAY_IMAGE):$(VERSION_VALUE)
ifeq ($(TRAVIS_BRANCH), master)
    $(DOCKER) tag $(DOCKER_DEST) $(QUAY_IMAGE):$(VERSION_VALUE_LATEST)
    $(DOCKER) push $(QUAY_IMAGE):$(VERSION_VALUE_LATEST)
endif

.PHONY: ship
ship: docker-build docker-push

