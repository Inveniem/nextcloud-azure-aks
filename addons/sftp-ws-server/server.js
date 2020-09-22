"use strict";

const express             = require('express');
const http                = require('http');
const {JsonWebTokenError} = require("jsonwebtoken");
const jwt                 = require('jsonwebtoken');
const url                 = require('url');
const util                = require('util');
const SFTP                = require("@inveniem/sftp-ws");

const MultiIssuerJwtScopedSftpServer =
  require("./lib/MultiIssuerJwtScopedSftpServer");

//==============================================================================
// Constants
//==============================================================================
// Host and port for the HTTP + SFTP server WebSocket endpoint.
const APP_HOSTNAME    = 'localhost';
const APP_PORT        = (process.env.SFTP_WS_PORT || 4002);
const APP_HOST        = APP_HOSTNAME + ":" + APP_PORT;

// Resource for starting a SFTP-WS session.
const APP_ENDPOINT    = '/sftp';

// An array of arrays that gets converted into a Map from origins -> pub keys.
//
// Each origin is expected to be regular expression, and the pub key should be
// an RSA public key. For example:
//
// ```
// [
//   [
//     "https?:\/\/localhost:4002",
//     "-----BEGIN PUBLIC KEY-----\n" +
//     "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvosthErm4A7SUzpHCMOR\n" +
//     "koAnEzNK0NHPD0sM2Mw5xkcGOGvf6Rq5hUXHk4sQKWNGV/wSXnjj0/EYgqysxW7O\n" +
//     "JeGC9ZZRPVGil7OM/MdB17OO7bHeVIFud3UiAApyKt+EQpp0SvHnBWyPBfhEHAQa\n" +
//     "4mkGFSq9SFTuKNhW2wONPVRa5HvxHJYAi6xnqPGpIHl2xuu+utF316fNKY/gydIA\n" +
//     "CJsxjMfY15rh7ol/KXqV7XkMfHzVd0KoFHh72oZ9p0PXMA33Pxn+Yi/Is6vhNzXU\n" +
//     "PuemePhgtL8Ycbgz/9Eif1HFrQpk1DB5qczcyBVOTw6bmv/xBfmYnLz2uusYzmN2\n" +
//     "XwIDAQAB\n" +
//     "-----END PUBLIC KEY-----"
//   ],
//   [
//     "https?:\/\/example.com",
//     "-----BEGIN PUBLIC KEY-----\n" +
//     "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvosthErm4A7SUzpHCMOR\n" +
//     "koAnEzNK0NHPD0sM2Mw5xkcGOGvf6Rq5hUXHk4sQKWNGV/wSXnjj0/EYgqysxW7O\n" +
//     "JeGC9ZZRPVGil7OM/MdB17OO7bHeVIFud3UiAApyKt+EQpp0SvHnBWyPBfhEHAQa\n" +
//     "4mkGFSq9SFTuKNhW2wONPVRa5HvxHJYAi6xnqPGpIHl2xuu+utF316fNKY/gydIA\n" +
//     "CJsxjMfY15rh7ol/KXqV7XkMfHzVd0KoFHh72oZ9p0PXMA33Pxn+Yi/Is6vhNzXU\n" +
//     "PuemePhgtL8Ycbgz/9Eif1HFrQpk1DB5qczcyBVOTw6bmv/xBfmYnLz2uusYzmN2\n" +
//     "XwIDAQAB\n" +
//     "-----END PUBLIC KEY-----"
//   ],
// ]
// ```
//
const ORIGIN_JWT_RSA_PUB_KEYS =
  new Map(JSON.parse(process.env.ORIGIN_JWT_RSA_PUB_KEYS || '[]'));

//==============================================================================
// Main Body
//==============================================================================
if (ORIGIN_JWT_RSA_PUB_KEYS.length === 0) {
  throw new Error('ORIGIN_JWT_RSA_PUB_KEYS must be provided in environment.');
}

console.log("");
console.log("Allowed origin patterns:");

for (const [origin, pubKey] of ORIGIN_JWT_RSA_PUB_KEYS) {
  console.log(" - " + origin);
}
console.log("");

const app = express();

// FIXME: For debug - serve static files from 'client' subfolder.
app.use(express.static(__dirname + '/client'));

// Create an HTTP server to handle protocol switching.
const server = http.createServer(app);

// Start SFTP over WebSockets server.
const sftp = new MultiIssuerJwtScopedSftpServer(
  APP_HOST,
  ORIGIN_JWT_RSA_PUB_KEYS,
  {
  server:      server,
  virtualRoot: __dirname + '/files',
  path:        APP_ENDPOINT,
  log:         console // log to console
});

// Start accepting requests.
server.listen(APP_PORT, APP_HOSTNAME, function () {
  const host = server.address().address;

  console.log("");
  console.log('HTTP server listening at http://%s:%s', host, APP_PORT);
  console.log('WS-SFTP server listening at ws://%s:%s%s', host, APP_PORT, APP_ENDPOINT);
});
