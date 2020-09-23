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
   * @param {Map.<(string|RegExp),
   *              {
   *                public_key:    (String|Buffer),
   *                allowed_paths: string[]
   *              }>
   *        } originRestrictions
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
  constructor(appHost, originRestrictions, options = {}) {
    super(appHost, Array.from(originRestrictions.keys()), null, options);

    this.originRestrictions = originRestrictions;
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
   * @override
   * @param {string} origin
   *   The origin from which the request originated, as a URL.
   *
   * @returns {(string|Buffer|null)}
   *   The secret; or, null if there is no secret that matches the provided
   *   origin.
   */
  getJwtSigningSecret(origin) {
    for (const [originPattern, restrictions] of this.originRestrictions) {
      let originRegex = this.convertToRegex(originPattern);

      if (origin.match(originRegex)) {
        if (restrictions.public_key) {
          return restrictions.public_key;
        }
        else {
          this._log.error("Origin is missing a 'public_key': " + origin);
        }
      }
    }

    return null;
  }

  /**
   * @inheritDoc
   */
  validateJwtAndInitializeSession(jwt) {
    let sessionInfo = super.validateJwtAndInitializeSession(jwt);

    if (sessionInfo) {
      const origin = jwt.iss;

      if (!this.validateOriginPathRestrictions(origin, jwt)) {
        sessionInfo = false;
      }
    }

    return sessionInfo;
  }

  /**
   * Validates a JWT's authorized paths are a subset of origin's allowed paths.
   *
   * @param {string} origin
   *   The 'Origin' that was provided as the issuer in the JWT.
   * @param {object} jwt
   *   The JWT that was parsed from the request.
   *
   * @returns {boolean}
   *   true if the JWT does not allow access to any path outside of those
   *   permitted for the origin; false otherwise.
   */
  validateOriginPathRestrictions(origin, jwt) {
    let isValid = true;

    for (const [originPattern, restrictions] of this.originRestrictions) {
      let originRegex = this.convertToRegex(originPattern);

      if (origin.match(originRegex)) {
        const originAllowedPaths = (restrictions.allowed_paths || []);

        if (!Array.isArray(originAllowedPaths) ||
            (originAllowedPaths.length === 0)) {
          this._log.error(
            "Origin is missing an 'allowed_paths' restriction: " + origin
          );

          isValid = false;
          break;
        }
        else {
          const badPaths =
            jwt.authorized_paths.filter(
              (path) => !originAllowedPaths.includes(path)
            );

          if (badPaths.length !== 0) {
            this._log.error(
              "Valid JWT presented with an 'authorized_paths' claim that is " +
              "invalid for the origin. JWT: '%s', origin: '%s', allowed " +
              "paths for origin: '%s'",
              JSON.stringify(jwt),
              origin,
              JSON.stringify(originAllowedPaths)
            );

            isValid = false;
            break;
          }
        }
      }
    }

    return isValid;
  }
}

module.exports = MultiIssuerJwtScopedSftpServer;
