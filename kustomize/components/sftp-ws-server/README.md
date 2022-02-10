# SFTP-WS Server Add-on for Nextcloud Running on AKS 
This folder contains everything needed to run an
[SFTP-WS server](https://github.com/Inveniem/sftp-ws) as part of a Nextcloud
deployment. The SFTP-WS server can be used by browser-based applications other
than Nextcloud to read files from and write files to the volumes that back a
Nextcloud AKS deployment.

## Folder Contents
This folder contains:
- The source code for the NodeJS-based server application.
- Dockerfile and publishing script for releasing the application as a Docker 
  image in an Azure Container Registry. 
- A Kustomization add-on component for including the application in a Kustomize
  deployment overlay.

## Using this Add-on
### Enabling the Add-on
In your overlay under `overlays/`, open `kustomization.yaml` and uncomment the
following sections:

```yaml
components:
  - ../../components/sftp-ws-server
```

```yaml
configMapGenerator:
  - name: sftp-ws
    files:
      - originRestrictions=configs/sftp-ws/origin-restrictions.json
```

```yaml
transformers:
  - configure-storage.sftp-ws.yaml
```

This will ensure that the add-on gets deployed to your cluster along with the
rest of Nextcloud when you run:
```
./rigger deploy
```

If you've already deployed Nextcloud, you can also selectively deploy just the
add-on and related shared components by running:
```
./rigger deploy sftp-ws-server --with-dependencies
```

### Providing Settings
Settings for this add-on are provided inside the Nextcloud deployment overlay,
in two files:

- `configure-storage.sftp-ws.yaml` controls which volumes from the larger
  Nextcloud deployment are available for access over SFTP-WS.
- `configs/sftp-ws/origin-restrictions.json` controls which combination of RSA
  public keys and CORS origins are allowed to access each of the file shares
  that are exposed.

These files are described in depth in later sections.

### Specifying which Volumes the SFTP-WS Server Has Access To
This is controlled by the `configure-storage.sftp-ws.yaml` file inside your
overlay. Modify the `permutations` key to add or remove volumes from being
exposed inside the SFTP-WS server.

### Generating Key Pairs for Authentication
Run `./rigger sftp-ws-generate-keypair <name of keypair>` from within an
overlay to generate a private key in the overlay as
`generated-keys/<name of keypair>/jwt_private.pem` and the public key as 
`generated-keys/<name of keypair>/jwt_public.pem`. The client should be
configured to sign its JWTs with the private key, and the public key should be
supplied to the SFTP-WS server via the origin restrictions configuration file
(see next section).

### Specifying Origin Restrictions
For security reasons -- in addition to the SFTP-WS server only having access to
some but not all Nextcloud volumes -- the server also only selectively exposes
only a subset of file shares over the SFTP-WS protocol based on information in
the JWT presented during connection in the `token` query-string parameter of the
UPGRADE HTTP request.

This is controlled by the `configs/sftp-ws/origin-restrictions.json` file inside
your overlay. The file specifies which origins are allowed to connect to the
SFTP-WS server, what paths/shares a given origin is allowed to grant access to
via the JWT, and what public key is used to validate JWTs from that origin.

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
