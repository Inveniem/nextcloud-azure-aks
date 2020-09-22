"use strict";

const {JsonWebTokenError} = require("jsonwebtoken");
const jwt                 = require('jsonwebtoken');
const url                 = require('url');
const SFTP                = require("@inveniem/sftp-ws");
const FilteredFilesystem  = require("./FilteredFilesystem");

/**
 * An SFTP-WS server implementation that uses JWT-based authentication.
 *
 * The files/folders exposed to clients are based on what is specified in the
 * "authorized_paths" claim of the signed JWT identity token.
 */
class JwtScopedSftpServer extends SFTP.Server {
  /**
   * Constructor for JwtScopedSftpServer.
   *
   * @param {string} appHost
   *   The external host name and port of this application. This must match the
   *   "audience" of incoming JWTs.
   * @param {(string[]|RegExp[])} allowedOrigins
   *   An array of regular expressions used to match what origins clients may
   *   be directed to make connections on behalf of. Matching is done based on
   *   the "Origin" header in the UPGRADE request.
   * @param {(string|Buffer)} jwtSigningSecret
   *   The secret used to validate that the signature on a JWT is authentic; as
   *   either a Buffer containing an HS256, HS384, or HS512 shared secret in
   *   Base64-encoding, or a string containing an RS256, RS384, or RS512
   *   public key.
   * @param {object} options
   *   Optional arguments to configure the SFTP server instance.
   */
  constructor(appHost, allowedOrigins, jwtSigningSecret, options = {}) {
    // Prevent options we forcibly control from being set.
    ['verifyClient', 'filesystem'].forEach(function (unsupportedOption) {
      if (options[unsupportedOption]) {
        throw new Error(
          'This server does not support the `' + unsupportedOption + '` option'
        );
      }
    });

    // Prevent default, unfiltered filesystem view from being used.
    options.filesystem = null;

    super(options);

    if ((typeof appHost !== 'string') || !appHost.match(/^[^:]+:[\d]+$/)) {
      throw new Error(
        '`appHost` must be a string consisting of "host:port" (no protocol)'
      );
    }

    if (!Array.isArray(allowedOrigins)) {
      throw new Error(
        '`allowedOrigins` must be provided as an array of regular expressions'
      );
    }

    this.allowedOrigins   = allowedOrigins;
    this.appHost          = appHost;
    this.jwtSigningSecret = jwtSigningSecret;

    this._verifyClient = this.authenticateClient;
  }

  /**
   * Gets the secret used to validate that the signature on a JWT is authentic.
   *
   * This can be either a Buffer containing an HS256, HS384, or HS512 shared
   * secret in Base64-encoding, or a string containing an RS256, RS384, or RS512
   * public key.
   *
   * Origin must be provided, to allow sub-classes the flexibility to vary which
   * secret gets returned by the origin of the request. This is secure because
   * the issuer of the JWT is *required* to match the issuer claim ("iss") in
   * the JWT.
   *
   * @param {string} origin
   *   The origin from which the request originated, as a URL.
   *
   * @returns {(string|Buffer|null)}
   *   The secret; or, null if there is no secret that matches the provided
   *   origin.
   */
  getJwtSigningSecret(origin) {
    return this.jwtSigningSecret;
  }

  /**
   * Verifies that a particular client should be allowed to connect.
   *
   * @param {RequestInfo} requestInfo
   *   The incoming WebSocket connection request and header information.
   *
   * @returns {(boolean|{filesystem: IFilesystem})}
   *   Either the default parameters to apply to the client's new session; or,
   *   false if the user is not allowed to authenticate.
   */
  authenticateClient = (requestInfo) => {
    let   sessionInfo     = false;
    const requestOrigin   = requestInfo.origin,
          isAllowedOrigin = this.validateOrigin(requestOrigin);

    if (isAllowedOrigin) {
      const queryParams = url.parse(requestInfo.req.url, true).query,
            token       = queryParams.token,
            parsedJwt   = this.parseJwt(requestOrigin, token);

      if (parsedJwt) {
        sessionInfo = this.validateJwtAndInitializeSession(parsedJwt);
      }
    }

    return sessionInfo;
  }

  /**
   * Validates the origin of an incoming SFTP-WS connection request.
   *
   * @param {string} origin
   *   The 'Origin' header that was provided in the request.
   *
   * @returns {boolean}
   *   true if the origin is allowed; or, false, if it is not.
   */
  validateOrigin(origin) {
    let isAllowedOrigin = false;

    if (origin) {
      for (const allowedOrigin of this.allowedOrigins) {
        let originRegex = this.convertToRegex(allowedOrigin);

        if (origin.match(originRegex)) {
          isAllowedOrigin = true;
          break;
        }
      }
    }

    return isAllowedOrigin;
  }

  /**
   * Parses and validates the JWT of an incoming SFTP-WS connection request.
   *
   * @param {string} origin
   *   The 'Origin' header that was provided in the request.
   * @param {string} token
   *   The JSON Web Token that was provided in the query-string of the request.
   *
   * @returns {(null|{
   *            iss: string,
   *            aud: string,
   *            iat: int,
   *            exp: int,
   *            authorized_paths: string[]
   *          })}
   *  The parsed JWT; or, null, if the JWT is not valid/acceptable.
   */
  parseJwt(origin, token) {
    let parsedJwt = null;

    if (token) {
      const jwtSigningSecret = this.getJwtSigningSecret(origin);

      if (jwtSigningSecret) {
        try {
          // noinspection JSUnresolvedVariable
          parsedJwt =
            jwt.verify(
              token,
              jwtSigningSecret,
              {
                audience: this.appHost,
                issuer:   origin
              }
            );
        }
        catch (ex) {
          if (ex instanceof JsonWebTokenError) {
            this._log.error(
              'JWT validation failed (' + ex + ') - JWT: ' + token
            );
          }
          else {
            throw ex;
          }
        }
      }
    }

    return parsedJwt;
  }

  /**
   * Uses the JWT presented by a client to initialize his or her session.
   *
   * The basic claims and signature of the JWT are validated before this method
   * is called. This method is only called if the JWT has been considered valid
   * up to this point.
   *
   * @param {object} jwt
   *   The JWT that was parsed from the request.
   *
   * @returns {(boolean|{filesystem: IFilesystem})}
   *   The parameters to apply to the client's new session; or, false if the
   *   JWT is missing required information to start a session.
   */
  validateJwtAndInitializeSession(jwt) {
    let sessionInfo = false;

    if (jwt.authorized_paths) {
      const filesystem =
        new FilteredFilesystem(
          this._sessionInfo.virtualRoot,
          jwt.authorized_paths
        );

      this._log.info("User authenticated: %s", JSON.stringify(jwt));

      // Use this filesystem to provide a filtered/scoped view for the
      // current session.
      sessionInfo = {filesystem};
    } else {
      this._log.error(
        "Valid JWT presented without 'authorized_paths' claim: %s",
        JSON.stringify(jwt)
      );
    }

    return sessionInfo;
  }

  /**
   * Converts a value that may be a string or RegExp to a RegExp.
   *
   * @param {(string|RegExp)} stringOrRegex
   *   The value to convert.
   *
   * @returns {RegExp}
   *   The resulting regular expression.
   */
  convertToRegex(stringOrRegex) {
    let regex;

    if (stringOrRegex instanceof RegExp) {
      regex = stringOrRegex;
    }
    else {
      regex = new RegExp(stringOrRegex);
    }

    return regex;
  }
}

module.exports = JwtScopedSftpServer;
