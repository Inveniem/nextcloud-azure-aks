# Resources for Running Nextcloud on an Azure Kubernetes Service (AKS)
This repository contains docker images, configurations, and scripts to assist in 
getting Nextcloud to run  on an Azure Kubernetes Service.

This approach offers significantly more flexibility for storage than trying to
run Nextcloud on Azure Container Instances.

## Upgrading an Existing Nextcloud Deployment on AKS
If you have previously deployed this kit to AKS, exercise caution and follow the
steps in this section when upgrading to the latest version. 

### Prerequisites
Before upgrading, we recommend you:
1. Schedule a maintenance window with your organization that lasts at least 30
   minutes. Nextcloud will not be reachable during upgrades.
2. Backup your Nextcloud database.
3. Ensure that you have a backup copy of all files that are managed by
   Nextcloud. We recommend the best practice of following the 
   [3-2-1 Backup Strategy](https://www.backblaze.com/blog/the-3-2-1-backup-strategy/),
   which ensures your data is protected from risks even during normal operation
   (e.g., viruses, encryption-ware, accidental deletion, etc.).

### Upgrading between Major Versions of Nextcloud
Each major version of this kit works with a specific major version of Nextcloud. In
addition, Nextcloud does not support skipping major versions during upgrades, so
if you are several versions of Nextcloud behind, you will want to publish and
deploy this kit several times until your deployment has been upgraded to run the
latest version of Nextcloud.

Here is a list of which versions of Nextcloud are supported by each version of
this kit:

| nextcloud-azure-aks | Kubernetes Version Compatibility* | Nextcloud Version | Deployment Mechanism        |
|---------------------|-----------------------------------|-------------------|-----------------------------|
| 1.x                 | 1.15-1.21                         | 15.x              | Shell scripts and templates |
| 2.x                 | 1.15-1.21                         | 16.x              | Shell scripts and templates |
| 3.x                 | 1.15-1.21                         | 17.x              | Shell scripts and templates |
| 4.x                 | 1.15-1.21                         | 18.x              | Shell scripts and templates |
| 5.x                 | 1.15-1.21                         | 19.x              | Shell scripts and templates |
| 6.x                 | 1.16-1.22+                        | 19.x              | Shell scripts and templates |
| 7.x                 | 1.16-1.22+                        | 20.x              | Kustomize and Rigger        |

### Switching from "Shell Script" Deployment to "Kustomize" Deployment
If you are running version 1.x through 6.x of this kit and are now upgrading to
version 7.x, we recommend taking the following steps:

1. Clone this project to a new folder on your machine.
2. Ensure that all the dependencies listed under "Dependencies" in the
   "Deploying Nextcloud to AKS" section below are installed on your machine.
3. In the new copy of the project, copy `overlays/00-sample` to a new overlay in
   the same folder (e.g., `overlays/03-live`).
4. Migrate the settings you previously defined in `config.env` of your old copy
   into corresponding settings in the `.yaml` files of the overlay you created
   in the new copy of the project in step 3. See "Providing Settings and 
   Secrets" under the "Deploying Nextcloud to AKS" section below for information
   about the function of each file in the overlay.
5. Ensure that you are running at least Nextcloud 19 (version 5.x or 6.x of this 
   kit). If you are not, use your old copy of the project to publish and deploy
   each major version of this kit in succession until you've reached at least
   version 5.x of this kit).
