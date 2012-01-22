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

Service.prototype.is_supervised = function(){
  var lock
  ;

  if (this._is_supervised === undefined) {
    if (this.is_linked()) {
      lock = Path.join(this.pluto_path(), 'supervise', 'lock');

      try {
        lock = Fs.openSync(lock, 'r+');
        Fs.flockSync(lock, 'exnb')
        this._is_supervised = false;
      } catch(e) {
        this._is_supervised = true;
      }

      try { Fs.closeSync(lock); } catch(e) {};
    } else {
      this._is_supervised = false;
    }
  }

  return this._is_supervised;
};

Service.prototype.is_unsupervised = function(){
  return !this.is_supervised();
};

Service.prototype.is_linked = function(){
  var stat
  ,   path
  ;

  if (this._is_linked === undefined) {
    if (this.is_present()) {
      try { stat = Fs.lstatSync(this.runit_path()); } catch(e) {};
      if (stat && stat.isSymbolicLink()) {
        try { path = Fs.readlinkSync(this.runit_path()); } catch(e) {};
        if (path && path == this.pluto_path()) {
          this._is_linked = true;
        } else {
          this._is_linked = false;
        }
      } else {
        this._is_linked = false;
      }
    } else {
      this._is_linked = false;
    }
  }

  return this._is_linked;
};

Service.prototype.is_unlinked = function(){
  return !this.is_linked();
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

require('./services/up');
require('./services/down');
