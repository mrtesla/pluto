var L   = require('../logger')
,   S   = require('../api/services')
,   F   = require('futures')
,   TTY = require('tty')
;


var filters
;

filters = {
  'all'        : function(s){ return true; },
  'linked'     : function(s){ return s.is_linked(); },
  'supervised' : function(s){ return s.is_supervised(); },
  'up'         : function(s){ return s.is_up(); },
  'down'       : function(s){ return s.is_down(); }
};

exports.run = function(){
  var services
  ,   filter
  ,   patterns
  ;

  patterns = Array.prototype.slice.call(arguments, 1);

  filter = arguments[0];
  filter = filter || 'all';
  filter = filters[filter];

  if (!filter) {
    filter = filters['all'];
    patterns.unshift(arguments[0]);
  }

  services = S.find(patterns);
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
