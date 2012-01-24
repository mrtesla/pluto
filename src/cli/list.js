var L   = require('../logger')
,   S   = require('../api/services')
,   F   = require('futures')
,   TTY = require('tty')
;

exports.run = function(filter){
  var services
  ;

  if (arguments.length > 1) {
    help(arguments);
  }

  filter = filter || 'all';

  filter = ({
    'all'        : function(s){ return true; },
    'linked'     : function(s){ return s.is_linked(); },
    'supervised' : function(s){ return s.is_supervised(); },
    'up'         : function(s){ return s.is_up(); },
    'down'       : function(s){ return s.is_down(); }
  })[filter];

  if (!filter) {
    help(arguments);
  }

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
};

function help(args){
  L.error("Invalid filter: ", args);
  L.help("Usage: pluto list [all|linked|supervised|up|down]");
  L.help("       pluto help list");
  process.exit(1);
}
