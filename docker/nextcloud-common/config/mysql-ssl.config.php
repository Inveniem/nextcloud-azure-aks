<?php
/**
 * The name of the combined CA file that gets created during the Docker build.
 *
 * The CA file contains certificates for both BaltimoreCyberTrustRoot and
 * DigiCertGlobalRootG2, per the instructions from this article:
 * https://learn.microsoft.com/en-us/azure/mariadb/concepts-certificate-rotation
 */
const AZURE_CA_PEM_FILE = 'azure_ca.pem';

$config_folder = dirname(__FILE__);

# Support connecting to Azure MySQL over SSL
$CONFIG = array(
	'dbdriveroptions' => array(
		PDO::MYSQL_ATTR_SSL_CA => sprintf('%s/%s', $config_folder, AZURE_CA_PEM_FILE),
	),
);
