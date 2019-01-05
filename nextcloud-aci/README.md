# Resources for Running Nextcloud on an Azure Container Instance (ACI)
This folder contains scripts which can assist in trying to get Nextcloud to run 
on an Azure Containers Instance.

**NOTE:** This approach will not work. See "Why This Approach Fails" and "Where 
Do We Go from Here?".

## About This Folder
The `create_nextcloud.sh` script in this folder automatically performs the 
following actions:
 - Drops the existing Nextcloud resource group (if it exists).
 - Drops the existing Nextcloud database (if it exists).
 - Creates the Nextcloud resource group
 - Creates a new Azure Files storage account, which can be either:
    - `Standard_LRS`, which can be in any world region.
    - `Premium_LRS`, which can only exist in specific world regions, since it is 
      in preview at the time of this writing. More info can be found 
      [on the Azure blog](https://azure.microsoft.com/en-us/blog/premium-files-pushes-azure-files-limits-by-100x/).
 - Creates one Azure Files share for Nextcloud's apps, themes, and config.
 - Creates another Azure Files share for Nextcloud's data.
 - Creates Azure Files shares for three distinct Inveniem clients.
 - Deploys Nextcloud to an Azure Container Instance, with the following setup:
    - In the same region as the Azure Files storage (to avoid lag and 
      egress/ingress fees).
    - With all five Azure Files shares mounted as volumes in the container.
    - With all settings needed for installation (database host and user 
      credentials; and admin username and password) passed-in via environment 
      variables.
    - With the desired DNS name and port numbers needed to access Nextcloud.

The `drop_nextcloud.sh` script drops both the resource group and the Nextcloud 
database.

## Providing Settings to the Script
All of the settings needed by scripts need to be provided in `config.env`.

Copy `config.example.env` to `config.env` and then customize it for your needs.

## Why This Approach Fails
Unfortunately, this approach doesn't work well for two reasons: a technical 
issue, and a pricing issue.

### The Technical Issue with This Approach
ended up not working because of limitations in both
Azure Files and Nextcloud. Nextcloud requires `config.php` to be owned by the
same user account as the web server is running under (i.e. `www-data`) and to
have permissions of `0770`. Meanwhile, Azure Files uses SMB which does not 
support POSIX file ownership, so Nextcloud fails to deploy successfully. 

To add insult to injury, Azure Container Instances do not support any options for 
volume persistence other than Azure Files. If you do not setup volumes, 
Nextcloud will seem to install and run fine in a container instance until the 
container gets restarted, at which point **you will lose all of your files and
configuration settings**. 

The files here are being provided for reference, should we want to try a similar
approach with other containers in the future. At a minimum, this illustrates how
to setup and tear-down elaborate infrastructure on AWS using a shell script.

### The Pricing Issue with This Approach
Azure Container Instances are much more expensive than VMs of the same size. 
Running Nextcloud on Azure Kubernetes service or even directly on a VM is more 
cost-effective.

Consider a Nextcloud container with the following specifications:
- **vCPU:** 2
- **RAM:** 4 GB

These specifications are identical to an F2s v2 instance. As of January 2019, 
here's how pricing compares between these options in the West US 2 region:
- **With ACI:** Nextcloud would cost $105.12/month + storage costs. 
- **With an F2s v2 VM:** Nextcloud would cost $62.05/month + storage costs. 

ACI is nearly 41% more expensive. Compared to Dropbox:
- ACI costs as much as 5 users on a Dropbox Advanced plan and 8 users on a 
  Dropbox Standard plan.
- An F2s v2 VM costs as much as 3 users on a Dropbox Advanced plan and almost as 
  much as 5 users on a Dropbox Standard plan.

## Where Do We Go from Here?
[An enhancement request](https://github.com/nextcloud/server/issues/13277) was 
filed with Nextcloud requesting a way to suppress permission and ownership 
checks within Nextcloud. You may follow that issue for more information.

A [proof of concept (PoC)](https://github.com/GuyPaddock/nextcloud-server/commits/feature/skip-owner-checks) 
for the enhancement was developed for suppressing file ownership checking, but 
the PoC does not include the logic for skipping file mode checks (e.g. the check 
that requires files to have a mode of `0770`). Additional work would be required 
for such a check. A sample `Dockerfile` and Docker entrypoint, based on the 
`nextcloud:15-apache` Docker image, have been provided in the `docker/` folder 
to accompany this PoC.

If Nextcloud were fully modified to support this deployment model, Azure would
still need to reduce the price of ACIs in order for it to be an attractive
alternative to Dropbox.

Alternatively, Nextcloud can be run on Azure Kubernetes Service (AKS) since it
provides more robust control over volumes at a much more affordable price. F2s
v2 instances can be used as Kubernetes nodes. This has the added benefit that
multiple applications can be run on the same VMs in addition to Nextcloud, 
further increasing the cost effectiveness of your installation.
