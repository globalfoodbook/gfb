# Start with a base Ubuntu 14:04 image
FROM ubuntu:trusty

MAINTAINER Ikenna N. Okpala <me@ikennaokpala.com>

# Set up user environment

# Two users are defined one created by nginx and the other the host. This is for security reason www-data is configure accordingly with login disabled:
# sudo adduser --system --no-create-home --user-group --disabled-login --disabled-password www-data
#sudo adduser --system --no-create-home --user-group -s /sbin/nologin www-data

ENV MY_USER gfb
ENV NGINX_USER www-data
ENV NGINX_PATH_PREFIX /etc/nginx
ENV DEBIAN_FRONTEND noninteractive

ENV SERVER_URLS globalfoodbook.com www.globalfoodbook.com globalfoodbook.net www.globalfoodbook.net globalfoodbook.org www.globalfoodbook.org globalfoodbook.co.uk www.globalfoodbook.co.uk

ENV HOME /home/$MY_USER
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.en
ENV LC_ALL en_US.UTF-8

ENV NGINX_VERSION 1.9.10
ENV PSOL_VERSION 1.10.33.7
ENV NPS_VERSION $PSOL_VERSION-beta
ENV PHPREDIS_VERSION 2.2.7

ENV NGINX_FLAGS --with-file-aio --with-ipv6 --with-http_ssl_module  --with-http_realip_module --with-http_addition_module --with-http_xslt_module --with-http_image_filter_module --with-http_geoip_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_stub_status_module --with-http_perl_module --with-mail --with-mail_ssl_module --with-pcre --with-google_perftools_module --with-debug
ENV PS_NGX_EXTRA_FLAGS --with-cc=/usr/bin/gcc --with-ld-opt=-static-libstdc++

RUN adduser --disabled-password --gecos "" $MY_USER && echo "$MY_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $MY_USER

# Add all base dependencies
RUN sudo apt-get update -y

RUN sudo apt-get install -y build-essential checkinstall
RUN sudo apt-get install -y language-pack-en-base
RUN sudo apt-get install -y vim curl tmux wget unzip
RUN sudo apt-get install -y libnotify-dev imagemagick libmagickwand-dev
RUN sudo apt-get install -y libfuse-dev libcurl4-openssl-dev mime-support automake libtool python-docutils libreadline-dev
RUN sudo apt-get install -y libxslt1-dev libgd2-xpm-dev libgeoip-dev libgoogle-perftools-dev libperl-dev
RUN sudo apt-get install -y pkg-config libssl-dev
RUN sudo apt-get install -y git-core php5-redis
RUN sudo apt-get install -y man
RUN sudo apt-get install -y phantomjs
RUN sudo apt-get install -y libgmp-dev
RUN sudo apt-get install -y zlib1g-dev
RUN sudo apt-get install -y libxslt-dev
RUN sudo apt-get install -y libxml2-dev
RUN sudo apt-get install -y libpcre3 libpcre3-dev
RUN sudo apt-get install -y freetds-dev
RUN sudo apt-get install -y openjdk-7-jdk
RUN sudo apt-get install -y software-properties-common
RUN sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db

RUN sudo apt-get -y update
RUN sudo apt-get -y install php5-mysql libsqlite3-dev php5 php5-dev php5-curl php-pear php5-fpm php5-gd

RUN echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' | sudo tee /etc/apt/sources.list.d/newrelic.list
RUN /bin/bash -l -c "wget -O- https://download.newrelic.com/548C16BF.gpg | sudo apt-key add - "
RUN sudo apt-get update -y
RUN sudo apt-get install -y newrelic-php5
RUN sudo newrelic-install install

RUN /bin/bash -l -c "sudo wget https://github.com/phpredis/phpredis/archive/$PHPREDIS_VERSION.zip && sudo unzip $PHPREDIS_VERSION.zip && cd phpredis-$PHPREDIS_VERSION && sudo phpize && sudo ./configure && sudo make && sudo make install"

RUN /bin/bash -l -c "sudo mkdir -p /etc/ngx_pagespeed; cd /etc/ngx_pagespeed; sudo wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}.zip -O /etc/ngx_pagespeed/release-${NPS_VERSION}.zip; sudo unzip release-${NPS_VERSION}.zip -d /etc/ngx_pagespeed; cd /etc/ngx_pagespeed/ngx_pagespeed-release-${NPS_VERSION}/; sudo wget https://dl.google.com/dl/page-speed/psol/${PSOL_VERSION}.tar.gz -O /etc/ngx_pagespeed/ngx_pagespeed-release-${NPS_VERSION}/${PSOL_VERSION}.tar.gz; sudo tar -xzvf /etc/ngx_pagespeed/ngx_pagespeed-release-${NPS_VERSION}/${PSOL_VERSION}.tar.gz"
RUN /bin/bash -l -c "cd ~/ && sudo wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && sudo tar xzf nginx-${NGINX_VERSION}.tar.gz && cd nginx-${NGINX_VERSION} && sudo ./configure --prefix=${NGINX_PATH_PREFIX} --add-module=/etc/ngx_pagespeed/ngx_pagespeed-release-${NPS_VERSION} ${PS_NGX_EXTRA_FLAGS} ${NGINX_FLAGS} && sudo make && sudo make install"

