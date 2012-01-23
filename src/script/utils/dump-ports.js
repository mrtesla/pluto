var Optimist = require('optimist')
,   Services = require('../../api/services')
,   L        = require('../../logger')
;

var service
,   task
,   ports
;

service = Services.get(Optimist.argv._[0]);

if (!service) {
  L.error(Optimist.argv._[0], 'missing');
  process.exit(1);
}

task = service.task();

if (!task) {
  L.error(service.name(), 'failed to load task!');
  process.exit(1);
}

ports = {};
task.ports.forEach(function(port){
  ports[port.name] = process.env[port.name] || null;
  if (ports[port.name]) { ports[port.name] = parseInt(ports[port.name], 10); }
});

service.save_ports(ports);
