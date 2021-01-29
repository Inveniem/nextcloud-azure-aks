# SFTP-WS Server Add-on for Nextcloud Running on AKS 
This folder contains configurations and scripts to assist in setting up an 
SFTP-WS server that web applications other than Nextcloud can use to read files
from and write files to the Azure Files volumes that underlie a Nextcloud AKS
deployment.

## Using this Kit
### Providing Settings to the Scripts
All of the settings needed by scripts need to be provided in `config.env`
and `config.restrictions.json`. Copy `config.example.env` to `config.env`,
`config.origin_restrictions.example.json` to `config.origin_restrictions.json`, 
and then customize both for your needs.

Some settings are pulled-in from the top-level `nextcloud-aks` `config.env` file 
as well; make sure both have been configured. See top-level README.md for 
details.

### Specifying which Volumes the SFTP-WS Server Has Access To
This is controlled by the `SFTP_WS_FILE_SHARES` associative array in 
`config.env`.

See 
[`config.example.env`](https://github.com/GuyPaddock/inveniem-nextcloud-azure/blob/master/addons/sftp-ws-server/config.example.env)
for an example of how to expose a Nextcloud file share into the SFTP-WS Server
pod. In the example file, the `client1` volume/share is exposed. It will appear 
as `/files/client1` in the container.

### Generating Key Pairs for Authentication
Run `generate_jwt_rs256_keypair.sh` to save the private key to `jwt_private.pem`
and the public key to `jwt_public.pem`. The client should be configured with the
private key, and the public key should be supplied to the SFTP-WS server via
Origin restrictions (see next section).

### Specifying Origin Restrictions
For security reasons -- in addition to the SFTP-WS server only having access to
some but not all Nextcloud volumes -- the server also only selectively exposes
only a subset of file shares over the SFTP-WS protocol based on information in
the JWT presented during connection in the `token` query-string parameter of the
UPGRADE HTTP request.

This is controlled by the `config.origin_restrictions.json` file. The file
specifies which origins are allowed to connect to the SFTP-WS server, what
paths/shares a given origin is allowed to grant access to via the JWT, and what
public key is used to validate JWTs from that origin.

For example, consider these origin restrictions:
```json
{
  "\\Ahttps?://some.remote.client.example.com\\z": {
    "public_key": "-----BEGIN PUBLIC KEY-----\n... <snip> RSA public key A <snip> ...\n-----END PUBLIC KEY-----",
    "allowed_paths": [
      "client1",
      "client2"
    ]
  },
  "\\Ahttps?://other.remote.client.example.com\\z": {
    "public_key": "-----BEGIN PUBLIC KEY-----\n... <snip> RSA public key B <snip> ...\n-----END PUBLIC KEY-----",
    "allowed_paths": [
      "client3"
    ]
  }
}
```

This specifies five things:
1. Connection requests are only accepted from hosts having an `Origin` header
   that matches the regular expression patterns
   `\Ahttps?://some.remote.client.example.com\z` and
   `\Ahttps?://other.remote.client.example.com\z`, so
   only requests from hosts like `http://some.remote.client.example.com` and
   `https://other.remote.client.example.com`. Requests with any other `Origin`
   will be rejected.
2. That requests from `https://some.remote.client.example.com` must be
   authenticated by a JWT signed by the RSA private key matching RSA public key
   A. 
3. That requests from `https://other.remote.client.example.com` must be
   authenticated by a JWT signed by the RSA private key matching RSA public key
   B. 
4. A web application hosted at `https://some.remote.client.example.com` can only
   grant its users access to the `client1` and `client2` paths. Any JWT from
   this web application that tries to grant access to other paths (e.g. 
   `client3`) will be rejected. 
5. A web application hosted at `https://other.remote.client.example.com` can only
   grant its users access to the `client3` paths. Any JWT from this web
   application that tries to grant access to other paths (e.g. `client1` or 
   `client2`) will be rejected. 
   
With these origin restrictions, consider an `UPGRADE` request to this URL:
```
http://localhost:4002/sftp?token=eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL3NvbWUucmVtb3RlLmNsaWVudC5leGFtcGxlLmNvbSIsImF1ZCI6Im5leHRjbG91ZDEuZXhhbXBsZS5jb206NDAwMiIsImlhdCI6MTYwMDcyOTg4NiwiZXhwIjoxNjAwNzI5OTk5LCJzdWIiOiJndXlAZXhhbXBsZS5jb20iLCJhdXRob3JpemVkX3BhdGhzIjpbImNsaWVudDEiXX0.Wf-ABpH9X7wncIQvxC3-oYtxTjGN1tCpTy2-lBdSsFpuRZq46SOJVFsly9uTZtFWsSTDGbLiwwc-WA9tGY9EX4E5SmYx7gDRGVj6lEsfKm_9XX_z7tOkxKkfeLgRPij1mEmFEfXylJuBhNP3990nyrk5hbq3Xt0vHXtiu6x_i4GKBYgrF37a0TKOEcOxetHgFkyhroNY7oGbuvy9DfIL-ucPnQmEqJF7yuO2DCrPq-ViG1wSuehTTxynHHQrvl72VYH6a9SrE8h0C47LjNaRa0I5L0kwAe4pCeK2diARD73BuqnBUI-2IwlqvEQuuqP-WrW_mPSWPZqvaPgqZfNP_g
```

The decoded JWT payload contains:
```json
{
  "iss": "https://some.remote.client.example.com",
  "aud": "nextcloud1.example.com:4002",
  "iat": 1600729886,
  "exp": 1600729999,
  "sub": "guy@example.com",
  "authorized_paths": [
    "client1"
  ]
}
```

Assuming that this JWT was signed with the RSA private key corresponding to
public key A, and that the SFTP-WS server is hosted at
`nextcloud1.example.com:4002`, this JWT would be accepted, and grant the user
access to see and interact with only files from the `client1` Nextcloud share.

Conversely, consider another `UPGRADE` request to this URL:
```
http://localhost:4002/sftp?token=eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL3NvbWUucmVtb3RlLmNsaWVudC5leGFtcGxlLmNvbSIsImF1ZCI6Im5leHRjbG91ZDEuZXhhbXBsZS5jb206NDAwMiIsImlhdCI6MTYwMDcyOTg4NiwiZXhwIjoxNjAwNzI5OTk5LCJzdWIiOiJndXlAZXhhbXBsZS5jb20iLCJhdXRob3JpemVkX3BhdGhzIjpbImNsaWVudDMiXX0.MUbiDpCBlwtmoSI6lcMW1Oe_cphCmlfPez3e7GVlTEd3jGjBf3L4V8wXPb5uScpO0i2vyzZuNu835AZamTMtw4UeCkLaGqHbJGCrwnBhDyQHjUWJJPfQGsEgfN8dxZEo8T5oCBmhSYpos3dX4_0-KJYTL2DRfZwlmWSIhThZkPEbUSZedzDu6DrOC5lG0fYf9ASbrWexGI9S1nCH_Rny2OdMmi71NQO1loml7yclEMkAzamlfp0kThQI0U98jZxNMYngaKA3PgJhOHtzY_J04y73c4nAfIs4CyGTD8lP3SS3PQOOxIBjYO8A5x0pP9tyWxsqRSX-_lZbBduHs9dbVQ
```

The decoded JWT payload of this second request contains:
```json
{
  "iss": "https://some.remote.client.example.com",
  "aud": "nextcloud1.example.com:4002",
  "iat": 1600729886,
  "exp": 1600729999,
  "sub": "guy@example.com",
  "authorized_paths": [
    "client3"
  ]
}
```

This request would be denied with a `403 Forbidden` since
`some.remote.client.example.com` is not allowed to grant any of its users access
to files from `client3`.

### Deploying the SFTP Server
You can now deploy the SFTP server to the cluster in the current Kubernetes 
namespace by running the following command:

```
./deploy_sftp_ws_server_app.sh
```

This command is idempotent; you can tweak your deployment and run it again to
make changes to the SFTP-WS server pod configuration.
