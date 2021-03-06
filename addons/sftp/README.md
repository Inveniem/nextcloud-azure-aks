# SFTP Server Add-on for Nextcloud Running on AKS 
This folder contains configurations and scripts to assist in setting up an 
SFTP server that can grant one or more users direct access to the Azure Files
volumes that underlie a Nextcloud AKS deployment.

## Using this Kit
### Providing Settings to the Scripts
All of the settings needed by scripts need to be provided in `config.env`.
Copy `config.example.env` to `config.env` and then customize it for your needs.

Some settings are pulled-in from the top-level `nextcloud-aks` `config.env` file 
as well; make sure both have been configured. See top-level README.md for 
details.

### Specifying User Names and Passwords
This is controlled by the `SFTP_USER_ARRAY` array in `config.env`.

See 
[`config.example.env`](https://github.com/GuyPaddock/inveniem-nextcloud-azure/blob/master/addons/sftp/config.example.env)
for an example of how to add users and passwords. In the example file, 
the following users are allowed to log-in to the system:
- `larry` with a password of `larry-password` (password was encrypted).
- `moe` with a password of `moe-password` (password was encrypted).
- `curly` with a password of `curly-password` (password was encrypted).

**NOTE:** All users _must_ have a user ID of `33` to maintain compatibility
with the way that the Azure Files volumes are mounted in the Nextcloud 
containers. 

Long story short, Azure Files does not implement an ACL or POSIX ownership 
controls, but Nextcloud requires specific permissions to function. To 
accommodate this, the top-level `nextcloud-aks` kit uses options exposed by the 
Azure Files driver (`mountOptions`) to set the user ID and permissions of each 
volume at the _Persistent Volume_ level. In the Nextcloud containers, user ID
`33` is `www-data`. To avoid having to duplicate each persistent volumes just to 
support SFTP, we are therefore forced to re-use the same user ID in the SFTP 
container to ensure each user has access to files on those same persistent 
volumes.

### Specifying which Volumes Users Have Access To
This is controlled by the `PATH_USERS` associative array in `config.env`.

See 
[`config.example.env`](https://github.com/GuyPaddock/inveniem-nextcloud-azure/blob/master/addons/sftp/config.example.env)
for an example of how to grant users access to file shares. In the example file, 
the following users have access to the file shares specified:
- Larry and Moe both have access to the `client1` volume/share. It will appear 
  as `/client1` in SFTP when they log-in to their chroot-ed environment.
- Only Moe has access to the `client2` volume/share. It will appear as 
  `/client2` in SFTP when he logs-in to his chroot-ed environment.
- Curly and Moe both have access to the `client3` volume/share. It will appear 
  as `/client3` in SFTP when they log-in to their chroot-ed environment.

### Prerequisite: Generating and Deploying Host Keys
To ensure that users don't get security errors when reconnecting to the cluster
after an SFTP pod has been cycled, this resource kit requires that SSH server
keys are pre-generated and deployed as a secret in the cluster.

After providing settings in both `config.env` files (the one in the current 
directory and the one in the top-level folder), run the following script
to perform this setup:
```
./setup_host_keys.sh
```

### Deploying the SFTP Server
You can now deploy the SFTP server to the cluster in the current Kubernetes 
namespace by running the following command:

```
./deploy_sftp_app.sh
```

This command is idempotent; you can tweak your deployment and run it again to
make changes to the SFTP pod configuration.

### Setting-up DNS (Optional)
If you had Nextcloud installed at `nextcloud.example.com`, you might want to
configure an A record in your DNS zone so that `sftp.nextcloud.example.com` 
points at the IP address of the load balancer that is created by deploying this 
add-on.

After deploying this add-on, run `kubectl get services` to obtain the IP address
of the service. For example:

```
$ kubectl get services

NAME                 TYPE           CLUSTER-IP  EXTERNAL-IP PORT(S)          AGE
external-sftp        LoadBalancer   10.0.1.5    1.2.3.4     22889:30425/TCP  1d
internal-clamav      ClusterIP      10.0.1.4    <none>      3310/TCP         1d
internal-nextcloud   ClusterIP      10.0.1.3    <none>      80/TCP           1d
internal-redis       ClusterIP      10.0.1.2    <none>      6379/TCP         1d
```

In the example above, the external IP address for SFTP is `1.2.3.4`, so you'd
create an A record for `sftp.nextcloud.example.com` that points to `1.2.3.4`.
Obviously, this is just an example -- customize DNS zones as appropriate for
your deployment.

### Connecting to the SFTP Server
- **Protocol:** Secure FTP (SFTP)
- **Hostname:** _IP address or hostname configured for load balancer (see above)._
- **Port:** 22889
- **Username:** _One of the usernames from `SFTP_USER_ARRAY`_
- **Password:** _Password you encoded for this user_
