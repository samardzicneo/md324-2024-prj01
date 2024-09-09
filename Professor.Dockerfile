FROM debian:bookworm-slim AS build

ENV PHPVER=8.2
ENV PHPEXT="cli ctype curl dom fileinfo mbstring pdo tokenizer xml zip intl"

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt update
RUN apt install -y curl ca-certificates apt-transport-https
RUN mkdir -p /etc/apt/trusted.gpg.d
RUN curl https://packages.sury.org/php/apt.gpg > /etc/apt/trusted.gpg.d/php.gpg
RUN echo "deb https://packages.sury.org/php/ bookworm main" > /etc/apt/sources.list.d/php.list
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash
RUN apt update
RUN apt install -y nodejs
RUN apt install -y `for i in ${PHPEXT}; do echo php${PHPVER}-$i; done`
RUN curl https://getcomposer.org/installer | php -- --install-dir=/bin --filename composer

WORKDIR /app
ADD . .

RUN composer install

FROM php:8.2-apache-bookworm AS run

ENV PHPVER=8.2
ENV PHPEXT="ctype curl dom fileinfo mbstring pdo tokenizer xml zip intl"


COPY --from=build /var/www/html /var/www/html
COPY --from=build /var/www/html/.env.example /var/www/html/.env


WORKDIR /var/www/html

#COPY php.ini /etc/php/8.2/cli/conf.d/php.ini
RUN chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/public
RUN chown -R www-data:www-data /var/www/html

RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|g' /etc/apache2/sites-available/000-default.conf && \
    sed -i 's|<Directory /var/www/html/>|<Directory /var/www/html/public/>|g' /etc/apache2/sites-available/000-default.conf

RUN a2enmod rewrite

VOLUME [ "/app/.env" ]
VOLUME [ "/app/storage" ]

EXPOSE 80
CMD php artisan migrate:refresh
CMD php artisan key:generate
