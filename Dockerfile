# Start with a base Ubuntu 14:04 image
FROM ubuntu:trusty

MAINTAINER Ikenna N. Okpala <me@ikennaokpala.com>

# Set up user environment

# Two users are defined one created by nginx and the other the host. This is for security reason www-data is configure accordingly with login disabled:
# sudo adduser --system --no-create-home --user-group --disabled-login --disabled-password www-data
#sudo adduser --system --no-create-home --user-group -s /sbin/nologin www-data

ENV MY_USER=gfb WEB_USER=www-data NGINX_PATH_PREFIX=/etc/nginx SERVER_URLS="globalfoodbook.com www.globalfoodbook.com globalfoodbook.net www.globalfoodbook.net globalfoodbook.org www.globalfoodbook.org globalfoodbook.co.uk www.globalfoodbook.co.uk" DEBIAN_FRONTEND=noninteractive LANG=en_US.UTF-8 LANGUAGE=en_US.en LC_ALL=en_US.UTF-8 NGINX_VERSION=1.9.15 PSOL_VERSION=1.10.33.7 PHPREDIS_VERSION=2.2.7 WP_REDIS_VERSION=0.5.0 GCS_MEDIA_BUCKET=assets.globalfoodbook.net GCS_MEDIA_MODE=cdn GCS_MEDIA_KEY_FILE_PATH=/gcs/media.p12 GCS_MEDIA_SERVICE_ACCOUNT=we@globalfoodbook.com NUT_API_IP=127.0.0.1 NUT_API_PORT=8080 PHP_FPM_PATH=/etc/php5/fpm

ENV NPS_VERSION=$PSOL_VERSION-beta NGINX_USER=$MY_USER HOME=/home/$MY_USER APP_HOME=/home/$MY_USER/app NUT_API_IP_PORT=$NUT_API_IP:$NUT_API_PORT NGINX_CONF_PATH=$NGINX_PATH_PREFIX/conf NGINX_USER_CONF_PATH=$NGINX_PATH_PREFIX/conf/$MY_USER NGINX_USER_LOG_PATH=$NGINX_PATH_PREFIX/logs/$MY_USER PHP_FPM_INI=$PHP_FPM_PATH/php.ini PHP_FPM_POOL_CONF=$PHP_FPM_PATH/pool.d/www.conf PHP_FPM_CONF=$PHP_FPM_PATH/php-fpm.conf
ENV WP_HOME=$APP_HOME/wp NUT_API_URL=http://$NUT_API_IP_PORT/v1/nutrition/facts?ingredients= USER_TEMPLATES_PATH=$HOME/templates

ENV NGINX_FLAGS="--with-file-aio --with-ipv6 --with-http_ssl_module  --with-http_realip_module --with-http_addition_module --with-http_xslt_module --with-http_image_filter_module --with-http_geoip_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_stub_status_module --with-http_perl_module --with-mail --with-mail_ssl_module --with-pcre --with-google_perftools_module --with-debug" PS_NGX_EXTRA_FLAGS="--with-cc=/usr/bin/gcc --with-ld-opt=-static-libstdc++"

RUN adduser --disabled-password --gecos "" $MY_USER && echo "$MY_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $MY_USER

ADD templates/nginx/init.sh /etc/init.d/nginx

