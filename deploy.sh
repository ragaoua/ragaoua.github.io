#!/bin/bash

set -e

readonly publication_branch="gh-pages"
readonly jekyll_image="mrxder/jekyll-docker-arm64:latest"

podman run \
  --tty \
  --rm \
  -v "./jekyll:/var/jekyll" \
  "$jekyll_image" \
  bash -c "bundle install && bundle exec jekyll build"

git branch -D "$publication_branch"
git switch --orphan "$publication_branch"
git pull origin "$publication_branch"
shopt -s extglob
rm -rf !(jekyll)
mv jekyll/_site/* .
rm -rf jekyll
git add .
git commit
git push --set-upstream origin "$publication_branch"
git switch -
