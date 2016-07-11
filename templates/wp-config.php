<?php
/**
 * Custom WordPress configurations on "wp-config.php" file.
 *
 * This file has the following configurations: MySQL settings, Table Prefix, Secret Keys, WordPress Language, ABSPATH and more.
 * For more information visit {@link https://codex.wordpress.org/Editing_wp-config.php Editing wp-config.php} Codex page.
 * Created using {@link http://generatewp.com/wp-config/ wp-config.php File Generator} on GenerateWP.com.
 *
 * @package WordPress
 * @generator GenerateWP.com
 */

 /*
 You have three options to increase the execution time. Try editing one of the following:
 1. wp-config.php add:
 set_time_limit(60);
 above the That’s all, stop editing! Happy blogging. line
 2. htaccess file
 php_value max_execution_time 60
 3. php.ini file
 max_execution_time = 60 ;
 */

/** Enable W3 Total Cache */
define('WP_CACHE', true); // Added by W3 Total Cache

/** Enable W3 Total Cache Edge Mode */
define('W3TC_EDGE_MODE', true); // Added by W3 Total Cache

set_time_limit(6);

define('WP_SITEURL', 'http://' . $_SERVER['HTTP_HOST']);
define('WP_HOME', 'http://' . $_SERVER['HTTP_HOST']);

define("DB_NAME",     "${MARIADB_ENV_MARIADB_DATABASE}");
define("DB_USER",     "${MARIADB_ENV_MARIADB_USER}");
define("DB_PASSWORD", "${MARIADB_ENV_MARIADB_PASSWORD}");
define("DB_HOST",     "${MARIADB_PORT_3306_TCP_ADDR}");
define("DB_PORT",     "${MARIADB_PORT_3306_TCP_PORT}");
define("DB_CHARSET",  "utf8");

// AMAZON WEB SERVICE S3 SETTINGS
define("DBI_AWS_ACCESS_KEY_ID", "${AWS_ACCESS_KEY}");
define("DBI_AWS_SECRET_ACCESS_KEY", "${AWS_SECRET_ACCESS_KEY}");
define('WP_MEMORY_LIMIT', '3000M');

// GOOGLE CLOUD STORAGE SETTINGS
define("WP_STATELESS_MEDIA_BUCKET", "${GCS_MEDIA_BUCKET}");
define("WP_STATELESS_MEDIA_MODE", "${GCS_MEDIA_MODE}");
define("WP_STATELESS_MEDIA_KEY_FILE_PATH", "${GCS_MEDIA_KEY_FILE_PATH}");
define("WP_STATELESS_MEDIA_SERVICE_ACCOUNT", "${GCS_MEDIA_SERVICE_ACCOUNT}");

/* MySQL database table prefix. */
$table_prefix = "${MARIADB_ENV_MARIADB_DATABASE}_";

/* Authentication Unique Keys and Salts. */
/* https://api.wordpress.org/secret-key/1.1/salt/ */
define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');

error_reporting(~0);
ini_set('display_errors', 1);

/* WordPress Localized Language. */
define('WPLANG', '');

$redis_server = array(
  'host' => '${REDIS_PORT_6379_TCP_ADDR}',
  'port' => ${REDIS_PORT_6379_TCP_PORT},
  // 'auth' => '',
);


/* WordPress debug mode for developers. */
// define('WP_DEBUG',         true);
// define('WP_DEBUG_LOG',     true);
// define('WP_DEBUG_DISPLAY', false);
// define('SCRIPT_DEBUG',     true);
// define('SAVEQUERIES',      true);

/* That's all, stop editing! Happy blogging. */

/* Absolute path to the WordPress directory. */
if (!defined('ABSPATH'))
	define('ABSPATH', dirname(__FILE__) . '/');

/* Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');

define('FS_METHOD','direct');
