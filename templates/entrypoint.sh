#!/bin/bash

set -e
set -x

export WP_HOST_IP=`awk 'NR==1 {print $1}' /etc/hosts`

templates_path="/home/$MY_USER/templates";
obj_file_path="$WP_HOME/wp-content/object-cache.php";
wp_redis_obj_file_path="$WP_HOME/wp-content/plugins/wp-redis/object-cache.php";

sudo cp $templates_path/wp-config.php $WP_HOME/wp-config.php;
sudo cp $templates_path/default $NGINX_PATH_PREFIX/conf/$MY_USER/default;
sudo cp $templates_path/port_80 $NGINX_PATH_PREFIX/sites-available/port_80;
sudo cp $templates_path/port_5118 $NGINX_PATH_PREFIX/sites-available/port_5118;
sudo cp $templates_path/nginx.conf $NGINX_PATH_PREFIX/conf/nginx.conf;

if [[ ! -f $wp_redis_obj_file_path ]];
then
  sudo wget https://github.com/globalfoodbook/wp-redis/archive/v$WP_REDIS_VERSION.zip -O $templates_path/v$WP_REDIS_VERSION.zip;
  sudo unzip -j $templates_path/v$WP_REDIS_VERSION.zip -d $WP_HOME/wp-content/plugins/wp-redis;
fi

if [[ -L $obj_file_path || -f $obj_file_path ]]; # if object-cache symlink or file exists.. for symlink check this you can also use [[ -h $obj_file_path ]];
then
  sudo rm $obj_file_path;
fi
sudo ln -s $wp_redis_obj_file_path $obj_file_path > /dev/null 2>&1 &

echo -e WP Redis Setup is completed;

for name in MARIADB_ENV_MARIADB_DATABASE MARIADB_ENV_MARIADB_USER MARIADB_ENV_MARIADB_PASSWORD MARIADB_PORT_3306_TCP_ADDR MARIADB_PORT_3306_TCP_PORT AWS_ACCESS_KEY AWS_SECRET_ACCESS_KEY NGINX_USER NGINX_PATH_PREFIX SERVER_URLS MY_USER REDIS_PORT_6379_TCP_ADDR REDIS_PORT_6379_TCP_PORT WP_HOST_IP
do
    eval value=\$$name;
    sudo sed -i "s|\${${name}}|${value}|g" $WP_HOME/wp-config.php;
    sudo sed -i "s|\${${name}}|${value}|g" $NGINX_PATH_PREFIX/conf/nginx.conf;
    sudo sed -i "s|\${${name}}|${value}|g" $NGINX_PATH_PREFIX/conf/$MY_USER/default;
    sudo sed -i "s|\${${name}}|${value}|g" $NGINX_PATH_PREFIX/sites-available/port_80;
    sudo sed -i "s|\${${name}}|${value}|g" $NGINX_PATH_PREFIX/sites-available/port_5118;
done

echo -e Environment variables setup completed;

if [[ $NLS_PORT_80_TCP_ADDR ]]; then
  sudo sed -ie s"/^env\[NUT_API].*'$/env[NUT_API] = 'http:\/\/$NLS_PORT_80_TCP_ADDR\/v1\/nutrition\/facts?ingredients='/g" /etc/php5/fpm/php-fpm.conf
fi

sudo chown -R $NGINX_USER:$NGINX_USER $WP_HOME > /dev/null 2>&1 &
sudo find $WP_HOME -type d -exec chmod 755 {} \; > /dev/null 2>&1 &
sudo find $WP_HOME -type f -exec chmod 644 {} \; > /dev/null 2>&1 &

echo -e Permissions setup completed;

sudo service php5-fpm start
sudo service nginx start > /dev/null 2>&1 &

echo -e FPM and Ngnix start up is complete;

sudo touch $NGINX_PATH_PREFIX/logs/$MY_USER/access.log $NGINX_PATH_PREFIX/logs/$MY_USER/error.log
sudo tail -F $NGINX_PATH_PREFIX/logs/$MY_USER/access.log $NGINX_PATH_PREFIX/logs/$MY_USER/error.log
