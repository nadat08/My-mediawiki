FROM php:8.2-apache

# ติดตั้ง System Dependencies และ PHP Extensions ที่ MediaWiki จำเป็นต้องใช้
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    git \
    unzip \
    && docker-php-ext-install \
        intl \
        mbstring \
        xml \
        opcache \
        zip \
        pdo \
        pdo_mysql \
        pdo_pgsql

# เปิดใช้งาน Apache Rewrite Module
RUN a2enmod rewrite

# ดาวน์โหลดและติดตั้ง MediaWiki 1.46.0
ENV MEDIAWIKI_VERSION=1.46.0
ENV MEDIAWIKI_DOWNLOAD_URL=https://releases.wikimedia.org/mediawiki/1.46/mediawiki-1.46.0.tar.gz

RUN curl -fSL "$MEDIAWIKI_DOWNLOAD_URL" -o mediawiki.tar.gz \
    && tar -xzf mediawiki.tar.gz -C /var/www/html --strip-components=1 \
    && rm mediawiki.tar.gz

# ปรับแต่ง DocumentRoot ของ Apache ไปที่ /var/www/html
ENV APACHE_DOCUMENT_ROOT /var/www/html
RUN sed -ri -s 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -s 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf

# ตั้งค่าสิทธิ์ให้ Apache สามารถเขียนไฟล์ได้ (เช่น โฟลเดอร์ images)
RUN chown -R www-data:www-data /var/www/html

# Render จะใช้ PORT ตามที่กำหนดผ่าน Environment Variable
EXPOSE 80
CMD sed -i "s/Listen 80/Listen ${PORT:-80}/g" /etc/apache2/ports.conf && apache2-foreground
