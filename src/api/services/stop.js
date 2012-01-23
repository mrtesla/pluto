var Service = require('../services')._Service
;

Service.prototype.stop = function(callback){
  var self = this
  ;

  self.down(function(ok){
    if (!ok) {
      callback(false);
      return;
    }

    self.reset();
    self.unlink(function(ok){
      if (!ok) {
        callback(false);
        return;
      }

      self.reset();
      self.unsupervise(callback);
    });
  });
};
