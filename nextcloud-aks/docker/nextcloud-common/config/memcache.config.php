<?php
$redis_hostname = getenv('REDIS_HOST');
$redis_port = getenv('REDIS_PORT');
$redis_key = getenv('REDIS_KEY');

if (($redis_hostname !== FALSE) && ($redis_port !== FALSE)
	&& ($redis_key !== FALSE)) {
	$CONFIG = array(
		'memcache.local' => '\OC\Memcache\Redis',
		'memcache.locking' => '\OC\Memcache\Redis',
		'redis' => array(
			'host' => $redis_hostname,
			'port' => $redis_port,
			'password' => $redis_key,
			'timeout' => 1.5,
		),
	);
} else {
	# Fallback to APCu if we have to.
	$CONFIG = array(
		'memcache.local' => '\OC\Memcache\APCu',
	);
}
