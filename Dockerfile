ARG PHP_VERSION=8.2-apache
FROM php:${PHP_VERSION} as php_laravel

RUN apt-get update && apt-get install -y \
  curl \
  git \
  libicu-dev \
  libpq-dev \
  libmcrypt-dev \
  openssl \
  unzip \
  vim \
  zip \
  zlib1g-dev \
  libpng-dev \
  libzip-dev && \
rm -r /var/lib/apt/lists/*

RUN pecl install mcrypt-1.0.6 && \
  docker-php-ext-install fileinfo exif pcntl bcmath gd && \
  docker-php-ext-enable mcrypt && \
  a2enmod rewrite

RUN docker-php-ext-install pdo pdo_pgsql

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

FROM php_laravel as executeable

ENV APP_SOURCE /var/www/web-mydata
ENV APP_DEBUG=false
ENV APP_URL=""
ENV APP_ENV=production

WORKDIR $APP_SOURCE

RUN sed -i "s|DocumentRoot /var/www/html|DocumentRoot ${APP_SOURCE}/public|g" /etc/apache2/sites-enabled/000-default.conf

COPY . .

RUN mkdir -p public/storage && \
chmod -R 777 storage/* && \
chmod -R 777 public/storage

RUN composer install --no-interaction --optimize-autoloader --no-dev && \
    php artisan package:discover --ansi && \
    php artisan key:generate --ansi --force && \
    php artisan optimize

VOLUME ${APP_SOURCE}/storage

EXPOSE 80/tcp
