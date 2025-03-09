This is a jekyll project for hosting my blog on GitHub Pages.

# Working with Jekyll

## Initial set up

This is how the jekyll site scaffold was initially created.
Basically, just run an ephemeral jekyll container to setup the site scaffold.

### Create the site

~~~bash
mkdir jekyll
podman run \
  --rm \
  -v "./jekyll:/var/jekyll" \
  mrxder/jekyll-docker-arm64:latest \
  jekyll new . --skip-bundle
~~~

Note : I'm using the `mrxder/jekyll-docker-arm64` image, which run on arm64 since I'm using MacOs. Feel free to switch to the official `jekyll/jekyll` image, which is only supported on x86/amd64. Same goes for the next chapter.

### Set up the theme

~~~bash
podman run \
  --rm \
  -v "./jekyll:/var/jekyll" \
  mrxder/jekyll-docker-arm64:latest \
  bash -c "gem install jekyll-theme-clean-blog -v 4.0.12 && \
    cp -r /usr/local/bundle/gems/jekyll-theme-clean-blog-4.0.12/{_layouts,_includes,_sass,assets} /var/jekyll"
~~~

Then customize the `_layout` and `_include` files as needed.


## Work on the site and preview locally

### Build and preview the site 

~~~bash
./build_preview.sh
~~~

This will spawn a container named "jekyll-ragaoua-github-io" that'll run a Jekyll server, and will take a few seconds the first time it's run as it needs to install gems dependencies.

The container bind its local "/var/jekyll" directory to the host's "./jekyll" directory to access the jekyll site.
The gem/Bundler dependencies are persisted inside the "./jekyll/vendor" directory, so that next time it is run,
it won't go through the initial gem installation again.

The `--rm` flag is here to make sure the container is destroyed when stopped so that it doesn't stay around for too long.
So, to destroy the container, simply run `podman stop jekyll-ragaoua-github-io`

As long as the container is running, the site will be served by jekyll to be previewed locally on port 4000.
Running the script again will restart the container to reload the site.


# Site publication

The site is published to GitHub Pages through the "gh-pages" branch.

~~~bash
./deploy.sh
~~~

