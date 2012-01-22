var L       = require('../../logger')
,   Service = require('../services')._Service;
;

Service.prototype.is_unsupervised = function(){
  return !this.is_supervised();
};

Service.prototype.unsupervise = function(callback){
  var ok   = true
  ,   self = this
  ;

  if (this.is_absent()) {
    L.error(this.name(), 'is not installed.');
    ok = false;
  }

  if (this.is_linked()) {
    L.error(this.name(), 'is still linked.');
    ok = false;
  }

  if (this.is_up()) {
    L.error(this.name(), 'is still up and running.');
    ok = false;
  }

  if (!ok) {
    callback(false);
    return;
  }

  if (this.is_unsupervised()) {
    L.notice(this.name(), 'is already unsupervised.');
    callback(true);
    return;
  }

  setTimeout(check, 1000);

  function check(){
    self.reset();
    if (self.is_unsupervised()) {
      L.info(self.name(), 'is unsupervised.');
      callback(true);
    } else {
      setTimeout(check, 1000);
    }
  };
};

