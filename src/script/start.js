var Optimist = require('optimist')
,   Config   = require('../config')
,   Path     = require('path')
,   Fs       = require('fs')
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
pluto_root = process.cwd();
runit_root = Config.get('runit:dir');
pluto_srv  = Path.join(pluto_root, 'services', task.replace(/:/g, '__'));
runit_srv  = Path.join(runit_root, task.replace(/:/g, '__'));

if (!Path.existsSync(pluto_srv)) {
  process.stderr.write("[ERR] No such task: "+task+"\n");
  process.exit(1);
}

if (Path.existsSync(runit_srv)) {
  process.stderr.write("[ERR] Already linked task: "+task+"\n");
  process.exit(1);
}

Fs.symlinkSync(pluto_srv, runit_srv, 'dir');
