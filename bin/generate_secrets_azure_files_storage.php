#!/usr/bin/env php
<?php
/**
 * @file
 * Uses the Azure CLI to obtain the storage key for the storage accounts
 * described by JSON read from standard input, and then echoes the secret as a
 * Kubernetes deployment manifest.
 *
 * (A future version of this resource kit may wish to convert this into being a
 * generator, though that will need to handle authenticating with the Azure
 * CLI).
 *
 * @author Guy Elsmore-Paddock (guy@inveniem.com)
 * @copyright Copyright (c) 2022, Inveniem
 * @license GNU AGPL version 3 or any later version
 */
$storage_account_json            = file_get_contents('php://stdin');
$resource_group_storage_accounts = json_decode($storage_account_json);

if (empty($resource_group_storage_accounts)) {
  fwrite(
    STDERR,
    "Standard input must be a valid JSON payload containing storage account information.\n"
  );

  die(1);
}

$is_first = TRUE;

foreach ($resource_group_storage_accounts as $resource_group => $storage_accounts) {
  foreach ($storage_accounts as $storage_account => $secret_name) {
    $storage_key_command =
      sprintf(
        'az storage account keys list --resource-group "%s" --account-name "%s" --query "[0].value" -o tsv',
        $resource_group,
        $storage_account
      );

    $output      = [];
    $storage_key = exec($storage_key_command, $output);

    if (empty($storage_key)) {
      fwrite(STDERR, implode(PHP_EOL, $output));
      exit(2);
    }

    if ($is_first) {
      $is_first = FALSE;
    }
    else {
      echo "---\n";
    }
  ?>
kind: Secret
apiVersion: v1
metadata:
  name: "<?php echo $secret_name; ?>"
type: Opaque
stringData:
  azurestorageaccountname: <?php echo $storage_account . "\n"; ?>
  azurestorageaccountkey: <?php echo $storage_key . "\n"; ?>
<?php
  }
}
