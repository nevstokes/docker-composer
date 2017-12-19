ARG PHP_VERSION=latest
ARG FINAL_BASE_IMAGE=nevstokes/busybox

FROM nevstokes/php-src:${PHP_VERSION} AS src


FROM alpine:3.6 AS build

COPY --from=src /php.tar.xz .

# Requirements
RUN apk --update add \
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
# Enable optimization (-Os — Optimize for size)
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

COPY --from=build /usr/local/bin/php /usr/local/bin/
COPY --from=build /var/cache/apk /var/cache/

COPY getcomposer.sh .

RUN echo '@community http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
   && apk --update add \
        ca-certificates \
        git \
        libressl \
        upx@community \
    && ./getcomposer.sh \
    \
    && scanelf --nobanner --needed /usr/bin/git /usr/local/bin/php | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' | xargs apk add \
    \
    && upx -9 /usr/local/bin/php /usr/bin/git /usr/libexec/git-core/git-remote-http

# Remove what is no longer needed, which will clean up the shared library directories
RUN apk del --purge alpine-keys apk-tools libc-utils musl-utils scanelf upx

# With the exception of ld-musl, what is actually required is the shared library but named with just the major version
# number, as per its associated symlink. These can then be copied across to the next stage. Copying symlinks across
# effectively hardens them, duplicating the original shared object and inflating image size.
RUN rm /lib/libc.musl-x86_64.so.1 \
    && for lib_dir in $(find / -name lib*.so.* -type f -print | xargs -n 1 dirname | sort -u) \
    ; do \
        find $lib_dir -type l -name lib*.so -maxdepth 1 -print | xargs -rn 1 rm \
        && find $lib_dir -type f -name lib*.so.* -maxdepth 1 -print > libs.$$ \
        && find $lib_dir -type l -name lib*.so.* -maxdepth 1 -exec sh -c 'LINK=$(readlink -f $0) && ln -f $LINK $0' {} \; \
        && cat libs.$$ | xargs rm \
        && find $lib_dir -type l -maxdepth 1 -print | xargs -rn 1 rm; \
    done


FROM ${FINAL_BASE_IMAGE}

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL

COPY --from=libs /usr/local/bin/composer /usr/local/bin/php /usr/local/bin/

COPY --from=libs /usr/bin/git /usr/bin/
COPY --from=libs /usr/libexec/git-core/git-remote-https /usr/libexec/git-core/

COPY --from=libs /lib/ld-musl-x86_64.so.1 /lib/libz.so.1 /lib/
COPY --from=libs /usr/lib/*.so.* /usr/lib/

ENTRYPOINT ["/usr/local/bin/php", "/usr/local/bin/composer", "--ansi"]

WORKDIR /var/www

LABEL maintainer="Nev Stokes <mail@nevstokes.com>" \
    description="PHP Composer" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.schema-version="1.0" \
    org.label-schema.vcs-url=$VCS_URL \
    org.label-schema.vcs-ref=$VCS_REF
