# Kustomize-based Deployment of Nextcloud

## Pre-requisites for Use
1. Install the latest release of SOPS 
   [from GitHub](https://github.com/mozilla/sops/releases). For example:
   ```sh
   wget https://github.com/mozilla/sops/releases/download/v3.7.1/sops_3.7.1_amd64.deb
   sudo dpkg -i sops_3.7.1_amd64.deb
   ```

2. Define the `XDG_CONFIG_HOME` environment variable in your shell:
   ```sh
   echo "export XDG_CONFIG_HOME=\$HOME/.config" >> $HOME/.bashrc
   source $HOME/.bashrc
   ```

3. Install the [SOPS plug-in](https://github.com/viaduct-ai/kustomize-sops) for 
   Kustomize:
   ```sh
   source <( \
     curl -s https://raw.githubusercontent.com/viaduct-ai/kustomize-sops/master/scripts/install-ksops-archive.sh \
   )
   ```

4. Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt) (if not already installed):
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

5. Authenticate with the Azure CLI (follow instructions the command gives you to
   complete sign-in):
   ```sh
   az login
   ```

## Protecting Configuration from Re-install/Modification in Production
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
