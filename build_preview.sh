#!/bin/bash

set -e

readonly jekyll_image="mrxder/jekyll-docker-arm64:latest"
readonly container_name="jekyll-ragaoua-github-io"

if podman container exists "$container_name" 2>&1 >/dev/null ; then
  podman restart "$container_name" >/dev/null
else
  podman run \
    --quiet \
    --tty \
    --detach \
    --rm \
    --name "$container_name" \
    -v "./jekyll:/var/jekyll" \
    -p 4000:4000 \
    "$jekyll_image" \
    bash -c "bundle install && bundle exec jekyll serve --host=0.0.0.0"
fi

echo "Build in progress, run the following command to see progress :"
echo "podman logs -f $container_name"
echo
echo "Preview URL : http://127.0.0.1:4000"
