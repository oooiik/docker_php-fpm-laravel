FROM php:7.4-fpm

ARG USER=user
ARG UID=1000
ARG PORT=9000
ARG WORKDIR=/app

EXPOSE $PORT

RUN apt-get update

RUN apt-get install -y  \
    libzip-dev \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    curl \
    wget \
    openssl  \
    libssl-dev \
    libpq-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pgsql pdo_pgsql zip pdo_mysql mbstring exif pcntl bcmath gd

RUN pecl install xdebug-2.9.7 \
    && pecl install redis \
    && pecl install mongodb \
    && docker-php-ext-enable xdebug redis mongodb


COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN useradd -G www-data,root -u $UID -d /home/$USER $USER
RUN mkdir -p /home/$USER/.composer && \
    chown -R $USER:$USER /home/$USER

WORKDIR $WORKDIR

USER $USER

#CMD ["php-fpm"]
