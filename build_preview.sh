#!/bin/bash

readonly jekyll_image="mrxder/jekyll-docker-arm64:latest"
readonly container_name="jekyll-ragaoua-github-io"

if podman container exists "$container_name" 2>&1 >/dev/null ; then
  podman restart "$container_name"
else
  podman run \
    --tty \
    --detach \
    --rm \
    --name "$container_name" \
    -v "./jekyll:/var/jekyll" \
    -p 4000:4000 \
    "$jekyll_image" \
    bash -c "bundle install && bundle exec jekyll serve --host=0.0.0.0"
fi

echo "http://127.0.0.1:4000"
