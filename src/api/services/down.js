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

Service.prototype.down = function(callback){
  var ok   = true
  ,   self = this
  ,   srv
  ;

  if (this.is_absent()) {
    L.error(this.name(), 'is not installed.');
    ok = false;
  }

  if (!ok) {
    callback(false);
    return;
  }

  if (this.is_down()) {
    L.warn(this.name(), 'is already down.');
    callback(true);
    return;
  }

  try {
    Fs.writeFileSync(Path.join(this.pluto_path(), 'down'), '');
  } catch(e) {
    L.error(this.name(), 'failed to go down.');
    L.error(e);
    callback(false);
    return;
  }

  process.env['SVDIR'] = C.get('pluto:runit:dir');
  srv = Spawn('sv', ['-v', 'down', this.fs_name()]);

  srv.stdin.end();
  if (C.get('verbose')) {
    srv.stderr.pipe(process.stderr);
    srv.stdout.pipe(process.stdout);
  }

  srv.on('exit', function (code) {
    if (code === 0) {
      L.info(self.name(), 'went down.');
      callback(true);
    } else {
      L.error(self.name(), 'failed to go down.');
      callback(false);
    }
  });
};
