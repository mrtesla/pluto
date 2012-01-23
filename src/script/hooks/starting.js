var Optimist = require('optimist')
,   Services = require('../../api/services')
,   L        = require('../../logger')
,   H        = require('../../api/hooks')
;

var service
;

service = Services.get(Optimist.argv._[0]);

if (!service) {
  L.error(Optimist.argv._[0], 'missing');
  process.exit(1);
}

H.run(service, 'starting', function(ok){
  process.exit(ok ? 0 : 1);
});
