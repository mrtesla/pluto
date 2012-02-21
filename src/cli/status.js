var L        = require('../logger')
,   S        = require('../api/services')
;

exports.run = function(){
  if (arguments.length != 1) {
    help(args);
  }

  var service
  ;

  service = S.get(arguments[0]);

  if (service && service.is_linked() && service.is_supervised() && service.is_up()) {
    process.exit(0);
  } else {
    process.exit(1);
  }
};

function help(args){
  L.error("Invalid service: ", args);
  L.help("Usage: pluto status <service>");
  L.help("       pluto help show");
  process.exit(1);
}
