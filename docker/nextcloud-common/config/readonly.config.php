<?php
/**
 * @file
 * Force Nextcloud to run with a read-only config whenever the environment
 * variable is `true` or the config folder is mounted read-only.
 */
$read_only_str = getenv('NEXTCLOUD_CONFIG_READ_ONLY');

$is_read_only =
	!empty('NEXTCLOUD_CONFIG_READ_ONLY')
	&& strtolower($read_only_str) === 'true';

// If our own config file isn't writable, we know we're running in a read-only
// FS.
if (!is_writable(__FILE__)) {
	$is_read_only = TRUE;
}

$CONFIG = array(
	'config_is_read_only' => $is_read_only,
);
