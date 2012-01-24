var L        = require('../logger')
,   S        = require('../api/services')
,   F        = require('futures')
;

exports.run = function(){
  var services
  ;

  if (arguments.length < 1) {
    help(args);
  }

  services = S.find(arguments);
  F.forEachAsync(services, function(next, service){
    service.link(function(ok){
      if (!ok) { process.exit(1); }
      service.reset();
      service.supervise(function(ok){
        if (!ok) { process.exit(1) }
        next();
      });
    });
  });
};

function help(args){
  L.error("Invalid service: ", args);
  L.help("Usage: pluto link <service...>");
  L.help("       pluto help link");
  process.exit(1);
}
