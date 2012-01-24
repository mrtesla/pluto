var Services = require('../../api/services')
,   H        = require('../../api/hooks')
,   L        = require('../../logger')
;

exports.run = function(service){
  if (arguments.length != 1) {
    L.error("Invalid service: ", arguments);
    help(arguments);
  }

  service = Services.get(service);

  if (!service) {
    L.error("Invalid service: ", arguments);
    help(arguments);
  }

  H.run(service, 'starting', function(ok){
    process.exit(ok ? 0 : 1);
  });
};

function help(args){
  L.help("Usage: pluto hooks starting <service>");
  L.help("       pluto help hooks starting");
  process.exit(1);
}
