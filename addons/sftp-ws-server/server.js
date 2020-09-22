"use strict";

const express             = require('express');
const http                = require('http');
const {JsonWebTokenError} = require("jsonwebtoken");
const jwt                 = require('jsonwebtoken');
const url                 = require('url');
const util                = require('util');
const SFTP                = require("@inveniem/sftp-ws");

//==============================================================================
// Constants
//==============================================================================
// Specify host and port for the HTTP + SFTP server WebSocket endpoint.
const APP_HOSTNAME    = 'localhost';
const APP_PORT        = (process.env.SFTP_WS_PORT || 4002);
const APP_ENDPOINT    = '/sftp';
const JWT_HMAC_SECRET = process.env.JWT_HMAC_SECRET;

//==============================================================================
// Internal Functions
//==============================================================================
/**
 * Validates the origin of an incoming SFTP-WS connection request.
 *
 * @param {string} origin
 *   The 'Origin' header that was provided in the request.
 *
 * @returns {boolean}
 *   true if the origin is allowed; or, false, if it is not.
 */
function validateOrigin(origin) {
  let isAllowedOrigin = false;

  for (let originString of ALLOWED_ORIGIN_REGEXES) {
    let originRegex = new RegExp(originString);

    if (origin.match(originRegex)) {
      isAllowedOrigin = true;
      break;
    }
  }

  return isAllowedOrigin;
}

/**
 * Validates the JWT of an incoming SFTP-WS connection request.
 *
 * @param {string} origin
 *   The 'Origin' header that was provided in the request.
 * @param {string} token
 *   The JSON Web Token that was provided in the query-string of the request.
 *
 * @returns {boolean}
 *   true if the JWT grants access to this app; or, false, if it does not.
 */
function validateJwt(origin, token) {
  const appHost    = util.format('%s:%s', APP_HOSTNAME, APP_PORT);
  let   isValidJwt;

  if (!token) {
    return false;
  }

  try {
    // noinspection JSUnresolvedVariable
    jwt.verify(
      token,
      Buffer.from(JWT_HMAC_SECRET, 'base64'),
      {
        audience: appHost,
        issuer:   origin
      }
    );

    isValidJwt = true;
  }
  catch (ex) {
    if (ex instanceof JsonWebTokenError) {
      console.error("JWT validation failed (" + ex + ") - JWT: " + token);
    }
    else {
      throw ex;
    }
  }

  return isValidJwt;
}

/**
 * Verifies that a particular client should be allowed to connect to this app.
 *
 * @param {RequestInfo} requestInfo
 *   The incoming WebSocket connection request and header information.
 *
 * @returns {boolean}
 *   `true` if the client connection is allowed; or, `false`, if they should be
 *   refused.
 */
function authenticateClient(requestInfo) {
  const requestOrigin   = requestInfo.origin,
        isAllowedOrigin = validateOrigin(requestOrigin);
  let   isValidToken    = false;

  if (isAllowedOrigin) {
    const queryParams = url.parse(requestInfo.req.url, true).query,
          token       = queryParams.token;

    isValidToken = validateJwt(requestOrigin, token);
  }

  return isValidToken;
}

//==============================================================================
// Main Body
//==============================================================================
if (!JWT_HMAC_SECRET) {
  throw new Error('JWT_HMAC_SECRET must be provided in environment.');
}

const app = express();

// FIXME: For debug - serve static files from 'client' subfolder.
app.use(express.static(__dirname + '/client'));

// Specify what origins allowed to connect to this app via regular expressions.
//
// NOTE: Though "Origin" is not spoof-able in a browser, it is totally
// spoof-able via CLI tools.
const ALLOWED_ORIGIN_REGEXES =
  JSON.parse(process.env.ALLOWED_ORIGIN_REGEXES || '[]');

// Create an HTTP server to handle protocol switching.
const server = http.createServer(app);

// Start SFTP over WebSockets server.
const sftp = new SFTP.Server({
  server:       server,
  virtualRoot:  __dirname + '/files',
  path:         APP_ENDPOINT,
  verifyClient: authenticateClient,
  log:          console // log to console
});

// Start accepting requests.
server.listen(APP_PORT, APP_HOSTNAME, function () {
  const host = server.address().address;

  console.log('HTTP server listening at http://%s:%s', host, APP_PORT);
  console.log('WS-SFTP server listening at ws://%s:%s%s', host, APP_PORT, APP_ENDPOINT);
});
