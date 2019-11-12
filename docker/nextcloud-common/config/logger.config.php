<?php
	# Don't write logs to file shares; output the data to ephemeral storage
	# that gets echoed out to the Pod log.
	$CONFIG = array(
		'logfile' => '/var/log/nextcloud.log',
		'loglevel' => 1,
	);
