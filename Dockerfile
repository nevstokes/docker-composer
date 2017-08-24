FROM nevstokes/php-7.1:src AS src


FROM alpine:3.6 AS build

COPY --from=src /php.tar.xz .

RUN set -euxo pipefail

# Requirements
RUN apk --update add --no-cache \
        autoconf \
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

RUN mkdir -p /usr/src/php \
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
          --disable-all \
          --disable-cgi \
          --disable-phpdbg \
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
    && make clean \
    && { find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; }


# Clean slate
FROM alpine:3.6 AS libs

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL

COPY --from=build /usr/local/bin/php /usr/local/bin/php

COPY getcomposer.sh .

RUN set -euxo pipefail \
    && echo '@community http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
   && apk --update add \
        ca-certificates \
        git \
        libressl \
        upx@community \
    && ./getcomposer.sh \
    \
    && scanelf --nobanner --needed /usr/bin/git | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' | xargs apk add \
    && scanelf --nobanner --needed /usr/local/bin/php | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' | xargs apk add \
    \
    && upx -9 /usr/bin/git /usr/local/bin/php \
    && apk del --purge apk-tools upx \
    \
    && tar -czf lib.tar.gz /lib/*.so.* \
    && tar -czf usr-lib.tar.gz /usr/lib/libpcre.so.*


FROM busybox

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL

COPY --from=libs /usr/local/bin/composer /usr/local/bin/php /usr/local/bin/

COPY --from=libs /usr/bin/git /usr/bin/
COPY --from=libs /usr/libexec/git-core/git-remote-https /usr/libexec/git-core/
COPY --from=libs *.tar.gz /

ENTRYPOINT ["/usr/local/bin/php", "/usr/local/bin/composer", "--ansi"]

RUN tar -xzf /lib.tar.gz \
    && tar -xzf /usr-lib.tar.gz \
    && rm -rf /bin *.tar.gz

WORKDIR /var/www

LABEL maintainer="Nev Stokes <mail@nevstokes.com>" \
    description="PHP Composer" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.schema-version="1.0" \
    org.label-schema.vcs-url=$VCS_URL \
    org.label-schema.vcs-ref=$VCS_REF
