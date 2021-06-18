<?php
	$file_locking_str = getenv('NEXTCLOUD_FILE_LOCKING_ENABLED');

	$file_locking_bool =
		!empty('NEXTCLOUD_FILE_LOCKING_ENABLED')
		&& strtolower($file_locking_str) === 'true';

	$CONFIG = array(
		'filelocking.enabled' => $file_locking_bool,
	);
