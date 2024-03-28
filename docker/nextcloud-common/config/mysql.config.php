<?php
# Populate database connection info from environment.
$mysql_host     = getenv('MYSQL_HOST');
$mysql_port     = getenv('MYSQL_PORT') ?? 3306;
$mysql_database = getenv('MYSQL_DATABASE');
$mysql_user     = getenv('MYSQL_USER');
$mysql_password = getenv('MYSQL_PASSWORD');

if (!empty($mysql_host)) {
  $CONFIG = array(
    'dbtype'        => 'mysql',
    'dbname'        => $mysql_database,
    'dbhost'        => $mysql_host,
    'dbport'        => $mysql_port,
    'dbtableprefix' => '',
    'dbuser'        => $mysql_user,
    'dbpassword'    => $mysql_password,
  );
}
