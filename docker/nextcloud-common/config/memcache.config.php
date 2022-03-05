<?php
$redis_hostname = getenv('REDIS_HOST');
$redis_port = getenv('REDIS_PORT');
$redis_key = getenv('REDIS_KEY');

if ($redis_port === FALSE) {
	$redis_port = 6379;
}

if ($redis_hostname !== FALSE) {
	$CONFIG = array(
		'memcache.distributed' => '\OC\Memcache\Redis',
		'memcache.locking' => '\OC\Memcache\Redis',
		'redis' => array(
			'host' => $redis_hostname,
			'port' => $redis_port,
			'timeout' => 1.5,
		),
	);

	if ($redis_key !== FALSE) {
		$CONFIG['redis']['password'] = $redis_key;
	}
}
