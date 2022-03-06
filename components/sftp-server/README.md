# SFTP Server Add-on for Nextcloud Running on AKS
This folder contains everything needed to run an SFTP server as part of a
Nextcloud deployment. The server can used to grant one or more users direct 
access to the Azure Files volumes that underlie a Nextcloud AKS deployment, for
larger transfers that don't work well through the web interface to Nextcloud.

## Folder Contents
This folder contains a Kustomization add-on component for including SFTP in a
Kustomize deployment overlay.

## Using this Add-on
### Enabling the Add-on
In your overlay under `overlays/`, open `kustomization.yaml` and uncomment the
following sections:

```yaml
components:
  - ../../components/sftp-server
```

```yaml
generators:
  - decrypt-secrets.sftp.yaml
```

```yaml
configMapGenerator:
  - name: sftp
    files:
      - configs/sftp/users.conf
```

```yaml
transformers:
  - configure-storage.sftp.yaml
```

This will ensure that the add-on gets deployed to your cluster along with the
rest of Nextcloud.

### Providing Settings
Settings for this add-on are provided inside the Nextcloud deployment overlay,
in two files:

- `configs/sftp/users.conf` controls list of users that have access over SFTP as
  well as the encrypted password for each user. SFTP usernames have no
  relationship to usernames in Nextcloud itself.
- `configure-storage.sftp.yaml` controls which volumes from the larger Nextcloud
  deployment are available for access over SFTP, as well as which users have
  access to those volumes.

These files are described in depth in later sections.

### Granting Users SFTP Access
Run `./rigger add-sftp-user <username>` from within an overlay to add a user to
the `configs/sftp/users.conf` file in the overlay. For security reasons, you
will be prompted for the password of the user instead of being able to specify
it on the command line.

**NOTE:** All users added by the CLI command have a user ID of `33`. This is
_required_ to maintain compatibility with the way that the Azure Files volumes
are mounted in the Nextcloud  containers. 

Azure Files does not implement an ACL or POSIX ownership controls, but Nextcloud
requires specific permissions to function. To accommodate this, this kit uses
options exposed by the Azure Files driver (`mountOptions`) to set the user ID
and permissions of each volume at the _Persistent Volume_ level. In the
Nextcloud containers, user ID `33` is `www-data`. To avoid having to duplicate
each persistent volumes just to support SFTP, we re-use the same user ID in the
SFTP container to ensure each user has access to files on those same persistent 
volumes.

### Specifying which Volumes Users Have Access To
Modify `configure-storage.sftp.yaml` to control which volumes are available in
the SFTP container and which of those volumes are mounted within the home
folders of each user.

See the
[`configure-storage.sftp.yaml`](https://github.com/GuyPaddock/inveniem-nextcloud-azure/blob/master/kustomize/overlays/01-sample/configure-storage.sftp.yaml)
file in the sample overlay for an example of how to grant users access to file
shares. In the example file, the following users have access to the file shares
specified:
- Larry and Moe both have access to the `client1` volume/share. It will appear 
  as `/client1` in SFTP when they log in to their chroot-ed environment.
- Only Moe has access to the `client2` volume/share. It will appear as 
  `/client2` in SFTP when he logs-in to his chroot-ed environment.
- Curly and Moe both have access to the `client3` volume/share. It will appear 
  as `/client3` in SFTP when they log in to their chroot-ed environment.

### Prerequisite: Generating and Deploying Host Keys
To ensure that users don't get security errors when reconnecting to the cluster
after an SFTP pod has been cycled, this resource kit requires that SSH server
keys are pre-generated and deployed as a secret in the cluster.

Run the following command to generate them within the overlay:
```
./rigger generate-sftp-host-keys
```

The keys will be encrypted and saved in
`manifests/generated/secrets-sftp.enc.yaml`, which is safe to check in to source
control.

### Deploying the SFTP Server
Once enabled, SFTP will be deployed with Nextcloud when you run:
```
./rigger deploy
```

If you've already deployed Nextcloud, you can also selectively deploy just the
add-on and related shared components by running:
```
./rigger deploy sftp-ws-server --with-dependencies
```

### Setting-up DNS (Optional)
If you had Nextcloud installed at `nextcloud.example.com`, you might want to
configure an A record in your DNS zone so that `sftp.nextcloud.example.com` 
points at the IP address of the load balancer that is created by deploying this 
add-on.

After deploying this add-on, run `kubectl get services` to obtain the IP address
of the service. For example:

```
$ kubectl get services -n <YOUR NAMESPACE>

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
- **Username:** _One of the usernames from `configs/sftp/users.conf`_
- **Password:** _Password for this user_
