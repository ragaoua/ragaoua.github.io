# Initial set up

Below is how the blog is initially created.

## Run the jekyll container

~~~bash
podman run -itd --rm -v "./:/var/jekyll" --name jekyll mrxder/jekyll-docker-arm64:latest
~~~

## Create the site scaffold

~~~bash
podman exec -it jekyll jekyll new . --skip-bundle
~~~

## Delete the container

~~~bash
podman stop jekyll
~~~

# Work on the site and preview locally

## Run the jekyll container, exposing port 4000

~~~bash
podman run -itd -v "./:/var/jekyll" -p 4000:4000 --name jekyll mrxder/jekyll-docker-arm64:latest bash -c "bundle install && bundle exec jekyll serve --host=0.0.0.0"
~~~

Note : this will install the dependencies and may take a few seconds. Use "podman logs" to watch the process.

As long as the container is running, the site will be served by jekyll to be previewed locally.
Restarting the container will naturally reload the site.
