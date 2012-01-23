var Service = require('../services')._Service
,   Spawn   = require('child_process').spawn
,   C       = require('../../config')
,   L       = require('../../logger')
;

Service.prototype.destroy = function(callback){
  var ok   = true
  ,   self = this
  ;

  if (this.is_linked()) {
    L.error(this.name(), "is still linked.");
    ok = false;
  }

  if (this.is_supervised()) {
    L.error(this.name(), "is still supervised.");
    ok = false;
  }

  if (!ok) {
    callback(false);
    return;
  }

  if (this.is_absent()) {
    L.warn(this.name(), 'is already destroyed.');
    callback(true);
    return;
  }

  srv = Spawn('rm', ['-rf', this.pluto_path()]);

  srv.stdin.end();
  if (C.get('verbose')) {
    srv.stderr.pipe(process.stderr);
    srv.stdout.pipe(process.stdout);
  }

  srv.on('exit', function (code) {
    if (code === 0) {
      L.info(self.name(), 'is destroyed.');
      callback(true);
    } else {
      L.error(self.name(), 'failed to be destroyed.');
      callback(false);
    }
  });
};
