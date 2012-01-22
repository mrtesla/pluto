var Optimist = require('optimist')
,   L        = require('../logger')
,   S        = require('../api/services')
,   C        = require('../config')
//,   Path     = require('path')
//,   Fs       = require('fs')
,   Spawn    = require('child_process').spawn
;

var service
;

if (Optimist.argv._.length != 1) {
  L.error("Missing argument: <task>");
  process.exit(1);
}

service = S.get(Optimist.argv._[0]);

service.up(function(ok){
  process.exit(ok ? 0 : 1);
});
