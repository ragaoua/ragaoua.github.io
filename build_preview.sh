#!/bin/bash

set -e

readonly jekyll_image="mrxder/jekyll-docker-arm64:latest"
readonly container_name="jekyll-ragaoua-github-io"

if podman container exists "$container_name" 2>&1 >/dev/null ; then
  podman restart "$container_name" >/dev/null
else
  readonly bundler_volume="jekyll-ragaoua-github-io-bundler"
  podman volume create --ignore $bundler_volume >/dev/null

  podman run \
    --quiet \
    --tty \
    --detach \
    --rm \
    --name "$container_name" \
    -v "./jekyll:/var/jekyll" \
    -v "$bundler_volume:/usr/local/bundle" \
    -p 4000:4000 \
    "$jekyll_image" \
    bash -c "bundle install && bundle exec jekyll serve --host=0.0.0.0"
fi

echo "Container running, run the following command to see if it's ready :"
echo "podman logs -f $container_name"
echo
echo "Preview URL : http://127.0.0.1:4000"
