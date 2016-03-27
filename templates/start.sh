#!/bin/bash
export WP_HOST_IP=`awk 'NR==1 {print $1}' /etc/hosts`

cp /home/gfb/wp-config.php /home/gfb/app/wp/wp-config.php
cp /home/gfb/index-wp-redis.php /home/gfb/app/wp/index-wp-redis.php
cp /home/gfb/index.php /home/gfb/app/wp/index.php

for name in MYSQL_ENV_MYSQL_DATABASE MYSQL_ENV_MYSQL_USER MYSQL_ENV_MYSQL_PASSWORD MYSQL_PORT_3306_TCP_ADDR MYSQL_PORT_3306_TCP_PORT
do
    eval value=\$$name
    sed -i "s|\${${name}}|${value}|g" /home/gfb/app/wp/wp-config.php
done

for name in REDIS_PORT_6379_TCP_ADDR WP_HOST_IP
do
    eval value=\$$name
    sed -i "s|\${${name}}|${value}|g" /home/gfb/app/wp/index-wp-redis.php
done

sudo chown www-data:www-data  -R /home/gfb/app && sudo find /home/gfb/app -type d -exec chmod 755 {} \; && sudo find /home/gfb/app -type f -exec chmod 644 {} \;

sudo service php5-fpm start
sudo service nginx start

touch /etc/nginx/logs/gfb/access.log /etc/nginx/logs/gfb/error.log
tail -F /etc/nginx/logs/gfb/access.log /etc/nginx/logs/gfb/error.log
