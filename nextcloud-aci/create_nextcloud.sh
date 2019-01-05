#!/usr/bin/env bash

##
# This script attempts to deploy Nextcloud to an Azure Container Instance, with
# volumes stored on Azure Files.
#
# See README.md for more details.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019, Inveniem
# @license GNU AGPL version 3 or any later version
#

set -u
set -e

source 'config.env'

if [[ "${DROP_EXISTING}" -eq 1 ]]; then
    source 'drop_nextcloud.sh'
fi

echo "Creating resource group '${RESOURCE_GROUP}'..."
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}"
echo ""

# Premium Storage Preview
if [[ "${USE_PREMIUM_STORAGE}" -eq 1 ]]; then
    echo "Creating premium storage account '${STORAGE_ACCOUNT_NAME}'..."
    az storage account create \
      --resource-group "${RESOURCE_GROUP}" \
      --name "${STORAGE_ACCOUNT_NAME}" \
      --kind "FileStorage" \
      --sku "Premium_LRS" \
      --location "${LOCATION}"
else
    echo "Creating standard storage account '${STORAGE_ACCOUNT_NAME}'..."
    az storage account create \
      --resource-group "${RESOURCE_GROUP}" \
      --name "${STORAGE_ACCOUNT_NAME}" \
      --kind "StorageV2" \
      --sku "Standard_LRS" \
      --location "${LOCATION}"
fi
echo ""

export AZURE_STORAGE_CONNECTION_STRING=$( \
  az storage account show-connection-string \
    --name "${STORAGE_ACCOUNT_NAME}" \
    --query "connectionString" \
    --output=tsv
)

echo "Creating shares..."
az storage share create --name "${NEXTCLOUD_CONFIG_SHARE_NAME}"
az storage share create --name "${NEXTCLOUD_DATA_SHARE_NAME}"

az storage share create --name "${STORAGE_SHARE_CLIENT_1_NAME}"
az storage share create --name "${STORAGE_SHARE_CLIENT_2_NAME}"
az storage share create --name "${STORAGE_SHARE_CLIENT_3_NAME}"
echo ""

STORAGE_ACCOUNT_KEY=$( \
  az storage account keys list \
    --account-name "${STORAGE_ACCOUNT_NAME}" \
    --query "[0].value" \
    --output=tsv
)

echo "Creating container..."
cat << EOF > ./nextcloud.json
{
  "name": "${CONTAINER_GROUP_NAME}",
  "type": "Microsoft.ContainerInstance/containerGroups",
  "apiVersion": "2018-10-01",
  "location": "${LOCATION}",
  "tags": {
    "service": "nextcloud",
  },
  "properties": {
    "osType": "Linux",
    "restartPolicy": "Never",
    "imageRegistryCredentials": [
      {
        "server": "${REGISTRY_HOST}",
        "username": "${REGISTRY_USER}",
        "password": "${REGISTRY_PASSWORD}"
      }
    ],
    "containers": [
      {
        "name": "${CONTAINER_NAME}",
        "properties": {
          "image": "${REGISTRY_HOST}/${CONTAINER_IMAGE_NAME}",
          "ports": [
            {
              "protocol": "TCP",
              "port": "${CONTAINER_PORT}"
            }
          ],
          "environmentVariables": [
            {
              "name": "MYSQL_HOST",
              "value": "${MYSQL_HOST}"
            },
            {
              "name": "MYSQL_DATABASE",
              "value": "${MYSQL_DATABASE}"
            },
            {
              "name": "MYSQL_USER",
              "secureValue": "${MYSQL_USER}"
            },
            {
              "name": "MYSQL_PASSWORD",
              "secureValue": "${MYSQL_PASSWORD}"
            },
            {
              "name": "NEXTCLOUD_ADMIN_USER",
              "secureValue": "${NEXTCLOUD_ADMIN_USER}"
            },
            {
              "name": "NEXTCLOUD_ADMIN_PASSWORD",
              "secureValue": "${NEXTCLOUD_ADMIN_PASSWORD}"
            },
            {
              "name": "NEXTCLOUD_CHECK_CONFIG_OWNER",
              "value": "false"
            }
          ],
          "resources": {
            "requests": {
              "memoryInGB": "${CONTAINER_MEMORY_GB}",
              "cpu": "${CONTAINER_CPU_CORES}"
            }
          },
          "volumeMounts": [
            {
              "name": "nextcloud-config",
              "mountPath": "${NEXTCLOUD_CONFIG_MOUNT}"
            },
            {
              "name": "nextcloud-data",
              "mountPath": "${NEXTCLOUD_DATA_MOUNT}"
            },
            {
              "name": "client1-mount",
              "mountPath": "${STORAGE_SHARE_CLIENT_1_MOUNT}"
            },
            {
              "name": "client2-mount",
              "mountPath": "${STORAGE_SHARE_CLIENT_2_MOUNT}"
            },
            {
              "name": "client3-mount",
              "mountPath": "${STORAGE_SHARE_CLIENT_3_MOUNT}"
            }
          ]
        }
      }
    ],
    "ipAddress": {
      "type": "Public",
      "dnsNameLabel": "${CONTAINER_DNS_NAME}",
      "ports": [
        {
          "protocol": "TCP",
          "port": "${CONTAINER_PORT}",
        }
      ]
    },
    "volumes": [
      {
        "name": "nextcloud-config",
        "azureFile": {
          "shareName": "${NEXTCLOUD_CONFIG_SHARE_NAME}",
          "storageAccountName": "${STORAGE_ACCOUNT_NAME}",
          "storageAccountKey": "${STORAGE_ACCOUNT_KEY}"
        }
      },
      {
        "name": "nextcloud-data",
        "azureFile": {
          "shareName": "${NEXTCLOUD_DATA_SHARE_NAME}",
          "storageAccountName": "${STORAGE_ACCOUNT_NAME}",
          "storageAccountKey": "${STORAGE_ACCOUNT_KEY}"
        }
      },
      {
        "name": "client1-mount",
        "azureFile": {
          "shareName": "${STORAGE_SHARE_CLIENT_1_NAME}",
          "storageAccountName": "${STORAGE_ACCOUNT_NAME}",
          "storageAccountKey": "${STORAGE_ACCOUNT_KEY}"
        }
      },
      {
        "name": "client2-mount",
        "azureFile": {
          "shareName": "${STORAGE_SHARE_CLIENT_2_NAME}",
          "storageAccountName": "${STORAGE_ACCOUNT_NAME}",
          "storageAccountKey": "${STORAGE_ACCOUNT_KEY}"
        }
      },
      {
        "name": "client3-mount",
        "azureFile": {
          "shareName": "${STORAGE_SHARE_CLIENT_3_NAME}",
          "storageAccountName": "${STORAGE_ACCOUNT_NAME}",
          "storageAccountKey": "${STORAGE_ACCOUNT_KEY}"
        }
      }
    ]
  }
}

EOF

az container create \
  --resource-group "${RESOURCE_GROUP}" \
  --file ./nextcloud.json

echo ""
echo "Done!"

rm ./nextcloud.json

echo "Following installer progress in container logs..."
az container logs \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${CONTAINER_GROUP_NAME}" --follow
