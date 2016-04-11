#!/bin/bash

set -e

export WP_HOST_IP=`awk 'NR==1 {print $1}' /etc/hosts`

sudo cp /home/$MY_USER/wp-config.php /home/$MY_USER/app/wp/wp-config.php;
sudo cp /home/$MY_USER/index-wp-redis.php /home/$MY_USER/app/wp/index-wp-redis.php;
sudo cp /home/$MY_USER/index.php /home/$MY_USER/app/wp/index.php;
sudo cp /home/$MY_USER/default $NGINX_PATH_PREFIX/sites-available/default;
sudo cp /home/$MY_USER/port_80 $NGINX_PATH_PREFIX/sites-available/port_80;
sudo cp /home/$MY_USER/port_5118 $NGINX_PATH_PREFIX/sites-available/port_5118;
sudo cp /home/$MY_USER/nginx.conf $NGINX_PATH_PREFIX/conf/nginx.conf;

for name in MYSQL_ENV_MYSQL_DATABASE MYSQL_ENV_MYSQL_USER MYSQL_ENV_MYSQL_PASSWORD MYSQL_PORT_3306_TCP_ADDR MYSQL_PORT_3306_TCP_PORT AWS_ACCESS_KEY AWS_SECRET_ACCESS_KEY
do
    eval value=\$$name;
    sudo sed -i "s|\${${name}}|${value}|g" /home/$MY_USER/app/wp/wp-config.php;
done

for name in REDIS_PORT_6379_TCP_ADDR WP_HOST_IP
do
    eval value=\$$name;
    sudo sed -i "s|\${${name}}|${value}|g" /home/$MY_USER/app/wp/index-wp-redis.php;
done

for name in NGINX_USER NGINX_PATH_PREFIX NGINX_USER SERVER_URLS MY_USER
do
    eval value=\$$name;
    sudo sed -i "s|\${${name}}|${value}|g" $NGINX_PATH_PREFIX/conf/nginx.conf;
    sudo sed -i "s|\${${name}}|${value}|g" $NGINX_PATH_PREFIX/sites-available/default;
    sudo sed -i "s|\${${name}}|${value}|g" $NGINX_PATH_PREFIX/sites-available/port_80;
    sudo sed -i "s|\${${name}}|${value}|g" $NGINX_PATH_PREFIX/sites-available/port_5118;
done

sudo chown $NGINX_USER:$NGINX_USER -R /home/$MY_USER/app && sudo find /home/$MY_USER/app -type d -exec chmod 755 {} \; && sudo find /home/$MY_USER/app -type f -exec chmod 644 {} \;

sudo service php5-fpm start
sudo service nginx start

touch $NGINX_PATH_PREFIX/logs/$MY_USER/access.log $NGINX_PATH_PREFIX/logs/$MY_USER/error.log
tail -F $NGINX_PATH_PREFIX/logs/$MY_USER/access.log $NGINX_PATH_PREFIX/logs/$MY_USER/error.log
