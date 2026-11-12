FROM php:8.2-apache

# Ekstensi yang dibutuhkan stokbarang (mysqli) + opsi PDO
RUN docker-php-ext-install -j"$(nproc)" mysqli pdo_mysql opcache \
    && a2enmod rewrite headers expires \
    && rm -rf /var/lib/apt/lists/*

# Folder kerja default image sudah /var/www/html
WORKDIR /var/www/html
