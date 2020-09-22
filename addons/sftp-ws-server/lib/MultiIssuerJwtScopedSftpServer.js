"use strict";

const JwtScopedSftpServer = require("./JwtScopedSftpServer");

/**
 * A JWT-based SFTP-WS server that allows JWT secrets to vary by request origin.
 */
class MultiIssuerJwtScopedSftpServer extends JwtScopedSftpServer {
  /**
   * Constructor for MultiIssuerJwtScopedSftpServer.
   *
   * @param {string} appHost
   *   The external host name and port of this application. This must match the
   *   "audience" of incoming JWTs.
   * @param {Map.<(string|RegExp),(String|Buffer)>} originSecretMap
   *   A map in which:
   *   - Each key is a regular expression used to match an origin that a client
   *     may be directed to make connections on behalf of; and
   *   - The value is the secret used to validate the signature on a JWT from
   *     the corresponding origin is authentic; as either a Buffer containing
   *     an HS256, HS384, or HS512 shared secret in Base64-encoding, or a string
   *     containing an RS256, RS384, or RS512 public key.
   * @param {object} options
   *   Optional arguments to configure the SFTP server instance.
   */
  constructor(appHost, originSecretMap, options = {}) {
    super(appHost, Array.from(originSecretMap.keys()), null, options);

    this.originSecretMap = originSecretMap;
  }

  /**
   * Gets the secret used to validate that the signature on a JWT is authentic.
   *
   * This can be either a Buffer containing an HS256, HS384, or HS512 shared
   * secret in Base64-encoding, or a string containing an RS256, RS384, or RS512
   * public key.
   *
   * The secret returned is the one appropriate for the given origin.
   *
   * @param {string} origin
   *   The origin from which the request originated, as a URL.
   *
   * @returns {(string|Buffer|null)}
   *   The secret; or, null if there is no secret that matches the provided
   *   origin.
   */
  getJwtSigningSecret(origin) {
    for (const [originPattern, signingSecret] of this.originSecretMap) {
      let originRegex = this.convertToRegex(originPattern);

      if (origin.match(originRegex)) {
        return signingSecret;
      }
    }

    return null;
  }
}

module.exports = MultiIssuerJwtScopedSftpServer;
