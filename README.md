# PHP Composer Docker Image
Composer Docker image for PHP dependency management

This is an Alpine-based image with a custom build of PHP and configured solely for the purpose of running [Composer](https://getcomposer.org). This allows the resulting images to be far smaller than the official version but does mean that some extensions and scripts will be unavailable. It is recommended that the Composer flags `--ignore-platform-reqs` and `--no-scripts` be employed; any commands that need to be run pre- or post-install should be done in a separate entrypoint script.

There are three tags available:

**latest** — 20.8MB

Basic Composer image with PHP built from the latest [source image](https://hub.docker.com/r/nevstokes/php-7.1/).

**prestissimo** — 37.6MB

Image as above but with `curl` added to PHP for running the installed [Prestissimo](https://github.com/hirak/prestissimo) Composer extension for much improved performance.

**pgo**  — 37.6MB

Same as the Prestissimo tag but with a [Profile Guided Optimised](https://software.intel.com/en-us/blogs/2015/10/09/pgo-let-it-go-php) build of PHP. This means that the build of this image will take substantially longer. This is really just an experiment; there isn't actually a noticeable improvement in terms of performance.