6. Ensure your Kubernetes cluster is running at least AKS 1.16. As of this
   writing, the oldest version of Kubernetes that
   [Azure officially supports](https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions#kubernetes-version-support-policy)
   is 1.20.14.
7. Create a `02-test` overlay for Nextcloud that deploys to a separate
   `nextcloud-test` namespace within your cluster. Ideally, you will want this
   test copy to use a separate Azure Files account, separate MySQL/MariaDB
   database, and separate Key Vault from your production copy, in case something
   goes wrong during the Nextcloud upgrade. Deploy this overlay to your cluster 
   and use it to do a trial run of the upgrade process. Do not proceed until you
   have everything working on the test environment.
8. Dump a Yaml version of your current Nextcloud deployment manifest in case you
   need to reference it (e.g.,
   `kubectl get deployment --output=yaml -n nextcloud-live nextcloud > nextcloud.bak.yaml`).
9. Using the old copy of the project, undeploy all of Nextcloud, including its
   PVs, PVCs, secrets, services, and ingresses. If possible, delete the entire
   namespace that contains your Nextcloud deployment (e.g.,
   `kubectl delete namespace nextcloud-live`).
10. Ensure that you are starting with a replica count of `1` within your
    `kustomization.yaml` file so that multiple pods do not attempt to perform a
    database upgrade at the same time.
11. Use the new `03-live` overlay within the new copy of the project to
    re-deploy Nextcloud.
12. Use `kubectl get pods -n nextcloud-live` and `stern` or `kubectl logs` to 
    monitor the Nextcloud rollout and the database upgrade.
13. After the upgrade, sign in to Nextcloud and visit "Settings" > "Overview" to
    check on the health of your Nextcloud deployment.

## Deploying Nextcloud to AKS
### Dependencies
You will need to do the following before you can use this resource kit:
1. Create an AKS cluster.
2. Set up nginx ingress on the cluster (this project has not been updated to 
   work with Application Gateway ingress yet, but PRs are welcome!).
3. Set up an Azure Container Registry (ACR).
4. Set up a MySQL server instance on Azure.
5. Create an empty database and its corresponding user account on the MySQL 
   database instance.
6. Install Linux packages for each of the following on the machine from which 
   you will be deploying:
     - Docker Desktop (`docker`) with Kubernetes cluster (`kubectl`)
     - Git (`git`)
     - Kustomize (`kustomize`)
     - MySQL Client (`mysql`)
     - OpenSSL (`openssl`)
     - PHP 7.4+ (`php`)
     - yq (`yq`)
7. After installing the Azure CLI, 
   [sign in to your Azure account](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli).
8. Ensure that your account has the
   [the "Global administrator" role](https://docs.microsoft.com/en-us/azure/active-directory/users-groups-roles/directory-assign-admin-roles) 
   within your Azure AD tenant, for best results.
9. Install the latest release of SOPS
   [from GitHub](https://github.com/mozilla/sops/releases). For example:
   ```sh
   wget https://github.com/mozilla/sops/releases/download/v3.7.1/sops_3.7.1_amd64.deb
   sudo dpkg -i sops_3.7.1_amd64.deb
   ```
10. Define the `XDG_CONFIG_HOME` environment variable in your shell:
    ```sh
    echo "export XDG_CONFIG_HOME=\$HOME/.config" >> $HOME/.bashrc
    source $HOME/.bashrc
    ```
11. Install the [SOPS plug-in](https://github.com/viaduct-ai/kustomize-sops) for
    Kustomize:
    ```sh
    source <( \
      curl -s https://raw.githubusercontent.com/viaduct-ai/kustomize-sops/master/scripts/install-ksops-archive.sh \
    )
    ```
12. Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt) (if not already installed):
    ```sh
    sudo apt-get update
    sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg

    curl -sL https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor |
    sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

    AZ_REPO=$(lsb_release -cs)
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |
    sudo tee /etc/apt/sources.list.d/azure-cli.list

    sudo apt-get update
    sudo apt-get install azure-cli
    ```
13. Authenticate with the Azure CLI (follow instructions the command gives you to
    complete sign-in):
    ```sh
    az login
    ```
14. Create an Azure Files storage account (unless you are using some other
    storage provider, such as NFS, Ceph, or Qumulo as a Service).
15. Create an Azure Key Vault for each environment that you want to maintain
    secrets for.

### Providing Settings and Secrets
This kit uses Kustomize, the
[native configuration management tool](https://kustomize.io/) maintained by the
Kubernetes team, to maintain and generate Kubernetes deployment manifests.

The idea is that this project maintains the manifests that are in the "base"
configuration, and then you maintain settings and secrets in "overlays" that are
specific to each of the environments you maintain.

To get started, take a look at the Sample overlay in `overlays/00-sample`. Copy
the sample to a new overlay (e.g., `overlays/01-dev`), and then customize every
file in the overlay to match your environment. You can create and customize as
many overlays as you need, one for each environment.

A description of each important file in the overlay is described below:

#### `rigger`
["Rigger"](https://www.wise-geek.com/what-does-a-marine-rigger-do.htm) is a CLI
utility that automates common tasks when working with an overlay. Rigger is 
context-aware -- running it while your current working directory is inside an
overlay will cause Rigger to load and use the settings of that overlay. The
script actually lives at the root of the repository at `bin/rigger`, while the 
`rigger` script inside each overlay is a wrapper script to invoke it.

Run `./rigger --help` from within an overlay to see what sub-commands it 
provides. After configuring your overlay, the most common commands you will use
are `./rigger deploy`, `./rigger undeploy`, and `./rigger show-manifests`.

#### `kustomization.yaml`
This file controls how Kustomize merges and overrides configurations from the
base overlay with settings for your environment.

You will want to customize:
- The `components`, `generators`, `configMapGenerator`, and `transformers`
  sections based on which optional add-on components you want to include. See 
  the README.md files under each of the folders in the `components/` folder. Not
  all components are optional. You can also choose between either
  "Let's encrypt" or "Buypass" for SSL certificate issuance.
- The `patches` section:
  - So that it references the appropriate certificate issuer and includes an
    email address on your domain to notify about SSL certificate expiry.
  - (After deployment) You can configure the starting number of replicas to use
    for a higher-availability deployment of Nextcloud. This must be `1` during
    install/upgrade, and you could start with `1` and then setup auto-scaling or
    use the `./rigger scale` command instead.
- The `namespace` value, so that it references your desired, target namespace.
  Customize `manifests/namespace-nextcloud.yaml` so it matches the name you put
  here.
- The `images` section, so that it points to your ACR hostname.

#### `configure-storage.nextcloud.yaml`
This file controls where storage for Nextcloud is sourced from. This sample
defaults to storing the Nextcloud configuration and data volumes in two 
different Azure Files shares that are named `nextcloud-config` and
`nextcloud-data`, respectively. You will need to create the storage account and
configure network security before being able to use it with Nextcloud.

The actual storage account name is controlled by
`manifests/config-environment.yaml`. Once you have set up the storage account
in Azure and then added its name to `config-environment.yaml`, the secrets for
the storage account can be obtained and encrypted by running
`./rigger generate-storage-secrets`.

In addition – as this kit can be used to set up a multi-tenant Nextcloud
deployment – the sample sets up storage for three projects/clients called
`client1`, `client2`, and `client3` that are mounted inside the Nextcloud
container under `/mnt/share/client1`, `/mnt/share/client2`, and
`/mnt/share/client3`, for use as "Local" external shares inside Nextcloud. For
your setup:
- If you don't need multi-tenancy you can simply remove this section.
- If you do need to support multi-tenancy, under "Volumes for Client/Project
  Shares", modify the list of values under `permutations.values` to reflect the
  name of each client/share you've pre-created in your Azure Files account.

If you need to support a different storage provider than Azure Files, make the
appropriate changes to each `spec` and `mergeSpec` section in the file to match
the settings that are appropriate for your environment. See the documentation
for the
[Kustomize Storage Config Transformer](https://github.com/Inveniem/kustomize-storage-config-transformer).

#### `decrypt-secrets.nextcloud.yaml`
This instructs Kustomize in how SOPS should be invoked to decrypt secrets when
generating manifests. You typically will not need to modify this file.

#### `publish.profile`
This file controls how Nextcloud images are published to your ACR and what apps
are included in each image. Review the documentation for each value in the file
customize for your needs. Be sure that the apps you are specifying in
`NEXTCLOUD_CUSTOM_APPS` are compatible with your release of Nextcloud.

You can also define additional macros/commands that should be invoked before
publishing commands are run. For example, this is where you can add commands to
use the AZ CLI to refresh ACR credentials for Docker or Podman.

#### `manifests/config-environment.yaml`
This file controls several aspects of Nextcloud's deployment-time and run-time
behavior, including
- Whether file locking is enabled or disabled.
- What hostnames Nextcloud trusts for requests.
- What Azure Key Vault key is used to encrypt and decrypt keys through SOPS.
  More information about how to set up a key for SOPS in AKV is provided in
  [the SOPS documentation](https://github.com/mozilla/sops#encrypting-using-azure-key-vault).
- The names of the storage accounts that will be used to store Nextcloud config
  and data. The access keys for the accounts listed here will be retrieved and
  encrypted when you run `./rigger generate-storage-secrets`.

#### `manifests/namespace-nextcloud.yaml`
This file controls the name of the namespace that is created for the overlay.
The name included in this file must match the `namespace` declared in 
`kustomization.yaml`.

#### `manifests/secrets-mysql.yaml`
**THIS FILE SHOULD NOT BE CHECKED INTO SOURCE CONTROL**. It is included in the
sample overlay so that you know what information needs to be provided, but there
are rules in `.gitignore` that prevent this file from getting checked-in for
other overlays.

This file controls the hostname, port, username, etc. that are used to connect
to the Nextcloud database for this overlay. Customize this file, then run
`./rigger encrypt-secrets` to encrypt the secrets using SOPS to a file that is
safe to check in. Only developers who have been granted access to retrieve the
encryption key in AKV will be able to decrypt the secrets.

#### `manifests/secrets-nextcloud.yaml`
**THIS FILE SHOULD NOT BE CHECKED INTO SOURCE CONTROL**. It is included in the
sample overlay so that you know what information needs to be provided, but there
are rules in `.gitignore` that prevent this file from getting checked-in for
other overlays.

This file controls the admin username and password on a new installation of
Nextcloud for this overlay. **It has no effect on an existing Nextcloud 
deployment.** Customize this file, then run `./rigger encrypt-secrets` to
encrypt the secrets using SOPS to a file that is safe to check in. Only
developers who have been granted access to retrieve the encryption key in AKV
will be able to decrypt the secrets.

#### `manifests/secrets-redis.yaml`
**THIS FILE SHOULD NOT BE CHECKED INTO SOURCE CONTROL**. It is included in the
sample overlay so that you know what information needs to be provided, but there
are rules in `.gitignore` that prevent this file from getting checked-in for
other overlays.

This file controls the configuration of Redis, including the password that 
Nextcloud uses to authenticate with Redis. Though Redis is not externally 
accessible, this is a best practice to ensure that if an application within your
cluster – other than Nextcloud – is compromised, it cannot access user session
information.

### Protecting Configuration from Re-install/Modification in Production
If Nextcloud believes that the `config.php` file is missing, it will create a
new, blank `config.php` file. Unfortunately, this may trigger sporadically and
accidentally if the volume hosting Nextcloud configuration becomes disconnected
or unmounted at run-time, such as when a Kubernetes node is under significant
memory or CPU pressure, or the Azure Files storage account hosting Nextcloud is
throttling connections due to excessive IOPS or transfer throughput. Then, when
connectivity is restored, the blank `config.php` file will overwrite the real
copy of the file.

The result for the end-user is that they will be redirected to the Nextcloud
installer. Thankfully, after https://github.com/nextcloud/server/pull/14965, the
user will see an error message rather than being given the ability to re-install
Nextcloud and take full control of the installation. Regardless, this is not the
greatest UX because the Nextcloud installation will continue to display an error
message for all users until an admin restores the `config.php` from a backup
(assuming the admin has a backup at all!).

If you have a high-traffic or under-provisioned installation, or just want to
harden your server from security vulnerabilities that could modify your
Nextcloud configuration, it is recommended that you mount the `config` volume
read-only _except_ during initial setup and upgrades.

To do this, from within the overlay you are deploying, change the
`containerVolumeTemplates.volumeMountTemplates.mergeSpec.readOnly` setting in
the "Nextcloud Configuration Volume" section from `false` to `true` and then
re-deploy your application. When doing maintenance or upgrades, you will need to
change this setting back to `false` until you are done. Then, change it back to
`true` to restore the installation to a hardened state.

### Granting AKS Access to Azure Container Registry (ACR)
In order to use the Docker images generated by the Dockerfiles in this repo, you
will need to publish them to ACR, and you will need to give AKS a means to 
access ACR.

The preferred approach for this is to use AKS ACR integration, as described in
[official documentation](https://docs.microsoft.com/en-us/azure/aks/cluster-container-registry-integration).

### Building and Pushing Images
You will need to build and push Docker images from this repo to your own Azure
Container Registry. 

Configure ACR settings in `publish.profile` within the overlay, then build and
publish images using `./rigger publish`. You can control what Docker images the
overlay uses at run-time by using `./rigger version-stamp` after checking out a
tagged version (it will update `kustomization.yaml`).

### Running the Deployment
Once your overlay has been configured, change your working directory into the
overlay and run `./rigger show-manifests` to see and review all the Kubernetes 
deployment manifests that will be pushed to your Kubernetes cluster. If
everything looks good, run `./rigger deploy` to perform the deployment!

#### About the Redis Cache
To support clustered deployment (i.e. multiple Nextcloud pods behind a load
balancer), this resource kit is designed to create a Redis cache pod within
the cluster that is used to persist file locks and PHP sessions. The cache is 
automatically created during deployment.

#### Setting Up Antivirus
If you fully deploy this kit, you will end up with a ClamAV pod and service 
running alongside the pods for Nextcloud. ClamAV is configured to run in daemon 
mode, to support antivirus scans through the 
[Nextcloud Antivirus app](https://docs.nextcloud.com/server/15/admin_manual/configuration_server/antivirus_configuration.html). 
You will need to enable the app and configure antivirus settings under 
`settings/admin/security` after Nextcloud is installed for the first time.

Use these settings:
- **Mode:** 
  Daemon
- **Host:** 
  internal-clamav._NAMESPACE_ (where _NAMESPACE_ is the Kubernetes namespace, 
  such as `default` or `nextcloud-live`)
- **Port:** 
  3310
- **Stream Length:** 
  26214400 bytes
- **File size limit, -1 means no limit:** 
  -1 bytes
- **When infected files are found during a background scan:** 
  _(Administrator choice)_

## Removing Nextcloud
Run `./rigger undeploy` to remove all the resources that were created during
deployment. This will include all secrets, persistent volumes, persistent volume
claims, secrets, etc.

**If you have changed configuration since deployment:** It's possible that not
all resources will be removed. For example, if you deployed with one set of
Azure Files shares, then customize the list to remove a share and un-deploy,
it's possible that one or more persistent volumes will not get removed because
they are no longer referenced by the generated manifests.

## Additional Admin Utilities
Rigger includes several additional sub-commands to make administration of 
deployments slightly easier.

### Connecting to the Nextcloud CLI
Nextcloud documentation often references running commands with an `occ` utility
to perform administrative tasks like cleaning-up trash bins, repairing the
database, installing indices, etc.

Run `./rigger launch-shell` to be launched into a shell session on the
first-available Nextcloud pod in your cluster. You will automatically be signed
in as the `www-data` user and dropped into `/var/www/html` and can run `./occ`
commands from this terminal

### Connecting to the MySQL CLI
Run `./rigger launch-db-shell` to launch the MySQL CLI, connected via the same 
credentials that Nextcloud uses to connect.

## Licensing
All scripts and documentation provided in this repository are licensed under the
GNU Affero GPL version 3, or any later version.

© 2019-2022 Inveniem. All rights reserved.
