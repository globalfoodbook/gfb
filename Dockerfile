# Start with a base Ubuntu 14:04 image
FROM ubuntu:trusty

MAINTAINER Ikenna N. Okpala <me@ikennaokpala.com>

# Set up user environment

# Two users are defined one created by nginx and the other the host. This is for security reason www-data is configure accordingly with login disabled:
# sudo adduser --system --no-create-home --user-group --disabled-login --disabled-password www-data
#sudo adduser --system --no-create-home --user-group -s /sbin/nologin www-data

# Check before upgrade lua here https://github.com/openresty/lua-nginx-module#installation

ENV MY_USER=gfb WEB_USER=www-data DEBIAN_FRONTEND=noninteractive SERVER_URLS="globalfoodbook.com www.globalfoodbook.com globalfoodbook.net www.globalfoodbook.net globalfoodbook.org www.globalfoodbook.org globalfoodbook.co.uk www.globalfoodbook.co.uk" NUT_API_IP=127.0.0.1 NUT_API_PORT=8080 LANG=en_US.UTF-8 LANGUAGE=en_US.en LC_ALL=en_US.UTF-8 PSOL_VERSION=1.10.33.7 NGINX_VERSION=1.9.15 PHPREDIS_VERSION=2.2.7 WP_REDIS_VERSION=0.5.0 OPENRESTY_VERSION=1.9.15.1  OPENRESTY_PATH=/etc/openresty LUAROCKS_VERSION=2.3.0 LUA_MAIN_VERSION=5.1 RESTY_AUTO_SSL_PATH=/etc/resty-auto-ssl  GCS_MEDIA_BUCKET=assets.globalfoodbook.net GCS_MEDIA_MODE=cdn GCS_MEDIA_KEY_FILE_PATH=/gcs/media.p12 GCS_MEDIA_SERVICE_ACCOUNT=we@globalfoodbook.com OPENSSL_VERSION=1.0.2h SSL_ROOT=/etc/ssl LUAJIT_VERSION=2.1 LUA_SUFFIX=jit-2.1.0-beta2

ENV OPENRESTY_PATH_PREFIX=${OPENRESTY_PATH}/nginx NGINX_USER=${MY_USER} HOME=/home/${MY_USER} NPS_VERSION=${PSOL_VERSION}-beta
ENV APP_HOME=${HOME}/app NGINX_PATH_PREFIX=${OPENRESTY_PATH_PREFIX}/nginx
ENV NGX_PAGESPEED_PATH=${NGINX_PATH_PREFIX}/ngx_pagespeed  LUAJIT_ROOT=${OPENRESTY_PATH_PREFIX}/luajit WP_HOME=${APP_HOME}/wp
ENV NGX_PAGESPEED_RELEASE_PATH=${NGX_PAGESPEED_PATH}/ngx_pagespeed-release-${NPS_VERSION} NGINX_LOGS_PATH=${NGINX_PATH_PREFIX}/logs/${MY_USER}  NUT_API_IP_PORT=${NUT_API_IP}:${NUT_API_PORT} NUT_API_URL="http://${NUT_API_IP_PORT}/v1/nutrition/facts?ingredients=" OPENSSL_ROOT=${NGINX_PATH_PREFIX}/openssl-${OPENSSL_VERSION} PATH="${PATH}:${OPENRESTY_PATH}/bin:${NGINX_PATH_PREFIX}/sbin:${NGINX_PATH_PREFIX}/bin:${LUAJIT_ROOT}/bin"

ENV NGINX_FLAGS="--with-file-aio --with-ipv6 --with-http_ssl_module  --with-luajit-xcflags=-DLUAJIT_ENABLE_LUA52COMPAT --with-http_realip_module --with-http_addition_module --with-http_xslt_module --with-http_image_filter_module --with-http_geoip_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_stub_status_module --with-http_perl_module --with-mail --with-mail_ssl_module --with-pcre --with-google_perftools_module --with-debug --with-openssl=${OPENSSL_ROOT} --with-md5=${OPENSSL_ROOT} --with-md5-asm --with-sha1=${OPENSSL_ROOT} --add-module=${NGX_PAGESPEED_RELEASE_PATH}" PS_NGX_EXTRA_FLAGS="--with-cc=/usr/bin/gcc --with-ld-opt=-static-libstdc++"

RUN adduser --disabled-password --gecos "" $MY_USER && echo "$MY_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $MY_USER

