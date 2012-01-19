var Optimist = require('optimist')
,   C        = require('../config')
,   Path     = require('path')
,   Fs       = require('fs-ext')
;

var task
,   pluto_root
,   runit_root
,   srv
;

if (Optimist.argv._.length != 1) {
  process.stderr.write("[ERR] Missing argument: <task>\n");
  process.exit(1);
}

task       = Optimist.argv._[0];
pluto_srv  = Path.join(C.get('pluto:dir'), 'services', task.replace(/:/g, '.'));
runit_srv  = Path.join(C.get('runit:dir'), task.replace(/:/g, '.'));

if (!Path.existsSync(pluto_srv)) {
  process.stderr.write("[ERR] No such task: "+task+"\n");
  process.exit(1);
}

if (Path.existsSync(runit_srv)) {
  process.stderr.write("[ERR] Already linked task: "+task+"\n");
  process.exit(1);
}

Fs.symlinkSync(pluto_srv, runit_srv, 'dir');
wait_for_runsv();

function wait_for_runsv(){
  var lock
  ;

  lock = Path.join(runit_srv, 'supervise', 'lock');
  lock = Fs.openSync(lock, 'r+');

  Fs.flock(lock, 'exnb', function(err){
    if (err) {
      Fs.closeSync(lock);
      process.exit(0);
    } else {
      Fs.closeSync(lock);
      setTimeout(wait_for_runsv, 1000);
    }
  });
}
