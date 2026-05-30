# PHP-FPM Laravel Dev Images (with gRPC)

[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![PHP](https://img.shields.io/badge/php-7.4%20%7C%208.2%20%7C%208.3%20%7C%208.4-777BB4?style=flat-square&logo=php&logoColor=white)](https://www.php.net/)
[![Laravel](https://img.shields.io/badge/laravel-ready-FF2D20?style=flat-square&logo=laravel&logoColor=white)](https://laravel.com/)
[![gRPC](https://img.shields.io/badge/gRPC-built--in-244C5A?style=flat-square&logo=grpc&logoColor=white)](https://grpc.io/)
[![Build](https://github.com/oooiik/docker_php-fpm-laravel/actions/workflows/build.yml/badge.svg)](https://github.com/oooiik/docker_php-fpm-laravel/actions/workflows/build.yml)

Pre-built PHP-FPM Docker images tuned for local Laravel development — with **gRPC support compiled in from source**, so you can stop fighting `pecl install grpc` and `protoc-gen-php-grpc` setup on every new project.

```bash
# In your Laravel project's docker-compose.yml:
services:
  php:
    image: oooiik/php:8.3-fpm-laravel
    volumes:
      - .:/app
    ports:
      - "9000:9000"
```

That's it — Composer, all common PHP extensions, gRPC tooling, and Xdebug are already inside.

## Why this exists

Setting up gRPC for PHP in a Laravel project usually means:

1. Installing `protoc` and pinning a version
2. Building `protoc-gen-php-grpc` from the gRPC C++ source (with `cmake`, `make`, ~10 min build time)
3. `pecl install grpc` + `docker-php-ext-enable grpc`
4. Adding all the right `libssl`, `libpq`, `libffi` system packages so the above actually compiles
5. Repeating all of that in every project's Dockerfile

These images do all of that once, so your project Dockerfile becomes a one-liner.

## What's inside

Each image extends the official `php:X.Y-fpm` base and adds:

### gRPC stack (the hard part)
- **`protoc`** v27.2 — Protocol Buffers compiler
- **`protoc-gen-php-grpc`** v1.38.0 — built from source, ready in `$PATH`
- **`grpc`** PHP extension — installed via PECL and enabled

### PHP extensions (compiled)
`pgsql` · `pdo_pgsql` · `pdo_mysql` · `zip` · `mbstring` · `exif` · `pcntl` · `bcmath` · `gd` · `calendar` · `ffi`

### PECL extensions
`xdebug` · `redis` · `mongodb` · `mailparse`

### Tools
- **Composer** (latest, copied from `composer:latest`)
- **System libs** for compiling PHP extensions: `libzip-dev`, `libpng-dev`, `libonig-dev`, `libxml2-dev`, `libssl-dev`, `libpq-dev`, `libffi-dev`, `cmake`, `build-essential`, `pkg-config`

### Runtime
- Non-root user (`user`, UID 1000) — keeps file ownership sane when mounting host volumes
- `WORKDIR /app`
- Exposes port 9000 (php-fpm)

## Available tags

| Tag | PHP version | Base image |
|---|---|---|
| `oooiik/php:7.4-fpm-laravel` | 7.4 | `php:7.4-fpm` |
| `oooiik/php:8.2-fpm-laravel` | 8.2 | `php:8.2-fpm` |
| `oooiik/php:8.3-fpm-laravel` | 8.3 | `php:8.3-fpm` |
| `oooiik/php:8.4-fpm-laravel` | 8.4 | `php:8.4-fpm` |

## Usage

### Pull from Docker Hub

```bash
docker pull oooiik/php:8.3-fpm-laravel
```

### Docker Compose (typical Laravel local setup)

```yaml
services:
  php:
    image: oooiik/php:8.3-fpm-laravel
    user: "1000:1000"
    working_dir: /app
    volumes:
      - .:/app
    environment:
      PHP_IDE_CONFIG: "serverName=Docker"

  nginx:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - .:/app
      - ./docker/nginx.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - php

  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: app
      POSTGRES_USER: app
      POSTGRES_PASSWORD: secret
    ports:
      - "5432:5432"
```

### Build customizations

Each image accepts these build args if you build it yourself:

| ARG | Default | Purpose |
|---|---|---|
| `USER` | `user` | Runtime user name |
| `UID` | `1000` | Match your host UID to avoid volume permission issues |
| `PORT` | `9000` | php-fpm listen port |
| `WORKDIR` | `/app` | Working directory inside the container |

```bash
docker build \
  --build-arg UID=$(id -u) \
  -t my-app/php:8.3-fpm-laravel \
  -f php:8.3-fpm-laravel.Dockerfile .
```

### Generating PHP from `.proto` files

Since `protoc` and `protoc-gen-php-grpc` are baked in:

```bash
docker run --rm -v $(pwd):/app oooiik/php:8.3-fpm-laravel \
  protoc \
    --php_out=./generated \
    --grpc_out=./generated \
    --plugin=protoc-gen-grpc=/usr/local/bin/protoc-gen-php-grpc \
    your_service.proto
```

## Building locally

Clone and build any version:

```bash
git clone https://github.com/oooiik/docker_php-fpm-laravel.git
cd docker_php-fpm-laravel

# Pick a version
docker build -t php:8.3-fpm-laravel -f php:8.3-fpm-laravel.Dockerfile .
```

### Build all versions at once

```bash
for v in 7.4 8.2 8.3 8.4; do
  docker build -t oooiik/php:${v}-fpm-laravel -f php:${v}-fpm-laravel.Dockerfile .
done
```

### Publish to Docker Hub

```bash
for v in 7.4 8.2 8.3 8.4; do
  docker push oooiik/php:${v}-fpm-laravel
done
```

## Notes & caveats

- **Designed for local development.** Xdebug is enabled in all images, which makes them too heavy for production. Use `php:X.Y-fpm-alpine` with a slimmer extension set for prod.
- **First build is slow.** Compiling `protoc-gen-php-grpc` from the gRPC C++ source takes 5–10 minutes on most laptops. Subsequent pulls from Docker Hub are fast.
- **PHP 7.4** is included for legacy projects only — it's been EOL since November 2022. Migrate when you can.
- **Architecture:** images are built for `linux/amd64`. ARM (Apple Silicon) users may want to add `--platform linux/amd64` or rebuild locally.

## Contributing

Pull requests and issues are welcome — especially for additional PHP versions or ARM-native builds.

## License

[MIT](LICENSE) — Obidjon Toshev