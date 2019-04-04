# Helm Ingress Add-on for Nextcloud Running on AKS 
This folder contains configurations and scripts to assist in setting up an 
ingress controller on AKS, running over HTTPS with certificates automatically
issued and renewed by Let's Encrypt.

This approach is based primarily on 
[Microsoft's Official Documentation](https://docs.microsoft.com/en-us/azure/aks/ingress-tls).

## Using this Kit
### Providing Settings to the Scripts
All of the settings needed by scripts need to be provided in `config.env`.
Copy `config.example.env` to `config.env` and then customize it for your needs.

Some settings are pulled-in from the top-level `nextcloud-aks` `config.env` file 
as well; make sure both have been configured. See top-level README.md for details.

### Prerequisite: Setting Up Helm and Tiller
Before Helm can be used to install components on the cluster, the cluster needs
to be configured with a Tiller server, and provided with TLS certificates to
secure the connection between the server and Helm clients.

After providing settings in both `config.env` files (the one in the current 
directory and the one in the top-level folder), run scripts in the following 
order to perform this setup:
1. `./generate_ca_cert.sh` (do NOT run this a second time or you will lose CA certs).
2. `./generate_helm_client_cert.sh`
3. `./generate_tiller_server_cert.sh`
4. `./setup_helm.sh`

## Prerequisite: Installing an Ingress Controller and Certificate Issuer
Before ingress can be deployed for Nextcloud, the cluster needs an ingress 
_controller_ and a certificate issuer that can use Let's Encrypt to generate 
SSL certificates.

After setting-up Helm and Tiller, run scripts in the following order to 
deploy an nginx-based ingress controller and certificate issuer:

1. `./setup_cert_manager.sh`
2. `./deploy_certmanager_issuer.sh`
3. `./setup_ingress_controller.sh`

### Deploying the Certificate Manager and Nextcloud Ingress
You can now deploy an ingress route for Nextcloud in the current Kubernetes 
namespace by running the following command:

```
./deploy_nextcloud_ingress.sh
```

This command is idempotent; you can tweak your deployment and run it again to
make changes to the ingress configuration.

This configuration automatically routes to the Nextcloud service that is 
deployed and made available by the top-level `nextcloud-aks` kit. You only need
to deploy the ingress route once; you don't need to be re-deploy it if/when
you re-deploy Nextcloud or make changes to your Nextcloud deployment (e.g. 
adding or removing replicas, updating images, etc). If there are no Nextcloud
instances available for the ingress to route to, you will get a 503 error.
