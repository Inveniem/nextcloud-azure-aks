"use strict";

const express = require('express');
const http    = require('http');
const bunyan  = require('bunyan');

const MultiIssuerJwtScopedSftpServer =
  require("./lib/MultiIssuerJwtScopedSftpServer");

//==============================================================================
// Constants
//==============================================================================
// Level of log output to produce.
const LOG_LEVEL = (process.env.SFTP_WS_LOG_LEVEL || 'info')

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

const LOGGER =
  bunyan.createLogger({
    name:  'sftp-ws-server',
    level: LOG_LEVEL,
  });

//==============================================================================
// Main Body
//==============================================================================
if (ORIGIN_RESTRICTIONS.size === 0) {
  throw new Error(
    'SFTP_WS_ORIGIN_RESTRICTIONS must be provided in environment.'
  );
}

LOGGER.info('Allowed origins and paths:');

for (const [origin, restrictions] of ORIGIN_RESTRICTIONS) {
  LOGGER.info(' - %s: [%s]', origin, restrictions.allowed_paths.join(', '));
}
LOGGER.info('');

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
  log:         LOGGER,
});

// Start accepting requests.
server.listen(APP_PORT, APP_HOSTNAME, function () {
  const host = server.address().address;

  LOGGER.info('');
  LOGGER.info('HTTP server listening at http://%s:%s', host, APP_PORT);
  LOGGER.info('WS-SFTP server listening at ws://%s:%s%s', host, APP_PORT, APP_ENDPOINT);
  LOGGER.info('');
  LOGGER.info('Externally hosted on %s', APP_HOST);
});
