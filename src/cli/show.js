var L        = require('../logger')
,   S        = require('../api/services')
;

exports.run = function(){
  if (arguments.length < 1) {
    help(args);
  }

  S.find(arguments).forEach(function(service){
    var info = ""
    ;

    info += service.name() + "\n";
    info += "  " + (service.is_linked()     ? ('is linked.'.green)         : ('is not linked.'.yellow))  + "\n";
    info += "  " + (service.is_supervised() ? ('is supervised.'.green)     : ('is not supervised.'.red)) + "\n";
    info += "  " + (service.is_up()         ? ('is up and running.'.green) : ('is down.'.red))           + "\n";

    if (service.is_up()) {
      info   += "  ports:\n";
      service.task().ports.forEach(function(port){
        info += "    - " + port.name + "." + port.type + ": " + service.ports()[port.name] + "\n";
      });
    }

    process.stdout.write(info);
  });
};

function help(args){
  L.error("Invalid service: ", args);
  L.help("Usage: pluto show <service...>");
  L.help("       pluto help show");
  process.exit(1);
}
