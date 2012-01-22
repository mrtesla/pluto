var Fs    = require('fs-ext')
,   Path  = require('path')
,   Spawn = require('child_process').spawn
,   C     = require('../../config')
,   L     = require('../../logger')
,   Service = require('../services')._Service;
;

Service.prototype.is_up = function(){
  var state
  ;

  if (this._is_up === undefined) {
    if (this.is_supervised()) {
      state = Path.join(this.pluto_path(), 'supervise', 'stat');
      try { state = Fs.readFileSync(state, 'utf8').trim(); } catch(e) { state = null };
      if (state === 'run') {
        this._is_up = true;
      } else {
        this._is_up = false;
      }
    } else {
      this._is_up = false;
    }
  }

  return this._is_up;
};

Service.prototype.up = function(callback){
  var ok   = true
  ,   self = this
  ,   srv
  ;

  if (this.is_absent()) {
    L.error(this.name(), 'is not installed.');
    ok = false;
  }

  if (this.is_unlinked()) {
    L.error(this.name(), 'is not linked.');
    ok = false;
  }

  if (this.is_unsupervised()) {
    L.error(this.name(), 'is not supervised.');
    ok = false;
  }

  if (!ok) {
    callback(false);
    return;
  }

  if (this.is_up()) {
    L.notice(this.name(), 'is already up.');
    callback(true);
    return;
  }

  try { Fs.unlinkSync(Path.join(service.pluto_path(), 'down')); } catch(e) {};

  process.env['SVDIR'] = C.get('runit:dir');
  srv = Spawn('sv', ['-v', 'up', this.fs_name()]);

  srv.stdin.end();
  srv.stderr.pipe(process.stderr);
  srv.stdout.pipe(process.stdout);

  srv.on('exit', function (code) {
    if (code === 0) {
      L.info(self.name(), 'is up and running.');
      callback(true);
    } else {
      L.error(self.name(), 'failed to come up.');
      callback(false);
    }
  });
};
