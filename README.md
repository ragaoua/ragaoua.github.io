This is a jekyll project for hosting my blog on GitHub Pages.

# Working with Jekyll

## Initial set up

This is how the jekyll site scaffold was initially created.
Basically, just run an ephemeral jekyll container to setup the site scaffold.

~~~bash
podman run \
  --rm \
  -v "./jekyll:/var/jekyll" \
  mrxder/jekyll-docker-arm64:latest \
  jekyll new . --skip-bundle
~~~

Note : I'm using the `mrxder/jekyll-docker-arm64` image, which run on arm64 since I'm using MacOs. Feel free to switch to the official `jekyll/jekyll` image, which is only supported on x86/amd64. Same goes for the next chapter.


## Work on the site and preview locally

### Run a jekyll container, exposing port 4000

~~~bash
./build_preview.sh
~~~

This may take a few seconds as it needs to install gem dependencies. Use "podman logs" to watch the process unfold.

The `--rm` flag is here to make sure the container is destroyed when stopped so that it doesn't stay around for too long.

As long as the container is running, the site will be served by jekyll to be previewed locally.
Restarting the container will reload the site.


# Site publication

The site is published to GitHub Pages through the "gh-pages" branch.

~~~bash
./deploy.sh
~~~

