var Optimist = require('optimist')
,   L        = require('../logger')
,   S        = require('../api/services')
,   F        = require('futures')
;

var services
;

if (Optimist.argv._.length < 1) {
  L.error("Missing argument: <task>");
  process.exit(1);
}

services = S.find(Optimist.argv._);
F.forEachAsync(services, function(next, service){
  service.stop(function(ok){
    if (!ok) { process.exit(1) }
    next();
  });
});
