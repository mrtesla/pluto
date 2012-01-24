var L        = require('../../logger')
,   S        = require('../../api/services')
,   F        = require('futures')
;

exports.run = function(){
  var services
  ;

  if (arguments.length < 1) {
    help(arguments);
  }

  services = S.find(arguments);
  F.forEachAsync(services, function(next, service){
    service.destroy(function(ok){
      if (!ok) { process.exit(1) }
      next();
    });
  });
};

function help(args){
  L.error("Invalid service: ", args);
  L.help("Usage: pluto destroy service <service...>");
  L.help("       pluto help destroy service");
  process.exit(1);
}
