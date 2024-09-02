#FROM debian:bookworm-slim AS builder

FROM ubuntu:22.04 AS build
 
#FROM php:8.2-cli-bookworm AS build
 
LABEL maintainer="Luc Docker"
 
ARG WWWGROUP

ARG NODE_VERSION=20

ARG POSTGRES_VERSION=15
 
WORKDIR /var/www/html
 
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
 
RUN apt-get update

RUN mkdir -p /etc/apt/keyrings

RUN apt-get install -y gnupg gosu curl ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev dnsutils librsvg2-bin fswatch ffmpeg nano

RUN curl -sS 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c' | gpg --dearmor | tee /etc/apt/keyrings/ppa_ondrej_php.gpg > /dev/null

RUN echo "deb [signed-by=/etc/apt/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/ppa_ondrej_php.list

RUN apt-get update

RUN apt-get install -y php8.2-cli php8.2-dev

RUN apt-get install -y php8.2-pgsql php8.2-sqlite3 php8.2-gd php8.2-imagick

RUN apt-get install -y php8.2-curl

RUN apt-get install -y php8.2-imap php8.2-mysql php8.2-mbstring

RUN apt-get install -y php8.2-xml php8.2-zip php8.2-bcmath php8.2-soap

RUN apt-get install -y php8.2-intl php8.2-readline

RUN apt-get install -y php8.2-ldap

RUN apt-get install -y php8.2-msgpack php8.2-igbinary php8.2-redis php8.2-swoole

RUN apt-get install -y php8.2-memcached php8.2-pcov php8.2-xdebug

RUN curl -sLS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

RUN apt-get update
 
ADD . /var/www/html
 
COPY php.ini /etc/php/8.2/cli/conf.d/php.ini
 
RUN composer install
 
 
FROM php:8.2-apache

COPY --from=build /var/www/html /var/www/html

COPY --from=build /var/www/html/.env.example /var/www/html/.env
 
 
WORKDIR /var/www/html
 
COPY php.ini /etc/php/8.2/cli/conf.d/php.ini

RUN chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/public

RUN chown -R www-data:www-data /var/www/html
 
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|g' /etc/apache2/sites-available/000-default.conf && \

    sed -i 's|<Directory /var/www/html/>|<Directory /var/www/html/public/>|g' /etc/apache2/sites-available/000-default.conf
 
RUN a2enmod rewrite
 
RUN php artisan migrate:fresh --seed

RUN php artisan key:generat
 
EXPOSE 80

 