#!/bin/bash

set -e
set -x

export WP_HOST_IP=`awk 'NR==1 {print $1}' /etc/hosts`

sudo cp ${USER_TEMPLATES_PATH}/wp-config.php ${WP_HOME}//wp-config.php;
sudo cp ${USER_TEMPLATES_PATH}/configs/*.conf ${NGINX_USER_CONF_PATH}/configs;
sudo cp ${USER_TEMPLATES_PATH}/enabled/*.conf ${NGINX_USER_CONF_PATH}/enabled;
sudo cp ${USER_TEMPLATES_PATH}/conf/*.conf ${NGINX_CONF_PATH};
sudo cp ${USER_TEMPLATES_PATH}/lua/*.conf ${NGINX_USER_CONF_PATH}/lua;

if [[ ! -f ${WP_REDIS_OBJ_FILE_PATH} ]];
then
  sudo wget https://github.com/globalfoodbook/wp-redis/archive/v${WP_REDIS_VERSION}.zip -O ${USER_TEMPLATES_PATH}/v${WP_REDIS_VERSION}.zip;
  sudo unzip -j ${USER_TEMPLATES_PATH}/v${WP_REDIS_VERSION}.zip -d $WP_HOME/wp-content/plugins/wp-redis;
fi

if [[ -L ${OBJ_FILE_PATH} || -f ${OBJ_FILE_PATH} ]]; # if object-cache symlink or file exists.. for symlink check this you can also use [[ -h ${OBJ_FILE_PATH} ]];
then
  sudo rm ${OBJ_FILE_PATH};
fi
sudo ln -s ${WP_REDIS_OBJ_FILE_PATH} ${OBJ_FILE_PATH} > /dev/null 2>&1 &

echo -e WP Redis Setup is completed;

for name in MARIADB_ENV_MARIADB_DATABASE MARIADB_ENV_MARIADB_USER MARIADB_ENV_MARIADB_PASSWORD MARIADB_PORT_3306_TCP_ADDR MARIADB_PORT_3306_TCP_PORT AWS_ACCESS_KEY AWS_SECRET_ACCESS_KEY MY_USER REDIS_PORT_6379_TCP_ADDR REDIS_PORT_6379_TCP_PORT WP_HOST_IP GCS_MEDIA_BUCKET GCS_MEDIA_MODE GCS_MEDIA_KEY_FILE_PATH GCS_MEDIA_SERVICE_ACCOUNT NGINX_PATH_PREFIX NGINX_LOG_PATH NGINX_USER_LOG_PATH NGINX_USER PHP_FPM_IP_PORT SERVER_URLS WP_HOME NGINX_USER_CONF_PATH NGINX_CONF_PATH LUAJIT_PACKAGE_PATH
do
    eval value=\$$name;
    sudo sed -i "s|\${${name}}|${value}|g" ${WP_HOME}/wp-config.php;
    sudo sed -i "s|\${${name}}|${value}|g" ${NGINX_CONF_PATH}/nginx.conf;
    sudo sed -i "s|\${${name}}|${value}|g" ${NGINX_USER_CONF_PATH}/configs/default.conf;
    sudo sed -i "s|\${${name}}|${value}|g" ${NGINX_USER_CONF_PATH}/lua/default.conf;
    sudo sed -i "s|\${${name}}|${value}|g" ${NGINX_USER_CONF_PATH}/enabled/80.conf;
done

echo -e Environment variables setup completed;

if [[ $NLS_PORT_80_TCP_ADDR ]]; then
  sudo sed -ie s"/^env\[NUT_API].*'$/env[NUT_API] = 'http:\/\/$NLS_PORT_80_TCP_ADDR\/v1\/nutrition\/facts?ingredients='/g" ${PHP_FPM_CONF}
fi

sudo chown -R ${NGINX_USER}:${NGINX_USER} ${WP_HOME} > /dev/null 2>&1 &
sudo find ${WP_HOME} -type d -exec chmod 755 {} \; > /dev/null 2>&1 &
sudo find ${WP_HOME} -type f -exec chmod 644 {} \; > /dev/null 2>&1 &

echo -e Permissions setup completed;

# sudo service php5-fpm start
sudo /usr/sbin/php5-fpm --nodaemonize --fpm-config ${PHP_FPM_CONF} &
sudo service nginx start > /dev/null 2>&1 &

echo -e FPM start up is complete;

sudo touch ${NGINX_USER_LOG_PATH}/access.log ${NGINX_USER_LOG_PATH}/error.log ${NGINX_LOG_PATH}/access.log ${NGINX_LOG_PATH}/error.log
sudo tail -F ${NGINX_USER_LOG_PATH}/access.log ${NGINX_USER_LOG_PATH}/error.log ${NGINX_LOG_PATH}/access.log ${NGINX_LOG_PATH}/error.log
