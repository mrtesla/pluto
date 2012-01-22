var Optimist = require('optimist')
,   L        = require('../logger')
,   S        = require('../api/services')
;

var service
;

if (Optimist.argv._.length != 1) {
  L.error("Missing argument: <task>");
  process.exit(1);
}

service = S.get(Optimist.argv._[0]);

service.link(function(ok){
  if (!ok) { process.exit(1); }
  service.reset();
  service.supervise(function(ok){
    process.exit(ok ? 0 : 1);
  });
});
