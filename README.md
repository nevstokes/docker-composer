# PHP Composer Docker Image
Composer Docker image for PHP dependency management

This is a custom build of PHP and is configured solely for the purpose of running [Composer](https://getcomposer.org). This allows the resulting images to be far smaller than the official version but does mean that some extensions and scripts will be unavailable. It is recommended that the Composer flags `--ignore-platform-reqs` and `--no-scripts` be employed; any commands that need to be run pre- or post-install should be done in a separate entrypoint script.

There are three tags available:

[![](https://images.microbadger.com/badges/version/nevstokes/composer.svg)](https://microbadger.com/images/nevstokes/composer "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/nevstokes/composer.svg)](https://microbadger.com/images/nevstokes/composer "Get your own image badge on microbadger.com")

[Busybox](https://www.busybox.net)-based basic Composer image with a [UPX](https://upx.github.io)-compressed PHP built from the latest [source image](https://hub.docker.com/r/nevstokes/php-7.1/).

[![](https://images.microbadger.com/badges/version/nevstokes/composer:prestissimo.svg)](https://microbadger.com/images/nevstokes/composer:prestissimo "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/nevstokes/composer:prestissimo.svg)](https://microbadger.com/images/nevstokes/composer:prestissimo "Get your own image badge on microbadger.com")

Image as above but with `curl` added to PHP for running the installed [Prestissimo](https://github.com/hirak/prestissimo) Composer extension for much improved performance.

[![](https://images.microbadger.com/badges/version/nevstokes/composer:pgo.svg)](https://microbadger.com/images/nevstokes/composer:pgo "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/nevstokes/composer:pgo.svg)](https://microbadger.com/images/nevstokes/composer:pgo "Get your own image badge on microbadger.com")

Same as the Prestissimo tag but with a [Profile Guided Optimised](https://software.intel.com/en-us/blogs/2015/10/09/pgo-let-it-go-php) build of PHP. This means that the build of this image will take substantially longer. This is really just an experiment; there isn't actually a noticeable improvement in terms of performance.
