FROM php:7.3-fpm-buster
LABEL maintainer='Fabien Schurter <fabien@fabschurt.com>'

# Add some PHP config tweaks
COPY config/* "${PHP_INI_DIR}/conf.d/"

# Install Composer
COPY --from=composer:1.9 /usr/bin/composer /usr/bin/composer

# Install some commonly-used dependencies
RUN \
  apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y \
    gettext-base \
    git \
    libbz2-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libpq-dev \
    libzip-dev \
    unzip \
    zip \
  && \
  docker-php-ext-configure \
    gd \
      --with-freetype-dir=/usr/include \
      --with-jpeg-dir=/usr/include \
  && \
  docker-php-ext-install \
    bz2 \
    gd \
    fileinfo \
    intl \
    pdo_mysql \
    pdo_pgsql \
    zip \
  && \
  rm -r /var/lib/apt/lists/*

###########
# ONBUILD #
###########

# Build args
ONBUILD ARG ENVIRONMENT=prod
ONBUILD ARG LOCAL_PROJECT_ROOT=.
ONBUILD ARG WORKING_DIRECTORY=/usr/src/app
ONBUILD ARG RUNTIME_USER_NAME=php
ONBUILD ARG RUNTIME_USER_UID=1000

# Env vars
ONBUILD ENV ENVIRONMENT="$ENVIRONMENT"
ONBUILD ENV PATH="${PATH}:${WORKING_DIRECTORY}/vendor/bin"

# Create the runtime user
ONBUILD RUN \
  adduser \
    --uid "$RUNTIME_USER_UID" \
    --disabled-login \
    --disabled-password \
    --gecos '' \
    "$RUNTIME_USER_NAME"

# Configure PHP according to the targeted environment
ONBUILD RUN \
  ln -s \
    "${PHP_INI_DIR}/php.ini-$([ "$ENVIRONMENT" = 'dev' ] && echo 'development' || echo 'production')" \
    "${PHP_INI_DIR}/php.ini"

# Ship the code
ONBUILD COPY "$LOCAL_PROJECT_ROOT" "$WORKING_DIRECTORY"
ONBUILD RUN chown -R "${RUNTIME_USER_UID}:${RUNTIME_USER_UID}" "$WORKING_DIRECTORY"

# Set the default runtime user and working directory
ONBUILD USER "$RUNTIME_USER_UID"
ONBUILD WORKDIR "$WORKING_DIRECTORY"

# Install prestissimo to speed up Composer installs
ONBUILD RUN composer global require hirak/prestissimo:^0.3

# Install Composer dependencies if appropriate
ONBUILD RUN \
  if [ -f composer.json ]; then \
    composer install \
      --no-interaction \
      $([ "$ENVIRONMENT" = 'dev' ] && echo '' || echo '--no-dev --prefer-dist --optimize-autoloader') \
  ; fi
