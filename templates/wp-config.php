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

set_time_limit(6);

define('WP_SITEURL', 'http://' . $_SERVER['HTTP_HOST']);
define('WP_HOME', 'http://' . $_SERVER['HTTP_HOST']);

/* MySQL settings */
// define('DB_NAME',     'gfb');
// define('DB_USER',     'gfb');
// define('DB_PASSWORD', '');
// define('DB_HOST',     '10.51.18.12');
// define('DB_CHARSET',  'utf8');

define("DB_NAME",     "${MYSQL_ENV_MYSQL_DATABASE}");
define("DB_USER",     "${MYSQL_ENV_MYSQL_USER}");
define("DB_PASSWORD", "${MYSQL_ENV_MYSQL_PASSWORD}");
define("DB_HOST",     "${MYSQL_PORT_3306_TCP_ADDR}");
define("DB_PORT",     "${MYSQL_PORT_3306_TCP_PORT}");
define("DB_CHARSET",  "utf8");


/* MySQL database table prefix. */
$table_prefix = "${MYSQL_ENV_MYSQL_DATABASE}_";


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
