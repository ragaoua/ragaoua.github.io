This is a jekyll project for hosting my blog on GitHub Pages.

# Working with Jekyll

## Initial set up

This is how the jekyll site scaffold was initially created.
Basically, just run an ephemeral jekyll container to setup the site scaffold.

On x86/amd64 :

~~~bash
podman run \
  --interactive \
  --tty \
  --rm \
  -v "./:/var/jekyll" \
  jekyll/jekyll \
  jekyll new . --skip-bundle

~~~

On arm64 :

~~~bash
podman run \
  --interactive \
  --tty \
  --rm \
  -v "./:/var/jekyll" \
  mrxder/jekyll-docker-arm64:latest \
  jekyll new . --skip-bundle
~~~


## Work on the site and preview locally

### Run a jekyll container, exposing port 4000

~~~bash
podman run \
  --interactive \
  --tty \
  --detach \
  --rm \
  --name jekyll \
  -v "./:/var/jekyll" \
  -p 4000:4000 \
  mrxder/jekyll-docker-arm64:latest \
  bash -c "bundle install && bundle exec jekyll serve --host=0.0.0.0"
~~~

This will install the dependencies and may take a few seconds. Use "podman logs" to watch the process unfold.

The `--rm` flag is here to make sure the container is destroyed when stopped so that it doesn't stay around for too long.

As long as the container is running, the site will be served by jekyll to be previewed locally.
Restarting the container will reload the site.


# Site publication

The site is published to GitHub Pages through the "gh-pages" branch.
A client-side hook is set up to update the "gh-pages" branch whenever a push is issued.
Cf [.githooks/pre-push](.githooks/pre-push).
See [Hooks](# Hooks).

# Hooks

The [.githooks](.githooks) directory contains the repository hooks. Configure the local repo to use them :

~~~bash
git config --local core.hooksPath .githooks/
~~~
