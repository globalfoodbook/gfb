# Start with a base Ubuntu 14:04 image
FROM ubuntu:trusty

MAINTAINER Ikenna N. Okpala <me@ikennaokpala.com>

# Set up user environment
ENV DEBIAN_FRONTEND noninteractive
RUN adduser --disabled-password --gecos "" gfb && echo "gfb ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# set HOME so 'npm install' and 'bower install' don't write to /
ENV HOME /home/gfb
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.en
ENV LC_ALL en_US.UTF-8
ENV NGINX_VERSION 1.9.10
ENV NPS_VERSION  1.10.33.7-beta
# ENV PS_NGX_EXTRA_FLAGS --with-cc=/usr/lib/gcc-mozilla/bin/gcc  --with-ld-opt=-static-libstdc++
ENV PS_NGX_EXTRA_FLAGS --with-cc=/usr/bin/gcc --with-ld-opt=-static-libstdc++

USER gfb
# RUN sudo locale-gen

# Add all base dependencies
RUN sudo apt-get update -y
# RUN sudo apt-get install -y build-essential checkinstall gcc-mozilla
RUN sudo apt-get install -y build-essential checkinstall
RUN sudo apt-get install -y language-pack-en-base
RUN sudo apt-get install -y vim curl tmux wget unzip
RUN sudo apt-get install -y libnotify-dev imagemagick libmagickwand-dev
RUN sudo apt-get install -y libfuse-dev libcurl4-openssl-dev mime-support automake libtool python-docutils libreadline-dev
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
# RUN sudo add-apt-repository 'deb http://mirrors.coreix.net/mariadb/repo/10.0/ubuntu trusty main'
RUN sudo apt-get -y update
RUN sudo apt-get -y install php5-mysql libsqlite3-dev php5 php5-dev php5-curl php-pear php5-fpm php5-gd

RUN echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' | sudo tee /etc/apt/sources.list.d/newrelic.list
RUN /bin/bash -l -c "wget -O- https://download.newrelic.com/548C16BF.gpg | sudo apt-key add - "
RUN sudo apt-get update -y
RUN sudo apt-get install -y newrelic-php5
RUN sudo newrelic-install install

RUN /bin/bash -l -c "sudo mkdir -p /etc/ngx_pagespeed; cd /etc/ngx_pagespeed; sudo wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}.zip -O /etc/ngx_pagespeed/release-${NPS_VERSION}.zip; sudo unzip release-${NPS_VERSION}.zip -d /etc/ngx_pagespeed; cd /etc/ngx_pagespeed/ngx_pagespeed-release-${NPS_VERSION}/; sudo wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz -O /etc/ngx_pagespeed/ngx_pagespeed-release-${NPS_VERSION}/${NPS_VERSION}.tar.gz; sudo tar -xzvf /etc/ngx_pagespeed/ngx_pagespeed-release-${NPS_VERSION}/${NPS_VERSION}.tar.gz"
RUN /bin/bash -l -c "cd ~/ && sudo wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && sudo tar xzf nginx-${NGINX_VERSION}.tar.gz && cd nginx-${NGINX_VERSION} && sudo ./configure --prefix=/etc/nginx --add-module=/etc/ngx_pagespeed/ngx_pagespeed-release-${NPS_VERSION} ${PS_NGX_EXTRA_FLAGS} && sudo make && sudo make install"
ADD templates/nginx/nginx_init.sh /etc/init.d/nginx
RUN /bin/bash -l -c "sudo chmod +x /etc/init.d/nginx && sudo update-rc.d nginx defaults"
RUN sudo mkdir -p /etc/nginx/sites-available/
RUN sudo mkdir -p /etc/nginx/sites-enabled/
RUN sudo mkdir -p /etc/nginx/logs/gfb/

