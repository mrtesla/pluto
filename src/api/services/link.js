var Fs      = require('fs-ext')
,   Path    = require('path')
,   L       = require('../../logger')
,   Service = require('../services')._Service;
;

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

Service.prototype.link = function(callback){
  var ok = true
  ;

  if (this.is_absent()) {
    L.error(this.name(), 'is not installed.');
    ok = false;
  }

  if (!ok) {
    callback(false);
    return;
  }

  if (this.is_linked()) {
    L.warn(this.name(), 'is already linked.');
    callback(true);
    return;
  }

  try {
    Fs.writeFileSync(Path.join(this.pluto_path(), 'down'), '');
    Fs.symlinkSync(this.pluto_path(), this.runit_path(), 'dir');
    L.info(this.name(), 'is linked.');
    callback(true);
  } catch(e) {
    L.error(this.name(), 'failed to link.');
    L.error(e);
    callback(false);
  }
};
