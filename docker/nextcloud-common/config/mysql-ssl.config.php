<?php
	$all_ssl_ca_locations = [
		# Location of Azure Trusted CA on Alpine Linux
		'/etc/ssl/certs/Baltimore_CyberTrust_Root.pem',

		# Location of Azure Trusted CA on Ubuntu Linux
		'/etc/ssl/certs/ca-cert-Baltimore_CyberTrust_Root.pem',
	];

	foreach ($all_ssl_ca_locations as $location) {
		if (is_file($location)) {
			$ssl_ca_location = $location;
			break;
		}
	}

	if (!empty($ssl_ca_location)) {
		# Support connecting to Azure MySQL over SSL
		$CONFIG = array(
			'dbdriveroptions' => array(
				PDO::MYSQL_ATTR_SSL_CA => $ssl_ca_location,
			),
		);
	}
