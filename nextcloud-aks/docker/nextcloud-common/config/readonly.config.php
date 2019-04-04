<?php
	$read_only_str = getenv('NEXTCLOUD_CONFIG_READ_ONLY');

	$read_only_bool =
		!empty('NEXTCLOUD_CONFIG_READ_ONLY')
		&& strtolower($read_only_str) === 'true';

	# Allow config to made read-only after setup.
	$CONFIG = array(
		'config_is_read_only' => $read_only_bool,
	);
