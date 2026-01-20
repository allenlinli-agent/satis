FROM composer:latest AS build

WORKDIR /satis

COPY . /satis/

RUN set -eux ; \
  composer install \
    --no-interaction \
    --no-ansi \
    --no-scripts \
    --no-plugins \
    --no-dev \
    --prefer-dist \
    --no-progress \
    --no-suggest \
    --classmap-authoritative

FROM php:8-cli-alpine

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN set -eux ; \
  apk upgrade --no-cache ; \
  apk add --no-cache --upgrade \
    bash \
    curl \
    dcron \
    git \
    mercurial \
    nginx \
    openssh \
    openssl \
    p7zip \
    subversion \
    unzip \
    zip ; \
  install-php-extensions \
    bz2 \
    sockets \
    zip

ENV COMPOSER_HOME=/composer

COPY php-cli.ini /usr/local/etc/php/
COPY nginx.conf /etc/nginx/nginx.conf
COPY startup.sh /usr/local/bin/startup.sh
COPY crontab /etc/crontabs/root
COPY --from=build /satis /satis/

RUN chmod +x /usr/local/bin/startup.sh

WORKDIR /build

COPY satis.json /build/satis.json

EXPOSE 3000

CMD ["/usr/local/bin/startup.sh"]
