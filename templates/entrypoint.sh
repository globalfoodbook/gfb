#!/bin/bash

set -e

export WP_HOST_IP=`awk 'NR==1 {print $1}' /etc/hosts`

templates_path="/home/$MY_USER/templates";
obj_file_path="/home/$MY_USER/app/wp/wp-content/object-cache.php";
wp_redis_obj_file_path="/home/$MY_USER/app/wp/wp-content/plugins/wp-redis/object-cache.php";
NOW=$(date +"%Y-%m-%d-%H%M")

sudo cp $templates_path/wp-config.php /home/$MY_USER/app/wp/wp-config.php;
sudo cp $templates_path/index-wp-redis.php /home/$MY_USER/app/wp/index-wp-redis.php;
sudo cp $templates_path/index.php /home/$MY_USER/app/wp/index.php;
sudo cp $templates_path/default $NGINX_PATH_PREFIX/sites-available/default;
sudo cp $templates_path/port_80 $NGINX_PATH_PREFIX/sites-available/port_80;
sudo cp $templates_path/port_5118 $NGINX_PATH_PREFIX/sites-available/port_5118;
sudo cp $templates_path/nginx.conf $NGINX_PATH_PREFIX/conf/nginx.conf;

if [[ -L $obj_file_path ]]; # can also use [[ -h $obj_file_path ]];
then
  sudo rm $obj_file_path;
fi

if [[ ! -f $wp_redis_obj_file_path ]];
then
  sudo wget https://downloads.wordpress.org/plugin/wp-redis.0.4.0.zip -O $templates_path/wp-redis.0.4.0.zip;
  sudo unzip $templates_path/wp-redis.0.4.0.zip -d /home/$MY_USER/app/wp/wp-content/plugins/;
  sudo ln -s $wp_redis_obj_file_path $obj_file_path;
  echo -e WP Redis Setup is completed;
fi

for name in MYSQL_ENV_MYSQL_DATABASE MYSQL_ENV_MYSQL_USER MYSQL_ENV_MYSQL_PASSWORD MYSQL_PORT_3306_TCP_ADDR MYSQL_PORT_3306_TCP_PORT AWS_ACCESS_KEY AWS_SECRET_ACCESS_KEY NGINX_USER NGINX_PATH_PREFIX SERVER_URLS MY_USER REDIS_PORT_6379_TCP_ADDR REDIS_PORT_6379_TCP_PORT WP_HOST_IP
do
    eval value=\$$name;
    sudo sed -i "s|\${${name}}|${value}|g" /home/$MY_USER/app/wp/wp-config.php;
    # sudo sed -i "s|\${${name}}|${value}|g" /home/$MY_USER/app/wp/index-wp-redis.php;
    sudo sed -i "s|\${${name}}|${value}|g" $NGINX_PATH_PREFIX/conf/nginx.conf;
    sudo sed -i "s|\${${name}}|${value}|g" $NGINX_PATH_PREFIX/sites-available/default;
    sudo sed -i "s|\${${name}}|${value}|g" $NGINX_PATH_PREFIX/sites-available/port_80;
    sudo sed -i "s|\${${name}}|${value}|g" $NGINX_PATH_PREFIX/sites-available/port_5118;
done
echo -e Environment variables setup completed;

sudo chown -R $NGINX_USER:$NGINX_USER /home/$MY_USER/app > /dev/null 2>&1
sudo find /home/$MY_USER/app -type d -exec chmod 755 {} \; > /dev/null 2>&1
sudo find /home/$MY_USER/app -type f -exec chmod 644 {} \; > /dev/null 2>&1

echo -e Permissions setup completed;

sudo service php5-fpm start
sudo service nginx start > /dev/null 2>&1

echo -e FPM and Ngnix start up is complete;

sudo touch $NGINX_PATH_PREFIX/logs/$MY_USER/access.log $NGINX_PATH_PREFIX/logs/$MY_USER/error.log
sudo tail -F $NGINX_PATH_PREFIX/logs/$MY_USER/access.log $NGINX_PATH_PREFIX/logs/$MY_USER/error.log
