FROM php:8.1-fpm

ENV LIBZIP_CFLAGS \
    LIBZIP_LIBS

# Prerequisites installation
RUN apt-get update \
    && apt-get install -y libzip-dev \
     libicu-dev \
     libxslt-dev \
     libpng-dev \
     zlib1g-dev \
     libjpeg-dev \
     libfreetype6-dev \
     build-essential \
     libpcre3 \
     libpcre3-dev \
     zlib1g \
     zlib1g-dev \
     libssl-dev \
     libgd-dev \
     libxml2 \
     libxml2-dev \
     uuid-dev \
     wget \
     nginx \
     supervisor \
	&& mkdir -p /run/nginx

# Configure magento extension
RUN set -xe \
    && docker-php-ext-configure bcmath --enable-bcmath \
    && docker-php-ext-configure sockets --enable-sockets \
    && docker-php-ext-configure zip \
    && docker-php-ext-configure intl --enable-intl \
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql \
    && docker-php-ext-configure xsl \
    && docker-php-ext-configure soap --enable-soap \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        zip \
        intl \
        pdo_mysql \
        soap \
        xsl \
        sockets \
        opcache

RUN docker-php-ext-configure gd \
    #--with-png=/usr/include/ \
    --with-jpeg=/usr/include/ \
    --with-freetype=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-enable gd

RUN pecl install mailparse \
    && docker-php-ext-enable mailparse
    
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug
    
# Configure PHP-FPM
COPY ./docker-config/php/php.ini "$PHP_INI_DIR/php.ini"
COPY ./docker-config/php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY ./docker-config/php/xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
COPY ./docker-config/php/error_reporting.ini /usr/local/etc/php/conf.d/error_reporting.ini
# RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
# COPY ./php.ini /usr/local/etc/php/php.ini

# Configure nginx
COPY ./docker-config/nginx/app.conf /etc/nginx/conf.d/default.conf
RUN rm -rf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default 


# Configure supervisord
COPY ./docker-config/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# stdout configuration for nginx logs
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Working/Code Directory
WORKDIR /var/www/html

# Code copy
COPY . .

RUN sh setup.sh

# Port expose 
EXPOSE 9000 80

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

