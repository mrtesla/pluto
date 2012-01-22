var Fs    = require('fs-ext')
,   Path  = require('path')
,   Spawn = require('child_process').spawn
,   C     = require('../config')
,   L     = require('../logger')
;

var Service
;

var services
;


exports.load = function(){
  var names
  ;

  services = {};

  names = Fs.readdirSync(C.get('pluto:services_dir'));

  names = names.filter(function(e){
    return Fs.statSync(Path.join(C.get('pluto:services_dir'), e)).isDirectory();
  });

  names.forEach(function(e){
    service = new Service(e.replace(/\./g, ':'));
    services[service.name()] = service;
  });
};

exports.get = function(name){
  if (services === undefined) { exports.load(); }
  return services[name];
};


exports._Service = Service = function(name){
  this._name = name;
};

Service.prototype.reset = function(){
  this._fs_name       = undefined;
  this._pluto_path    = undefined;
  this._runit_path    = undefined;

  this._is_supervised = undefined;
  this._is_up         = undefined;
  this._is_linked     = undefined;
  this._is_present    = undefined;
};

Service.prototype.name = function(){
  return this._name;
};

Service.prototype.fs_name = function(){
  if (this._fs_name === undefined) {
    this._fs_name = this.name().replace(/:/g, '.');
  }
  return this._fs_name;
};

Service.prototype.pluto_path = function(){
  if (this._pluto_path === undefined) {
    this._pluto_path = Path.join(C.get('pluto:services_dir'), this.fs_name());
  }
  return this._pluto_path;
};

Service.prototype.runit_path = function(){
  if (this._runit_path === undefined) {
    this._runit_path = Path.join(C.get('runit:dir'), this.fs_name());
  }
  return this._runit_path;
};

Service.prototype.is_present = function(){
  var stat
  ;

  if (this._is_present === undefined) {
    try { stat = Fs.statSync(this.pluto_path()); } catch(e) {};
    if (stat && stat.isDirectory()) {
      this._is_present = true;
    } else {
      this._is_present = false;
    }
  }

  return this._is_present;
};

Service.prototype.is_absent = function(){
  return !this.is_present();
};

require('./services/link');
require('./services/unlink');

require('./services/supervise');
require('./services/unsupervise');

require('./services/up');
require('./services/down');
