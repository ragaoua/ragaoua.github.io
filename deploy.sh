#!/bin/bash

set -e

readonly publication_branch="gh-pages"
readonly jekyll_image="mrxder/jekyll-docker-arm64:latest"

podman run \
  --tty \
  --rm \
  -v "./:/var/jekyll" \
  "$jekyll_image" \
  bash -c "bundle install && bundle exec jekyll build"

git branch -D "$publication_branch"
git switch --orphan "$publication_branch"
git pull origin "$publication_branch"
shopt -s extglob
rm -rf !(_site) .jekyll-cache
mv _site/* .
rmdir _site
git add .
git commit
git push --set-upstream origin "$publication_branch"
git switch -
