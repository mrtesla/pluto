var Fs    = require('fs-ext')
,   Path  = require('path')
,   Spawn = require('child_process').spawn
,   C     = require('../../config')
,   L     = require('../../logger')
,   Service = require('../services')._Service;
;

Service.prototype.is_down = function(){
  return !this.is_up();
};
