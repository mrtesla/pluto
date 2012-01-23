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
  var info = ""
  ;

  info += service.name() + "\n";
  info += "  " + (service.is_linked()     ? ('is linked.'.green)         : ('is not linked.'.yellow))  + "\n";
  info += "  " + (service.is_supervised() ? ('is supervised.'.green)     : ('is not supervised.'.red)) + "\n";
  info += "  " + (service.is_up()         ? ('is up and running.'.green) : ('is down.'.red))           + "\n";

  process.stdout.write(info);
  next();
});
