#!/bin/bash

podman run \
  --tty \
  --detach \
  --rm \
  --name jekyll \
  -v "./jekyll:/var/jekyll" \
  -p 4000:4000 \
  mrxder/jekyll-docker-arm64:latest \
  bash -c "bundle install && bundle exec jekyll serve --host=0.0.0.0"
