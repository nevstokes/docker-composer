FROM nevstokes/php-7.1:src AS src


FROM alpine:3.6 AS build

ENV PHP_INI_DIR=/usr/local/etc/php

COPY --from=src /php.tar.xz .

RUN set -euxo pipefail

# Requirements
RUN apk update && apk add --no-cache \
        autoconf \
        curl-dev \
        file \
        g++ \
        gcc \
        libc-dev \
        libressl-dev \
        make \
        pkgconf \
        re2c \
        xz \
        zlib-dev

RUN mkdir -p $PHP_INI_DIR/conf.d \
    && mkdir -p /usr/src/php \
    && tar -Jxf php.tar.xz -C /usr/src/php --strip-components=1

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent
# Enable optimization (-Os — Optimize for size)
# Enable linker optimization
# Adds GNU HASH segments to generated executables
# https://github.com/docker-library/php/issues/272
RUN export CFLAGS="-fstack-protector-strong -fpic -fpie -Os" \
        CPPFLAGS="-fstack-protector-strong -fpic -fpie -Os" \
        LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie" \
    && cd /usr/src/php \
    && ./configure \
          --with-config-file-path="$PHP_INI_DIR" \
          --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
          --disable-all \
          --disable-cgi \
          --enable-filter \
          --enable-hash \
          --enable-json \
          --enable-mbstring \
          --enable-phar \
          --enable-zip \
          --with-openssl \
          --with-zlib \
    && make -j "$(getconf _NPROCESSORS_ONLN)" \
    && make install \
    && { find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; } \
    && make clean


# Clean slate
FROM alpine:3.6

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL

ENV PHP_INI_DIR=/usr/local/etc/php

COPY --from=build /usr/local/bin/php /usr/local/bin/php
COPY --from=build $PHP_INI_DIR/conf.d $PHP_INI_DIR/conf.d

COPY getcomposer.sh .

RUN set -euxo pipefail \
    && apk --update add --no-cache \
        ca-certificates \
        git \
        libressl \
    && ./getcomposer.sh \
    && rm -rf \
        getcomposer.sh \
        /var/cache \
    && find /usr/libexec/git-core/* | grep -v git-remote-https | xargs rm -rf \
    && find /bin -type l | grep -v /sh | xargs rm -f

WORKDIR /var/www

ENTRYPOINT ["composer"]
CMD ["--ansi"]

LABEL maintainer "Nev Stokes <mail@nevstokes.com>" \
    description="PHP Composer" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.schema-version="1.0" \
    org.label-schema.vcs-url=$VCS_URL \
    org.label-schema.vcs-ref=$VCS_REF
