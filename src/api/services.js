var Fs    = require('fs-ext')
,   Path  = require('path')
,   Spawn = require('child_process').spawn
,   U     = require('util')
,   C     = require('../config')
,   L     = require('../logger')
;

var Service
,   uniqueArray
;

var services
,   index
;

uniqueArray = function(arr) {
  var o = {}, i, l = arr.length, r = [];
  for(i=0; i<l;i+=1) o[arr[i]] = arr[i];
  for(i in o) r.push(o[i]);
  return r;
};

exports.load = function(){
  var names
  ;

  services = {};
  index    = {};

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

exports.find = function(name){
  if (U.isArray(name)) {
    var services = []
    ;

    name.forEach(function(name){
      services = services.concat(exports.find(name));
    });

    return uniqueArray(services);
  } else if (name.indexOf('*') == -1){
    return exports.find_exact(name);
  } else {
    return exports.find_pattern(name);
  }
};

exports.find_exact = function(name){
  if (services === undefined) { exports.load(); }

  var service
  ;

  service = services[name];

  if (service) {
    return [service];
  } else {
    L.error(name, 'not found!');
    return [];
  }
};

exports.find_pattern = function(pattern){
  if (services === undefined) { exports.load(); }

  pattern = pattern.replace(/\./g, '\\.');
  pattern = pattern.replace(/\*\*/g, '.+');
  pattern = pattern.replace(/\*/g, '[^:]+');
  pattern = pattern.replace(/\?/g, '[^:]');

  pattern = new RegExp('^' + pattern + '$', 'i');

  return Object.keys(services).filter(function(name){
    return pattern.test(name);
  }).map(function(name){
    return services[name];
  });
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

require('./services/start');
require('./services/stop');
require('./services/restart');
