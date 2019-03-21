FROM php:7.2-fpm
LABEL maintainer='Fabien Schurter <fabien@fabschurt.com>'

# Install some common dependencies
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN \
  apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y \
    git \
    libbz2-dev \
    libicu-dev \
    libpq-dev \
    libzip-dev \
    unzip \
    zip \
  && \
  docker-php-ext-install \
    bz2 \
    fileinfo \
    intl \
    pdo_mysql \
    pdo_pgsql \
    zip

# Initialize the runtime environment (on child image build)
ONBUILD ARG APP_ROOT=/usr/src/app
ONBUILD ARG RUNTIME_USER_UID=1000
ONBUILD ARG RUNTIME_USER="${RUNTIME_USER_UID}:${RUNTIME_USER_UID}"
ONBUILD COPY . "$APP_ROOT"
ONBUILD RUN \
  adduser \
    --uid "$RUNTIME_USER_UID" \
    --disabled-login \
    --disabled-password \
    --gecos '' \
    php \
  && \
  chown -R "$RUNTIME_USER" "$APP_ROOT"

# Configure PHP according to the targeted app environment
ONBUILD ARG APP_ENV=prod
ONBUILD RUN cp \
  "${PHP_INI_DIR}/php.ini-$([ "$APP_ENV" = dev ] && echo development || echo production)" \
  "${PHP_INI_DIR}/php.ini"

# Some default config tweaks
COPY --chown=root:staff config/php.ini "${PHP_INI_DIR}/conf.d/"