RUN sudo mkdir -p $NGINX_PATH_PREFIX/sites-available/
RUN sudo mkdir -p $NGINX_PATH_PREFIX/sites-enabled/
RUN sudo mkdir -p $NGINX_PATH_PREFIX/logs/$MY_USER/
RUN sudo mkdir -p $HOME/templates/

ADD templates/nginx/nginx_init.sh /etc/init.d/nginx
RUN /bin/bash -l -c "sudo chmod +x /etc/init.d/nginx && sudo update-rc.d nginx defaults"

ADD templates/wp-config.php $HOME/templates/wp-config.php

ADD templates/nginx/default $NGINX_PATH_PREFIX/sites-available/default
ADD templates/nginx/default $HOME/templates/default
ADD templates/nginx/nginx.conf $NGINX_PATH_PREFIX/conf/nginx.conf
ADD templates/nginx/nginx.conf $HOME/templates/nginx.conf
ADD templates/nginx/port_80 $NGINX_PATH_PREFIX/sites-available/port_80
ADD templates/nginx/port_80 $HOME/templates/port_80
ADD templates/nginx/port_5118 $NGINX_PATH_PREFIX/sites-available/port_5118
ADD templates/nginx/port_5118 $HOME/templates/port_5118

ADD templates/nginx/w3tc.conf $NGINX_PATH_PREFIX/sites-available/w3tc.conf
ADD templates/nginx/ngx_page_speed_x.conf $NGINX_PATH_PREFIX/sites-available/ngx_page_speed_x.conf

RUN sudo ln -s $NGINX_PATH_PREFIX/sites-available/port_80 $NGINX_PATH_PREFIX/sites-enabled/port_80
RUN sudo ln -s $NGINX_PATH_PREFIX/sites-available/port_5118 $NGINX_PATH_PREFIX/sites-enabled/port_5118
RUN sudo cp $NGINX_PATH_PREFIX/conf/nginx.conf $NGINX_PATH_PREFIX/conf/nginx.conf.default
RUN sudo rm $NGINX_PATH_PREFIX/conf/nginx.conf && cd $NGINX_PATH_PREFIX/conf/
RUN sudo rm -rf /home/$MY_USER/nginx-${NGINX_VERSION}*

RUN cd /usr/local
RUN /bin/bash -l -c "sudo wget http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -O /usr/local/ioncube_loaders_lin_x86-64.tar.gz"
RUN sudo tar xzf /usr/local/ioncube_loaders_lin_x86-64.tar.gz && sudo rm -f ioncube_loaders_lin_x86-64.tar.gz

RUN zend_ext="\n\nzend_extension=/usr/local/ioncube/ioncube_loader_lin_5.5.so"; sudo echo -e "$(cat /etc/php5/fpm/php.ini)$zend_ext" > ~/php.ini; sudo mv ~/php.ini /etc/php5/fpm/php.ini
RUN sudo sed -i s'/variables_order = "GPCS"/variables_order = "EGPCS"/' /etc/php5/fpm/php.ini
RUN sudo sed -i s'/upload_max_filesize = 2M/upload_max_filesize = 200M/' /etc/php5/fpm/php.ini
RUN sudo sed -i s'/post_max_size = 8M/post_max_size = 250M/' /etc/php5/fpm/php.ini
RUN sudo sed -i s'/max_execution_time = 30/max_execution_time = 10000/' /etc/php5/fpm/php.ini

RUN exp="\nenv[NUT_API] = 'http://10.51.18.2/v1/nutrition/facts?ingredients='"; sudo echo -e "$(cat /etc/php5/fpm/php-fpm.conf)$exp" > ~/php-fpm.conf; sudo mv ~/php-fpm.conf /etc/php5/fpm/php-fpm.conf
RUN sudo sed -i s'/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/' /etc/php5/fpm/pool.d/www.conf

RUN sudo mkdir -p $NGINX_PATH_PREFIX/logs/$MY_USER

RUN sudo echo "Europe/London" | sudo tee /etc/timezone && sudo dpkg-reconfigure --frontend noninteractive tzdata
RUN sudo apt-get -y install zsh
RUN if [ ! -f /home/$MY_USER/.oh-my-zsh/ ]; then sudo -u $MY_USER -H git clone git://github.com/robbyrussell/oh-my-zsh.git /home/$MY_USER/.oh-my-zsh;fi
RUN sudo -u $MY_USER -H cp /home/$MY_USER/.oh-my-zsh/templates/zshrc.zsh-template /home/$MY_USER/.zshrc
RUN sudo chsh -s $(which zsh) $MY_USER && zsh && sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="ys"/g' /home/$MY_USER/.zshrc


ADD templates/entrypoint.sh /etc/entrypoint.sh
RUN sudo chmod +x /etc/entrypoint.sh

EXPOSE 80
EXPOSE 443
EXPOSE 5118

# Setup the entrypoint
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["/etc/entrypoint.sh"]