# Add all base dependencies
RUN sudo apt-get update -y \
  && sudo apt-get install -y build-essential checkinstall language-pack-en-base vim curl tmux wget unzip libnotify-dev imagemagick libmagickwand-dev libfuse-dev libcurl4-openssl-dev mime-support automake libtool python-docutils libreadline-dev libxslt1-dev libgd2-xpm-dev libgeoip-dev libgoogle-perftools-dev libperl-dev pkg-config libssl-dev git-core subversion php5-redis man php5-cli imagemagick php5-imagick phantomjs libgmp-dev zlib1g-dev libxslt-dev libxml2-dev libpcre3 libpcre3-dev freetds-dev openjdk-7-jdk software-properties-common \
  && sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db \
  && sudo apt-get -y update \
  && sudo apt-get -y install php5-mysql libsqlite3-dev php5 php5-dev php5-curl php-pear php5-fpm php5-gd \
  && /bin/bash -l -c "sudo wget https://github.com/phpredis/phpredis/archive/$PHPREDIS_VERSION.zip && sudo unzip $PHPREDIS_VERSION.zip && cd phpredis-$PHPREDIS_VERSION && sudo phpize && sudo ./configure && sudo make && sudo make install" \
  && /bin/bash -l -c "sudo mkdir -p /etc/ngx_pagespeed; cd /etc/ngx_pagespeed; sudo wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}.zip -O /etc/ngx_pagespeed/release-${NPS_VERSION}.zip; sudo unzip release-${NPS_VERSION}.zip -d /etc/ngx_pagespeed; cd /etc/ngx_pagespeed/ngx_pagespeed-release-${NPS_VERSION}/; sudo wget https://dl.google.com/dl/page-speed/psol/${PSOL_VERSION}.tar.gz -O /etc/ngx_pagespeed/ngx_pagespeed-release-${NPS_VERSION}/${PSOL_VERSION}.tar.gz; sudo tar -xzvf /etc/ngx_pagespeed/ngx_pagespeed-release-${NPS_VERSION}/${PSOL_VERSION}.tar.gz" \
  && /bin/bash -l -c "cd ~/ && sudo wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && sudo tar xzf nginx-${NGINX_VERSION}.tar.gz && cd nginx-${NGINX_VERSION} && sudo ./configure --prefix=${NGINX_PATH_PREFIX} --add-module=/etc/ngx_pagespeed/ngx_pagespeed-release-${NPS_VERSION} ${PS_NGX_EXTRA_FLAGS} ${NGINX_FLAGS} && sudo make && sudo make install" \
  && sudo rm $NGINX_PATH_PREFIX/conf/nginx.conf && cd $NGINX_PATH_PREFIX/conf/ \
  && sudo rm -rf /home/$MY_USER/nginx-${NGINX_VERSION}* \
  && sudo mkdir -p $NGINX_USER_CONF_PATH/configs $NGINX_USER_CONF_PATH/enabled $NGINX_USER_CONF_PATH $NGINX_USER_LOG_PATH \
  && /bin/bash -l -c "sudo chmod +x /etc/init.d/nginx && sudo update-rc.d nginx defaults"

ADD templates/wp-config.php ${USER_TEMPLATES_PATH}/wp-config.php
ADD templates/nginx/conf/*.conf ${USER_TEMPLATES_PATH}/conf/
ADD templates/nginx/enabled/*.conf ${USER_TEMPLATES_PATH}/enabled/
ADD templates/nginx/configs/*.conf ${USER_TEMPLATES_PATH}/configs/

WORKDIR /usr/local

RUN /bin/bash -l -c "sudo wget http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -O /usr/local/ioncube_loaders_lin_x86-64.tar.gz" \
  && sudo tar xzf /usr/local/ioncube_loaders_lin_x86-64.tar.gz && sudo rm -f ioncube_loaders_lin_x86-64.tar.gz \
  && zend_ext="\n\nzend_extension=/usr/local/ioncube/ioncube_loader_lin_5.5.so" \
  && sudo echo -e "$(cat $PHP_FPM_INI)$zend_ext" > ~/php.ini && sudo mv ~/php.ini $PHP_FPM_INI \
  && sudo sed -i s'/variables_order = "GPCS"/variables_order = "EGPCS"/' $PHP_FPM_INI \
  && sudo sed -i s'/memory_limit = 128M/memory_limit = 3000M/' $PHP_FPM_INI \
  && sudo sed -i s'/upload_max_filesize = 2M/upload_max_filesize = 1000M/' $PHP_FPM_INI \
  && sudo sed -i s'/post_max_size = 8M/post_max_size = 2000M/' $PHP_FPM_INI \
  && sudo sed -i s'/max_execution_time = 30/max_execution_time = 10000/' $PHP_FPM_INI \
  && exp="\n\nenv[NUT_API] = '$NUT_API_URL'"; sudo echo -e "$(cat $PHP_FPM_CONF)$exp" > ~/php-fpm.conf; sudo mv ~/php-fpm.conf $PHP_FPM_CONF \
  && sudo sed -i s'/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/' $PHP_FPM_POOL_CONF \
  && sudo sed -i s'/;request_terminate_timeout = 0/request_terminate_timeout = 500/' $PHP_FPM_POOL_CONF \
  && sudo sed -i s"/user = $WEB_USER/user = $NGINX_USER/" $PHP_FPM_POOL_CONF \
  && sudo sed -i s"/group = $WEB_USER/group = $NGINX_USER/" $PHP_FPM_POOL_CONF \
  && sudo sed -i s"/listen.owner = $WEB_USER/listen.owner = $NGINX_USER/" $PHP_FPM_POOL_CONF \
  && sudo sed -i s"/listen.group = $WEB_USER/listen.group = $NGINX_USER/" $PHP_FPM_POOL_CONF \
  && sudo echo "Europe/London" | sudo tee /etc/timezone && sudo dpkg-reconfigure --frontend $DEBIAN_FRONTEND tzdata

ADD templates/entrypoint.sh /etc/entrypoint.sh
RUN sudo chmod +x /etc/entrypoint.sh

WORKDIR $APP_HOME

EXPOSE 80
EXPOSE 5119

# Setup the entrypoint
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["/etc/entrypoint.sh"]