# Add all base dependencies
RUN sudo apt-get update -y && sudo apt-get install -y build-essential \
  checkinstall language-pack-en-base musl-dev \
  vim curl tmux wget unzip libnotify-dev imagemagick libmagickwand-dev \
  libfuse-dev libcurl4-openssl-dev mime-support automake libtool \
  python-docutils libreadline-dev libxslt1-dev libgd2-xpm-dev libgeoip-dev \
  libgoogle-perftools-dev libperl-dev pkg-config libssl-dev git-core \
  subversion php5-redis man php5-cli imagemagick php5-imagick phantomjs \
  libgmp-dev zlib1g-dev libxslt-dev libxml2-dev libpcre3 libpcre3-dev \
  freetds-dev openjdk-7-jdk software-properties-common liblua5.2-dev liblua5.1-dev \
  libstdc++-4.8-dev libncurses5-dev libncursesw5-dev ncurses-dev \
  && sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db && sudo apt-get -y update \
  && sudo apt-get -y update && sudo apt-get -y install php5-mysql  \
  libsqlite3-dev php5 php5-dev php5-curl php-pear php5-fpm php5-gd \
  && /bin/bash -l -c "sudo wget https://github.com/phpredis/phpredis/archive/${PHPREDIS_VERSION}.zip && sudo unzip ${PHPREDIS_VERSION}.zip && cd phpredis-${PHPREDIS_VERSION} && sudo phpize && sudo ./configure && sudo make && sudo make install" \
  && sudo mkdir -p ${OPENSSL_ROOT} ${NGINX_PATH_PREFIX}/lua_ssl ${NGX_PAGESPEED_PATH} ${NGINX_LOGS_PATH}

# RUN echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' | sudo tee /etc/apt/sources.list.d/newrelic.list \
#   && /bin/bash -l -c "wget -O- https://download.newrelic.com/548C16BF.gpg | sudo apt-key add - " \
#   && sudo apt-get update -y && sudo apt-get install -y newrelic-php5 && sudo newrelic-install install

ADD templates/nginx/nginx_init.sh /etc/init.d/nginx
RUN /bin/bash -l -c "sudo wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}.zip -O ${NGX_PAGESPEED_PATH}/release-${NPS_VERSION}.zip; sudo unzip ${NGX_PAGESPEED_PATH}/release-${NPS_VERSION}.zip -d ${NGX_PAGESPEED_PATH}; sudo wget https://dl.google.com/dl/page-speed/psol/${PSOL_VERSION}.tar.gz -O ${NGX_PAGESPEED_PATH}/${PSOL_VERSION}.tar.gz; sudo tar -xzvf ${NGX_PAGESPEED_PATH}/${PSOL_VERSION}.tar.gz -C ${NGX_PAGESPEED_RELEASE_PATH} && sudo wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -O ${NGINX_PATH_PREFIX}/openssl-${OPENSSL_VERSION}.tar.gz && sudo tar -xzvf ${NGINX_PATH_PREFIX}/openssl-${OPENSSL_VERSION}.tar.gz -C ${NGINX_PATH_PREFIX}/" \
  && /bin/bash -l -c "sudo wget https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz -O /etc/openresty-${OPENRESTY_VERSION}.tar.gz && sudo tar -xzvf /etc/openresty-${OPENRESTY_VERSION}.tar.gz -C /etc && cd /etc/openresty-${OPENRESTY_VERSION} && sudo ./configure --prefix=${OPENRESTY_PATH_PREFIX} ${PS_NGX_EXTRA_FLAGS} ${NGINX_FLAGS} && sudo make && sudo make install && sudo ln -sf ${LUAJIT_ROOT}/bin/${LUA_SUFFIX} ${LUAJIT_ROOT}/bin/lua && sudo ln -sf ${LUAJIT_ROOT}/bin/lua /usr/local/bin/lua" \
  && /bin/bash -l -c "sudo wget https://github.com/keplerproject/luarocks/archive/v${LUAROCKS_VERSION}.tar.gz -O ${OPENRESTY_PATH}/v${LUAROCKS_VERSION}.tar.gz && sudo tar -xzvf ${OPENRESTY_PATH}/v${LUAROCKS_VERSION}.tar.gz -C ${OPENRESTY_PATH} && cd ${OPENRESTY_PATH}/luarocks-${LUAROCKS_VERSION} && sudo ./configure --prefix=${LUAJIT_ROOT} --with-lua=${LUAJIT_ROOT} --lua-suffix=${LUA_SUFFIX} --sysconfdir=${LUAJIT_ROOT}/luarocks --with-lua-lib=${LUAJIT_ROOT}/lib --with-lua-include=${LUAJIT_ROOT}/include/luajit-${LUAJIT_VERSION} --force-config && sudo make build && sudo make install && sudo ${LUAJIT_ROOT}/bin/luarocks install lua-resty-auto-ssl && sudo mkdir -p ${RESTY_AUTO_SSL_PATH} && sudo chown ${MY_USER} ${RESTY_AUTO_SSL_PATH} && sudo rm -rf ${OPENRESTY_PATH}/*.zip  ${OPENRESTY_PATH}/*.tar.gz ${OPENRESTY_PATH}/luarocks-${LUAROCKS_VERSION} /etc/openresty-*" \
  && sudo openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
  -subj '/CN=sni-support-required-for-valid-ssl' \
  -keyout ${SSL_ROOT}/resty-auto-ssl-fallback.key \
  -out ${SSL_ROOT}/resty-auto-ssl-fallback.crt \
  && sudo mkdir -p $NGINX_PATH_PREFIX/sites-available/ $NGINX_PATH_PREFIX/sites-enabled/ $NGINX_PATH_PREFIX/logs/$MY_USER/ $NGINX_PATH_PREFIX/conf/$MY_USER/ $HOME/templates/ \
  && /bin/bash -l -c "sudo chmod +x /etc/init.d/nginx && sudo update-rc.d nginx defaults"

