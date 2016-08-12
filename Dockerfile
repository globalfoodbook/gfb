# Start with a base Ubuntu 14:04 image
FROM ubuntu:trusty

MAINTAINER Ikenna N. Okpala <me@ikennaokpala.com>

# Set up user environment

# Two users are defined one created by nginx and the other the host. This is for security reason www-data is configure accordingly with login disabled:
# sudo adduser --system --no-create-home --user-group --disabled-login --disabled-password www-data
#sudo adduser --system --no-create-home --user-group -s /sbin/nologin www-data

ENV MY_USER=gfb WEB_USER=www-data DEBIAN_FRONTEND=noninteractive LOCAL_HOST_IP=0.0.0.0 NUT_API_PORT=8080 LANG=en_US.UTF-8 LANGUAGE=en_US.en LC_ALL=en_US.UTF-8 PHPREDIS_VERSION=2.2.7 WP_REDIS_VERSION=0.5.0 SERVER_URLS="globalfoodbook.com www.globalfoodbook.com globalfoodbook.net www.globalfoodbook.net globalfoodbook.org www.globalfoodbook.org globalfoodbook.co.uk www.globalfoodbook.co.uk" GCS_MEDIA_BUCKET=assets.globalfoodbook.net GCS_MEDIA_MODE=cdn GCS_MEDIA_KEY_FILE_PATH=/gcs/media.p12 GCS_MEDIA_SERVICE_ACCOUNT=we@globalfoodbook.com PHP_FPM_PORT=9000 PHP_FPM_PATH=/etc/php5/fpm PSOL_VERSION=1.11.33.2 NGINX_VERSION=1.9.15 OPENRESTY_VERSION=1.9.15.1  OPENRESTY_PATH=/etc/openresty LUAROCKS_VERSION=2.3.0 LUA_MAIN_VERSION=5.1 OPENSSL_VERSION=1.0.2h LUAJIT_VERSION=2.1 LUA_SUFFIX=jit-2.1.0-beta2
ENV OPENRESTY_PATH_PREFIX=${OPENRESTY_PATH}/${MY_USER} NGINX_USER=${MY_USER} HOME=/home/${MY_USER} NPS_VERSION=${PSOL_VERSION}-beta
ENV NGINX_PATH_PREFIX=${OPENRESTY_PATH_PREFIX}/nginx LUAJIT_ROOT=${OPENRESTY_PATH_PREFIX}/luajit
ENV NGX_PAGESPEED_PATH=${NGINX_PATH_PREFIX}/ngx_pagespeed NGINX_LOG_PATH=${NGINX_PATH_PREFIX}/logs NGINX_CONF_PATH=${NGINX_PATH_PREFIX}/conf
ENV NGX_PAGESPEED_RELEASE_PATH=${NGX_PAGESPEED_PATH}/ngx_pagespeed-release-${NPS_VERSION} NGINX_USER_CONF_PATH=${NGINX_CONF_PATH}/${MY_USER} OPENSSL_ROOT=${NGINX_PATH_PREFIX}/openssl-${OPENSSL_VERSION} NGINX_USER_LOG_PATH=${NGINX_LOG_PATH}/${MY_USER} NUT_API_IP=${LOCAL_HOST_IP} PATH="${PATH}:${OPENRESTY_PATH}/bin:${NGINX_PATH_PREFIX}/sbin:${NGINX_PATH_PREFIX}/bin:${LUAJIT_ROOT}/bin" LUAJIT_PACKAGE_PATH=${LUAJIT_ROOT}/share/lua/${LUA_MAIN_VERSION}
ENV NUT_API_IP_PORT=${NUT_API_IP}:${NUT_API_PORT} HOME=/home/${MY_USER} PHP_FPM_CONF=${PHP_FPM_PATH}/php-fpm.conf PHP_FPM_POOL_CONF=${PHP_FPM_PATH}/pool.d/www.conf PHP_FPM_INI=${PHP_FPM_PATH}/php.ini PHP_FPM_IP=${LOCAL_HOST_IP}

ENV NUT_API_URL="http://${NUT_API_IP_PORT}/v1/nutrition/facts?ingredients=" APP_HOME=${HOME}/app USER_TEMPLATES_PATH=${HOME}/templates
ENV WP_HOME=${APP_HOME}/wp PHP_FPM_IP_PORT=${PHP_FPM_IP}:${PHP_FPM_PORT}

ENV NGINX_FLAGS="--with-file-aio --with-ipv6 --with-http_ssl_module  --with-luajit-xcflags=-DLUAJIT_ENABLE_LUA52COMPAT --with-http_realip_module --with-http_addition_module --with-http_xslt_module --with-http_image_filter_module --with-http_geoip_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_stub_status_module --with-http_perl_module --with-mail --with-mail_ssl_module --with-pcre --with-google_perftools_module --with-debug --with-openssl=${OPENSSL_ROOT} --with-md5=${OPENSSL_ROOT} --with-md5-asm --with-sha1=${OPENSSL_ROOT} --add-module=${NGX_PAGESPEED_RELEASE_PATH}" PS_NGX_EXTRA_FLAGS="--with-cc=/usr/bin/gcc --with-ld-opt=-static-libstdc++" OBJ_FILE_PATH="${WP_HOME}/wp-content/object-cache.php" WP_REDIS_OBJ_FILE_PATH="${WP_HOME}/wp-content/plugins/wp-redis/object-cache.php"

