<?php
	# Support connecting to Azure MySQL over SSL
	$CONFIG = array(
		'dbdriveroptions' => array(
			PDO::MYSQL_ATTR_SSL_CA => '/etc/ssl/certs/Baltimore_CyberTrust_Root.pem',
		),
	);
