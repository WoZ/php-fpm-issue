FROM php:7.4.29-fpm-alpine3.15

RUN set -eux; \
    apk update ; \
    apk add strace

RUN set -eux; \
    rm /usr/local/etc/php-fpm.conf \
       /usr/local/etc/php-fpm.conf.default \
       /usr/local/etc/php/php.ini-development \
       /usr/local/etc/php/php.ini-production \
    ; \
    rm -rf /usr/local/etc/php-fpm.d

