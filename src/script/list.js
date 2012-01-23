var Optimist = require('optimist')
,   L        = require('../logger')
,   S        = require('../api/services')
,   F        = require('futures')
,   TTY      = require('tty')
;

var services
,   filter
;

if (Optimist.argv._.length > 1) {
  L.error("Invalid arguments: "+Optimist.argv._.join(' '));
  L.help("Usage: script/list [all|linked|supervised|up|down]");
  process.exit(1);
}

if (Optimist.argv._.length == 0) {
  Optimist.argv._.push('all');
}

filter = Optimist.argv._.shift();
filter = ({
  'all'        : function(s){ return true; },
  'linked'     : function(s){ return s.is_linked(); },
  'supervised' : function(s){ return s.is_supervised(); },
  'up'         : function(s){ return s.is_up(); },
  'down'       : function(s){ return s.is_down(); }
})[filter];

services = S.find('**');
F.forEachAsync(services, function(next, service){
  if (!filter(service)) {
    next();
    return;
  }

  if (TTY.isatty(1)) {
    if (service.is_up()) {
      process.stdout.write(service.name().green + "\n");
    } else {
      process.stdout.write(service.name().red + "\n");
    }
  } else {
    process.stdout.write(service.name() + "\n");
  }

  next();
});