RUN adduser --disabled-password --gecos "" ${MY_USER} && echo "${MY_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${MY_USER}

ADD templates/wp-config.php $HOME/templates/wp-config.php
ADD templates/nginx/init.sh /etc/init.d/nginx

# Add all base dependencies
RUN sudo apt-get update -y \
  && sudo apt-get install -y build-essential checkinstall language-pack-en-base \
  vim curl tmux wget unzip libnotify-dev imagemagick libmagickwand-dev \
  libfuse-dev libcurl4-openssl-dev mime-support automake libtool \
  python-docutils libreadline-dev libxslt1-dev libgd2-xpm-dev libgeoip-dev \
  libgoogle-perftools-dev libperl-dev pkg-config libssl-dev git-core subversion \
  php5-intl  php5-imap php5-mcrypt php5-memcache php5-ming php5-ps php5-pspell \
  php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl \
  php5-redis man php5-cli imagemagick php5-imagick phantomjs libgmp-dev \
  zlib1g-dev libxslt-dev libxml2-dev libpcre3 libpcre3-dev freetds-dev \
  openjdk-7-jdk software-properties-common libpng12-dev libjpeg-dev \
  && sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db \
  && sudo apt-get -y update \
  && sudo apt-get -y install php5-mysql libsqlite3-dev php5 php5-dev php5-curl php-pear php5-fpm php5-gd \
  && /bin/bash -l -c "sudo wget https://github.com/phpredis/phpredis/archive/${PHPREDIS_VERSION}.zip && sudo unzip ${PHPREDIS_VERSION}.zip && cd phpredis-${PHPREDIS_VERSION} && sudo phpize && sudo ./configure && sudo make && sudo make install" \
  && sudo mkdir -p ${OPENSSL_ROOT} ${NGINX_USER_CONF_PATH}/enabled ${NGINX_USER_CONF_PATH}/configs ${NGINX_USER_CONF_PATH}/lua/ ${USER_TEMPLATES_PATH}/enabled ${USER_TEMPLATES_PATH}/configs ${USER_TEMPLATES_PATH}/conf ${USER_TEMPLATES_PATH}/lua/ ${NGX_PAGESPEED_PATH} ${NGINX_LOG_PATH} ${NGINX_USER_LOG_PATH} \
  && /bin/bash -l -c "sudo wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}.zip -O ${NGX_PAGESPEED_PATH}/release-${NPS_VERSION}.zip; sudo unzip ${NGX_PAGESPEED_PATH}/release-${NPS_VERSION}.zip -d ${NGX_PAGESPEED_PATH}; sudo wget https://dl.google.com/dl/page-speed/psol/${PSOL_VERSION}.tar.gz -O ${NGX_PAGESPEED_PATH}/${PSOL_VERSION}.tar.gz; sudo tar -xzvf ${NGX_PAGESPEED_PATH}/${PSOL_VERSION}.tar.gz -C ${NGX_PAGESPEED_RELEASE_PATH} && sudo wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -O ${NGINX_PATH_PREFIX}/openssl-${OPENSSL_VERSION}.tar.gz && sudo tar -xzvf ${NGINX_PATH_PREFIX}/openssl-${OPENSSL_VERSION}.tar.gz -C ${NGINX_PATH_PREFIX}/"  \
  && /bin/bash -l -c "sudo wget https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz -O /etc/openresty-${OPENRESTY_VERSION}.tar.gz && sudo tar -xzvf /etc/openresty-${OPENRESTY_VERSION}.tar.gz -C /etc && cd /etc/openresty-${OPENRESTY_VERSION} && sudo ./configure --prefix=${OPENRESTY_PATH_PREFIX} ${PS_NGX_EXTRA_FLAGS} ${NGINX_FLAGS} && sudo make && sudo make install && sudo ln -sf ${LUAJIT_ROOT}/bin/${LUA_SUFFIX} ${LUAJIT_ROOT}/bin/lua && sudo ln -sf ${LUAJIT_ROOT}/bin/lua /usr/local/bin/lua"  \
  && /bin/bash -l -c "sudo wget https://github.com/keplerproject/luarocks/archive/v${LUAROCKS_VERSION}.tar.gz -O ${OPENRESTY_PATH}/v${LUAROCKS_VERSION}.tar.gz && sudo tar -xzvf ${OPENRESTY_PATH}/v${LUAROCKS_VERSION}.tar.gz -C ${OPENRESTY_PATH} && cd ${OPENRESTY_PATH}/luarocks-${LUAROCKS_VERSION} && sudo ./configure --prefix=${LUAJIT_ROOT} --with-lua=${LUAJIT_ROOT} --lua-suffix=${LUA_SUFFIX} --sysconfdir=${LUAJIT_ROOT}/luarocks --with-lua-lib=${LUAJIT_ROOT}/lib --with-lua-include=${LUAJIT_ROOT}/include/luajit-${LUAJIT_VERSION} --force-config && sudo make build && sudo make install"  \
  && sudo rm -rf ${OPENRESTY_PATH}/*.zip  ${OPENRESTY_PATH}/*.tar.gz ${NGINX_USER_CONF_PATH}/*.tar.gz ${NGINX_USER_CONF_PATH}/*.zip ${OPENRESTY_PATH}/luarocks-${LUAROCKS_VERSION} /etc/openresty-* \
  && /bin/bash -l -c "sudo chmod +x /etc/init.d/nginx && sudo update-rc.d nginx defaults"

ADD templates/nginx/conf/*.conf ${USER_TEMPLATES_PATH}/conf/
ADD templates/nginx/enabled/*.conf ${USER_TEMPLATES_PATH}/enabled/
ADD templates/nginx/configs/*.conf ${USER_TEMPLATES_PATH}/configs/
ADD templates/nginx/lua/* ${USER_TEMPLATES_PATH}/lua/

WORKDIR /usr/local

RUN /bin/bash -l -c "sudo wget http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -O /usr/local/ioncube_loaders_lin_x86-64.tar.gz" \
  && sudo tar xzf /usr/local/ioncube_loaders_lin_x86-64.tar.gz && sudo rm -f ioncube_loaders_lin_x86-64.tar.gz \
  && zend_ext="\n\nzend_extension=/usr/local/ioncube/ioncube_loader_lin_5.5.so" && sudo echo -e "$(cat ${PHP_FPM_INI})$zend_ext" > ~/php.ini && sudo mv ~/php.ini ${PHP_FPM_INI} \
  && sudo sed -i s'/variables_order = "GPCS"/variables_order = "EGPCS"/' ${PHP_FPM_INI} \
  && sudo sed -i s'/memory_limit = 128M/memory_limit = 3000M/' ${PHP_FPM_INI} \
  && sudo sed -i s'/upload_max_filesize = 2M/upload_max_filesize = 1000M/' ${PHP_FPM_INI} \
  && sudo sed -i s'/post_max_size = 8M/post_max_size = 2000M/' ${PHP_FPM_INI} \
  && sudo sed -i s'/max_execution_time = 30/max_execution_time = 10000/' ${PHP_FPM_INI} \
  && exp="\n\nenv[NUT_API] = '$NUT_API_URL'"; sudo echo -e "$(cat ${PHP_FPM_CONF})$exp" > ~/php-fpm.conf; sudo mv ~/php-fpm.conf ${PHP_FPM_CONF} \
  && sudo sed -i s"/listen = \/var\/run\/php5-fpm.sock/listen = ${PHP_FPM_IP_PORT}/" ${PHP_FPM_POOL_CONF} \
  && sudo sed -i s'/;request_terminate_timeout = 0/request_terminate_timeout = 30/' ${PHP_FPM_POOL_CONF} \
  && sudo sed -i s"/user = ${WEB_USER}/user = ${MY_USER}/" ${PHP_FPM_POOL_CONF} \
  && sudo sed -i s"/group = ${WEB_USER}/group = ${MY_USER}/" ${PHP_FPM_POOL_CONF} \
  && sudo sed -i s"/listen.owner = ${WEB_USER}/listen.owner = ${MY_USER}/" ${PHP_FPM_POOL_CONF} \
  && sudo sed -i s"/listen.group = ${WEB_USER}/listen.group = ${MY_USER}/" ${PHP_FPM_POOL_CONF} \
  && sudo sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" ${PHP_FPM_POOL_CONF} \
  && sudo sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" ${PHP_FPM_POOL_CONF} \
  && sudo find /etc/php5/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \; \
  && sudo sed -i s"/;listen.allowed_clients = 127.0.0.1/listen.allowed_clients = ${PHP_FPM_IP}/" ${PHP_FPM_POOL_CONF} \
  # && sudo sed -i -e "/listen.allowed_clients/d" ${PHP_FPM_POOL_CONF} \
  && sudo sed -i -e "/error_log/d" ${PHP_FPM_POOL_CONF} \
  && sudo echo "Europe/London" | sudo tee /etc/timezone && sudo dpkg-reconfigure --frontend $DEBIAN_FRONTEND tzdata

ADD templates/entrypoint.sh /etc/entrypoint.sh
RUN sudo chmod +x /etc/entrypoint.sh

WORKDIR ${APP_HOME}

EXPOSE ${PHP_FPM_PORT}
EXPOSE 80
EXPOSE 5119

# Setup the entrypoint
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["/etc/entrypoint.sh"]
