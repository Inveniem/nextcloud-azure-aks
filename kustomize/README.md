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
