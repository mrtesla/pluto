var Services = require('../../api/services')
,   L        = require('../../logger')
;

exports.run = function(service){
  var task
  ,   ports
  ;

  if (arguments.length != 1) {
    L.error("Invalid service: ", arguments);
    help(arguments);
  }

  service = Services.get(service);

  if (!service) {
    L.error("Invalid service: ", arguments);
    help(arguments);
  }

  task = service.task();

  if (!task) {
    L.error(service.name(), 'failed to load task!');
    help(arguments);
  }

  ports = {};
  task.ports.forEach(function(port){
    ports[port.name] = process.env[port.name] || null;
    if (ports[port.name]) { ports[port.name] = parseInt(ports[port.name], 10); }
  });

  service.save_ports(ports);
};

function help(args){
  L.help("Usage: pluto utils dump-ports <service>");
  L.help("       pluto help utils dump-ports");
  process.exit(1);
}