ADD templates/wp-config.php $HOME/templates/wp-config.php

ADD templates/nginx/default $NGINX_PATH_PREFIX/conf/$MY_USER/default
ADD templates/nginx/default $HOME/templates/default
ADD templates/nginx/nginx.conf $NGINX_PATH_PREFIX/conf/nginx.conf
ADD templates/nginx/nginx.conf $HOME/templates/nginx.conf
ADD templates/nginx/port_* $NGINX_PATH_PREFIX/sites-available/
ADD templates/nginx/port_* $HOME/templates/
ADD templates/nginx/lua/* $NGINX_PATH_PREFIX/lua_ssl/
ADD templates/nginx/lua/* $HOME/templates/

ADD templates/nginx/w3tc.conf $NGINX_PATH_PREFIX/conf/$MY_USER/w3tc.conf
ADD templates/nginx/ngx_page_speed_x.conf $NGINX_PATH_PREFIX/conf/$MY_USER/ngx_page_speed_x.conf

RUN sudo ln -s $NGINX_PATH_PREFIX/sites-available/port_80 $NGINX_PATH_PREFIX/sites-enabled/port_80 \
  && sudo ln -s $NGINX_PATH_PREFIX/sites-available/port_443 $NGINX_PATH_PREFIX/sites-enabled/port_443 \
  && sudo ln -s $NGINX_PATH_PREFIX/sites-available/port_5118 $NGINX_PATH_PREFIX/sites-enabled/port_5118 \
  && sudo cp $NGINX_PATH_PREFIX/conf/nginx.conf $NGINX_PATH_PREFIX/conf/nginx.conf.default \
  && sudo rm $NGINX_PATH_PREFIX/conf/nginx.conf && cd $NGINX_PATH_PREFIX/conf/ \
  && sudo rm -rf /home/$MY_USER/nginx-${NGINX_VERSION}* \
  && curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /usr/local

RUN /bin/bash -l -c "sudo wget http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -O /usr/local/ioncube_loaders_lin_x86-64.tar.gz" \
  && sudo tar xzf /usr/local/ioncube_loaders_lin_x86-64.tar.gz && sudo rm -f ioncube_loaders_lin_x86-64.tar.gz \
  && zend_ext="\n\nzend_extension=/usr/local/ioncube/ioncube_loader_lin_5.5.so" && sudo echo -e "$(cat /etc/php5/fpm/php.ini)$zend_ext" > ~/php.ini && sudo mv ~/php.ini /etc/php5/fpm/php.ini \
  && sudo sed -i s'/variables_order = "GPCS"/variables_order = "EGPCS"/' /etc/php5/fpm/php.ini \
  && sudo sed -i s'/memory_limit = 128M/memory_limit = 3000M/' /etc/php5/fpm/php.ini \
  && sudo sed -i s'/upload_max_filesize = 2M/upload_max_filesize = 1000M/' /etc/php5/fpm/php.ini \
  && sudo sed -i s'/post_max_size = 8M/post_max_size = 2000M/' /etc/php5/fpm/php.ini \
  && sudo sed -i s'/max_execution_time = 30/max_execution_time = 10000/' /etc/php5/fpm/php.ini \
  && exp="\n\nenv[NUT_API] = '$NUT_API_URL'"; sudo echo -e "$(cat /etc/php5/fpm/php-fpm.conf)$exp" > ~/php-fpm.conf; sudo mv ~/php-fpm.conf /etc/php5/fpm/php-fpm.conf \
  && sudo sed -i s'/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/' /etc/php5/fpm/pool.d/www.conf \
  && sudo sed -i s'/;request_terminate_timeout = 0/request_terminate_timeout = 500/' /etc/php5/fpm/pool.d/www.conf \
  && sudo sed -i s"/user = $WEB_USER/user = $NGINX_USER/" /etc/php5/fpm/pool.d/www.conf \
  && sudo sed -i s"/group = $WEB_USER/group = $NGINX_USER/" /etc/php5/fpm/pool.d/www.conf \
  && sudo sed -i s"/listen.owner = $WEB_USER/listen.owner = $NGINX_USER/" /etc/php5/fpm/pool.d/www.conf \
  && sudo sed -i s"/listen.group = $WEB_USER/listen.group = $NGINX_USER/" /etc/php5/fpm/pool.d/www.conf \
  && sudo echo "Europe/London" | sudo tee /etc/timezone && sudo dpkg-reconfigure --frontend $DEBIAN_FRONTEND tzdata

ADD templates/entrypoint.sh /etc/entrypoint.sh
RUN sudo chmod +x /etc/entrypoint.sh

WORKDIR $APP_HOME

EXPOSE 80
EXPOSE 443
EXPOSE 5118

# Setup the entrypoint
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["/etc/entrypoint.sh"]
