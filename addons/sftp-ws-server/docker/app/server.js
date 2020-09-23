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
const APP_HOSTNAME = (process.env.SFTP_WS_HOST || 'localhost');
const APP_PORT     = (process.env.SFTP_WS_PORT || 4002);

const APP_HOST =
  (process.env.SFTP_WS_APP_HOST || (APP_HOSTNAME + ":" + APP_PORT));

// Resource for starting a SFTP-WS session.
const APP_ENDPOINT    = '/sftp';

// A map from origins -> restrictions.
//
// Each origin is expected to be regular expression. Restrictions must include
// a list of paths and a public key. The public key should be an RSA public key.
//
// See README.md.
//

const ORIGIN_RESTRICTIONS =
  new Map(
    Object.entries(
      JSON.parse(process.env.SFTP_WS_ORIGIN_RESTRICTIONS || '{}')
    )
  );

//==============================================================================
// Main Body
//==============================================================================
if (ORIGIN_RESTRICTIONS.size === 0) {
  throw new Error(
    'SFTP_WS_ORIGIN_RESTRICTIONS must be provided in environment.'
  );
}

console.log('');
console.log('Allowed origins and paths:');

for (const [origin, restrictions] of ORIGIN_RESTRICTIONS) {
  console.log(' - ' + origin + ': [' + restrictions.allowed_paths + ']');
}
console.log('');

const app = express();

// FIXME: For debug - serve static files from 'client' subfolder.
app.use(express.static(__dirname + '/client'));

// Create an HTTP server to handle protocol switching.
const server = http.createServer(app);

// Start SFTP over WebSockets server.
const sftp = new MultiIssuerJwtScopedSftpServer(
  APP_HOST,
  ORIGIN_RESTRICTIONS,
  {
  server:      server,
  virtualRoot: __dirname + '/files',
  path:        APP_ENDPOINT,
  log:         console // log to console
});

// Start accepting requests.
server.listen(APP_PORT, APP_HOSTNAME, function () {
  const host = server.address().address;

  console.log('');
  console.log('HTTP server listening at http://%s:%s', host, APP_PORT);
  console.log('WS-SFTP server listening at ws://%s:%s%s', host, APP_PORT, APP_ENDPOINT);
  console.log('');
  console.log('Externally hosted on %s', APP_HOST);
});
