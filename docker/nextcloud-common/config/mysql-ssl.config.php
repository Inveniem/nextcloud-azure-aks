<?php
/**
 * The name of the combined CA file that gets created during the Docker build.
 *
 * The CA file contains certificates for both Baltimore Cyber Trust and
 * Digi Cert Global Root (both regular and G2), per the instructions from this
 * article:
 * https://learn.microsoft.com/en-us/azure/mariadb/concepts-certificate-rotation
 */
const AZURE_CA_PEM_FILE = 'azure_ca.pem';

$config_folder = dirname(__FILE__);
$ca_file_path  = sprintf('%s/%s', $config_folder, AZURE_CA_PEM_FILE);

if (is_readable($ca_file_path)) {
  # Ensure that the root certificate authority certificates for Azure from the
  # Docker image are used to verify the SSL certificate chain during connection.
  $CONFIG = array(
    'dbdriveroptions' => array(
      PDO::MYSQL_ATTR_SSL_CA => $ca_file_path,
    ),
  );
}
else {
  // Should not happen unless config is read-only and the CA file is missing
  // from the volume.
  throw new InvalidArgumentException(
    'The Azure CA file is missing (is config read-only when it should not be?): ' . $ca_file_path
  );
}
