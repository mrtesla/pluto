var Fs    = require('fs-ext')
,   Path  = require('path')
,   L     = require('../../logger')
,   Service = require('../services')._Service;
;

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

Service.prototype.supervise = function(callback){
  var ok   = true
  ,   self = this
  ;

  if (this.is_absent()) {
    L.error(this.name(), 'is not installed.');
    ok = false;
  }

  if (this.is_unlinked()) {
    L.error(this.name(), 'is not linked.');
    ok = false;
  }

  if (!ok) {
    callback(false);
    return;
  }

  if (this.is_supervised()) {
    L.notice(this.name(), 'is already supervised.');
    callback(true);
    return;
  }

  setTimeout(check, 1000);

  function check(){
    self.reset();
    if (self.is_supervised()) {
      L.info(self.name(), 'is supervised.');
      callback(true);
    } else {
      setTimeout(check, 1000);
    }
  };
};