ADD templates/index-wp-redis.php /home/gfb/index-wp-redis.php
ADD templates/index.php /home/gfb/index.php
ADD templates/wp-config.php /home/gfb/wp-config.php
ADD templates/nginx/default /etc/nginx/sites-available/default
ADD templates/nginx/port_80 /etc/nginx/sites-available/port_80
ADD templates/nginx/port_5118 /etc/nginx/sites-available/port_5118
ADD templates/nginx/w3tc.conf /etc/nginx/sites-available/w3tc.conf
ADD templates/nginx/ngx_page_speed_x.conf /etc/nginx/sites-available/ngx_page_speed_x.conf

RUN sudo ln -s /etc/nginx/sites-available/port_80 /etc/nginx/sites-enabled/port_80
RUN sudo ln -s /etc/nginx/sites-available/port_5118 /etc/nginx/sites-enabled/port_5118
RUN sudo cp /etc/nginx/conf/nginx.conf /etc/nginx/conf/nginx.conf.default
RUN sudo rm /etc/nginx/conf/nginx.conf && cd /etc/nginx/conf/
ADD templates/nginx/nginx.conf /etc/nginx/conf/nginx.conf
RUN sudo rm -rf /home/gfb/nginx-${NGINX_VERSION}*

RUN cd /usr/local
RUN /bin/bash -l -c "sudo wget http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -O /usr/local/ioncube_loaders_lin_x86-64.tar.gz"
RUN sudo tar xzf /usr/local/ioncube_loaders_lin_x86-64.tar.gz && sudo rm -f ioncube_loaders_lin_x86-64.tar.gz
RUN zend_ext="\n\nzend_extension=/usr/local/ioncube/ioncube_loader_lin_5.5.so"; sudo echo -e "$(cat /etc/php5/fpm/php.ini)$zend_ext" > ~/php.ini; sudo mv ~/php.ini /etc/php5/fpm/php.ini
RUN exp="\nenv[NUT_API] = 'http://10.51.18.2/v1/nutrition/facts?ingredients='"; sudo echo -e "$(cat /etc/php5/fpm/php-fpm.conf)$exp" > ~/php-fpm.conf; sudo mv ~/php-fpm.conf /etc/php5/fpm/php-fpm.conf
RUN sudo sed -i s'/variables_order = "GPCS"/variables_order = "EGPCS"/' /etc/php5/fpm/php.ini
RUN sudo sed -i s'/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/' /etc/php5/fpm/pool.d/www.conf
# RUN sudo mkdir -p /etc/nginx/logs/gfb && sudo rm -rf /gfb/logs && sudo ln -s /etc/nginx/logs/gfb /gfb/logs
RUN sudo mkdir -p /etc/nginx/logs/gfb

RUN sudo echo "Europe/London" | sudo tee /etc/timezone && sudo dpkg-reconfigure --frontend noninteractive tzdata
RUN sudo apt-get -y install zsh
RUN if [ ! -f /home/gfb/.oh-my-zsh/ ]; then sudo -u gfb -H git clone git://github.com/robbyrussell/oh-my-zsh.git /home/gfb/.oh-my-zsh;fi
RUN sudo -u gfb -H cp /home/gfb/.oh-my-zsh/templates/zshrc.zsh-template /home/gfb/.zshrc
RUN sudo chsh -s $(which zsh) gfb && zsh && sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="ys"/g' /home/gfb/.zshrc

# Add the application to the container (cwd)
# WORKDIR /gfb
# ADD ./ /gfb
# VOLUME ["/gfb"]

ADD templates/start.sh /etc/start.sh
RUN sudo chmod +x /etc/start.sh

# RUN ln -s /gfb /home/gfb/app
# RUN sudo chown www-data:www-data  -R /gfb && sudo find /gfb -type d -exec chmod 755 {} \; && sudo find /gfb -type f -exec chmod 644 {} \;

EXPOSE 80
EXPOSE 443
EXPOSE 5118

# Setup the entrypoint
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["/etc/start.sh"]
