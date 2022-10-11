<?php
# Limit IOPS and CPU exhaustion from large preview images (mainly TIFFs).
$CONFIG = array(
	'preview_max_filesize_image' => 50,
	'enable_previews' => true,
);
