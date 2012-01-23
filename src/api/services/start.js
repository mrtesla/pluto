var Service = require('../services')._Service
;

Service.prototype.start = function(callback){
  var self = this
  ;

  self.link(function(ok){
    if (!ok) {
      callback(false);
      return;
    }

    self.reset();
    self.supervise(function(ok){
      if (!ok) {
        callback(false);
        return;
      }

      self.reset();
      self.up(callback);
    });
  });
};
