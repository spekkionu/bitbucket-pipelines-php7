FROM ubuntu:16.04

MAINTAINER Jonathan Bernardi <jon@jonbernardi.com>

# Use baseimage-docker's init system.
#CMD ["/sbin/my_init"]

# Set correct environment variables
ENV HOME /root

# Ensure UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8
RUN locale-gen en_US.UTF-8

# MYSQL ROOT PASSWORD
ARG MYSQL_ROOT_PASS=root    

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    software-properties-common \
    python-software-properties \
    build-essential \
    curl \
    git \
    unzip \
    mcrypt \
    wget \
    openssl \
    autoconf \
    g++ \
    make \
    --no-install-recommends && rm -r /var/lib/apt/lists/* \
    && apt-get --purge autoremove -y

# OpenSSL
RUN mkdir -p /usr/local/openssl/include/openssl/ && \
    ln -s /usr/include/openssl/evp.h /usr/local/openssl/include/openssl/evp.h && \
    mkdir -p /usr/local/openssl/lib/ && \
    ln -s /usr/lib/x86_64-linux-gnu/libssl.a /usr/local/openssl/lib/libssl.a && \
    ln -s /usr/lib/x86_64-linux-gnu/libssl.so /usr/local/openssl/lib/

# NODE JS
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
    apt-get install nodejs -qq && \
    npm install -g gulp
    
# YARN
RUN curl -o- -L https://yarnpkg.com/install.sh | bash

# MYSQL
# /usr/bin/mysqld_safe
RUN bash -c 'debconf-set-selections <<< "mysql-server-5.7 mysql-server/root_password password $MYSQL_ROOT_PASS"' && \
		bash -c 'debconf-set-selections <<< "mysql-server-5.7 mysql-server/root_password_again password $MYSQL_ROOT_PASS"' && \
		DEBIAN_FRONTEND=noninteractive apt-get update && \
		DEBIAN_FRONTEND=noninteractive apt-get install -qqy mysql-server-5.7
		
# PHP Extensions
RUN add-apt-repository -y ppa:ondrej/php && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y -qq php-pear php7.0-dev php7.0-fpm php7.0-mcrypt php7.0-zip php7.0-xml php7.0-mbstring php7.0-curl php7.0-json php7.0-mysql php7.0-tokenizer php7.0-cli php7.0-imap php7.0-intl php7.0-xsl php7.0-bcmath php7.0-iconv php7.0-libsodium && \
    apt-get remove --purge php5 php5-common

# Run xdebug installation.
RUN wget --no-check-certificate https://xdebug.org/files/xdebug-2.4.0rc4.tgz && \
    tar -xzf xdebug-2.4.0rc4.tgz && \
    rm xdebug-2.4.0rc4.tgz && \
    cd xdebug-2.4.0RC4 && \
    phpize && \
    ./configure --enable-xdebug && \
    make && \
    cp modules/xdebug.so /usr/lib/. && \
    echo 'zend_extension="/usr/lib/xdebug.so"' > /etc/php/7.0/cli/conf.d/20-xdebug.ini && \
    echo 'xdebug.remote_enable=1' >> /etc/php/7.0/cli/conf.d/20-xdebug.ini

# Time Zone
RUN echo "date.timezone=America/Los_Angeles" > /etc/php/7.0/cli/conf.d/date_timezone.ini && \
    echo "date.timezone=America/Los_Angeles" > /etc/php/7.0/fpm/conf.d/date_timezone.ini

VOLUME /root/composer

# Environmental Variables
ENV COMPOSER_HOME /root/composer

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Goto temporary directory.
WORKDIR /tmp

# Run phpunit installation.
RUN composer selfupdate && \
    composer global require hirak/prestissimo --prefer-dist --no-interaction && \
    composer require "phpunit/phpunit" --prefer-dist --no-interaction && \
    ln -s /tmp/vendor/bin/phpunit /usr/local/bin/phpunit && \
    rm -rf /root/.composer/cache/*

RUN service php7.0-fpm restart

RUN apt-get clean -y && \
		apt-get autoremove -y && \
		rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
