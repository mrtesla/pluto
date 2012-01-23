var Service = require('../services')._Service
,   Path    = require('path')
,   Fs      = require('fs')
;

Service.prototype.ports = function(){
  if (this._ports === undefined) {
    var ports
    ,   path
    ;

    try {
      path  = Path.join(this.pluto_path(), 'ports.json');
      ports = JSON.parse(Fs.readFileSync(path));
    } catch(e) {
      ports = [];
    }

    this._ports = ports;
  }

  return this._ports;
};

Service.prototype.save_ports = function(ports){
  this._ports = undefined;

  var path
  ;

  path  = Path.join(this.pluto_path(), 'ports.json');
  ports = JSON.stringify(ports, null, '  ');

  Fs.writeFileSync(path, ports);
};
