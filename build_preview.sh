#!/bin/bash

set -e

detach_option="--detach"
while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--debug)
      detach_option=""
      shift
      ;;
    *)
      echo "Unknown option $1" >&2
      exit 2
      ;;
  esac
done
readonly detach_option

readonly jekyll_image="mrxder/jekyll-docker-arm64:latest"
readonly container_name="jekyll-ragaoua-github-io"

if podman container exists "$container_name" 2>&1 >/dev/null ; then
  podman stop "$container_name" >/dev/null
fi

podman run \
  --quiet \
  --tty \
  $detach_option \
  --rm \
  --name "$container_name" \
  -v "$(dirname "$(realpath "$0")")/jekyll:/var/jekyll" \
  -p 4000:4000 \
  "$jekyll_image" \
  bash -c "bundle config set --local path vendor/bundle && \
    bundle install && \
    bundle exec jekyll serve --host=0.0.0.0 --livereload --force_polling"


echo "Container running, run the following command to see if it's ready :"
echo "podman logs -f $container_name"
echo
echo "Preview URL : http://127.0.0.1:4000"
