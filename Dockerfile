FROM php:8.3-apache

# =========================
# System Dependencies
# =========================
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libpq-dev \
    curl \
    git \
    unzip \
    ca-certificates \
    && docker-php-ext-install \
        intl \
        mbstring \
        xml \
        opcache \
        zip \
        pdo \
        pdo_mysql \
        pdo_pgsql \
    && rm -rf /var/lib/apt/lists/*


# =========================
# Apache Rewrite
# =========================
RUN a2enmod rewrite


# =========================
# MediaWiki 1.46.0
# =========================
ENV MEDIAWIKI_VERSION=1.46.0
ENV MEDIAWIKI_DOWNLOAD_URL=https://releases.wikimedia.org/mediawiki/1.46/mediawiki-1.46.0.tar.gz

RUN curl -fSL "$MEDIAWIKI_DOWNLOAD_URL" \
    -o /tmp/mediawiki.tar.gz \
    && tar -xzf /tmp/mediawiki.tar.gz \
    -C /var/www/html \
    --strip-components=1 \
    && rm /tmp/mediawiki.tar.gz


# =========================
# MobileFrontend
# =========================
RUN git clone \
    --depth 1 \
    --branch REL1_46 \
    https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileFrontend \
    /var/www/html/extensions/MobileFrontend


# =========================
# Apache DocumentRoot
# =========================
ENV APACHE_DOCUMENT_ROOT=/var/www/html

RUN sed -ri \
    -e "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" \
    /etc/apache2/sites-available/*.conf

RUN sed -ri \
    -e "s!/var/www/!${APACHE_DOCUMENT_ROOT}!g" \
    /etc/apache2/apache2.conf


# =========================
# Permissions
# =========================
RUN chown -R www-data:www-data /var/www/html


# =========================
# Render Port
# =========================
EXPOSE 10000


# =========================
# Start Apache
# =========================
CMD sed -ri \
    "s/Listen 80/Listen ${PORT:-10000}/g" \
    /etc/apache2/ports.conf \
    && sed -ri \
    "s/<VirtualHost \*:80>/<VirtualHost *:${PORT:-10000}>/g" \
    /etc/apache2/sites-available/000-default.conf \
    && apache2-foreground
