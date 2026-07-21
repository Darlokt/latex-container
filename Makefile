SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

IMAGE ?= latex-container:local
PLATFORM ?= linux/amd64
BUILD_DATE ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
VCS_REF ?= $(shell git rev-parse --verify HEAD 2>/dev/null || printf unknown)
VERSION ?= local
TEXLIVE_SNAPSHOT ?= $(shell date -u +%Y-%m-%d)

.PHONY: help build test check inspect clean

help: ## Show available targets.
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "%-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the local runtime image.
	docker buildx build \
		--build-arg BUILD_DATE="$(BUILD_DATE)" \
		--build-arg TEXLIVE_SNAPSHOT="$(TEXLIVE_SNAPSHOT)" \
		--build-arg VCS_REF="$(VCS_REF)" \
		--build-arg VERSION="$(VERSION)" \
		--load \
		--platform "$(PLATFORM)" \
		--tag "$(IMAGE)" \
		--target final \
		.

test: ## Build and execute the Docker smoke-test stage.
	docker buildx build \
		--build-arg BUILD_DATE="$(BUILD_DATE)" \
		--build-arg TEXLIVE_SNAPSHOT="$(TEXLIVE_SNAPSHOT)" \
		--build-arg VCS_REF="$(VCS_REF)" \
		--build-arg VERSION="$(VERSION)" \
		--platform "$(PLATFORM)" \
		--progress plain \
		--target test \
		.

check: ## Run fast repository checks without installing TeX Live.
	docker run --rm -v "$(CURDIR):/mnt:ro" -w /mnt \
		koalaman/shellcheck:v0.11.0@sha256:61862eba1fcf09a484ebcc6feea46f1782532571a34ed51fedf90dd25f925a8d \
		scripts/* tests/smoke/* .github/scripts/*.sh
	docker build --check .
	npm ci --ignore-scripts
	npx markdownlint --ignore node_modules '**/*.md'

inspect: ## Inspect the locally built runtime image and its manifest.
	docker image inspect "$(IMAGE)"
	docker run --rm "$(IMAGE)" check-latex-environment
	docker run --rm "$(IMAGE)" cat /usr/local/share/latex-container/build-info.json

clean: ## Remove local JavaScript dependencies and smoke output.
	rm -rf node_modules tests/fixtures/build
