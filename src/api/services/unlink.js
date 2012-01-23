var Fs    = require('fs-ext')
,   L     = require('../../logger')
,   Service = require('../services')._Service;
;

Service.prototype.is_unlinked = function(){
  return !this.is_linked();
};

Service.prototype.unlink = function(callback){
  var ok = true
  ;

  if (this.is_absent()) {
    L.error(this.name(), 'is not installed.');
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

  if (this.is_unlinked()) {
    L.warn(this.name(), 'is already unlinked.');
    callback(true);
    return;
  }

  try {
    Fs.unlinkSync(this.runit_path());
    L.info(this.name(), 'is unlinked.');
    callback(true);
  } catch(e) {
    L.error(this.name(), 'failed to unlink.');
    L.error(e);
    callback(false);
  }
};
