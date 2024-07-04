FROM php:8.3-fpm

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
    git \
    cmake \
    autoconf \
    libtool \
    pkg-config \
    build-essential \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pgsql pdo_pgsql zip pdo_mysql mbstring exif pcntl bcmath gd calendar

RUN pecl install xdebug redis mongodb mailparse \
    && docker-php-ext-enable xdebug redis mongodb mailparse

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install protobuf compiler (protoc)
RUN wget https://github.com/protocolbuffers/protobuf/releases/download/v27.2/protoc-27.2-linux-x86_64.zip \
    && unzip protoc-27.2-linux-x86_64.zip -d /usr/local \
    && rm protoc-27.2-linux-x86_64.zip

# Install protoc-gen-php-grpc plugin
RUN git clone --recurse-submodules -b v1.38.0 https://github.com/grpc/grpc /grpc \
    && cd /grpc \
    && mkdir -p cmake/build \
    && cd cmake/build \
    && cmake ../.. \
    && make grpc_php_plugin \
    && cp grpc_php_plugin /usr/local/bin/protoc-gen-php-grpc \
    && cd / \
    && rm -rf /grpc

# Install PHP extensions for gRPC
RUN pecl install grpc \
    && docker-php-ext-enable grpc

RUN useradd -G www-data,root -u $UID -d /home/$USER $USER
RUN mkdir -p /home/$USER/.composer && \
    chown -R $USER:$USER /home/$USER

WORKDIR $WORKDIR

USER $USER

#CMD ["php-fpm"]
