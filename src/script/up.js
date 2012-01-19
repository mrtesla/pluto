var Optimist = require('optimist')
,   Config   = require('../config')
,   Path     = require('path')
,   Fs       = require('fs')
,   Spawn    = require('child_process').spawn
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
pluto_srv  = Path.join(pluto_root, 'services', task.replace(/:/g, '.'));
runit_srv  = Path.join(runit_root, task.replace(/:/g, '.'));

if (!Path.existsSync(pluto_srv)) {
  process.stderr.write("[ERR] No such task: "+task+"\n");
  process.exit(1);
}

if (!Path.existsSync(runit_srv)) {
  process.stderr.write("[ERR] Already unlinked task: "+task+"\n");
  process.exit(1);
}



try { Fs.unlinkSync(Path.join(pluto_srv, 'down'), ''); } catch(e) {};



process.env['SVDIR'] = runit_root;
srv = Spawn('sv', ['-v', 'up', task.replace(/:/g, '.')]);

srv.stdin.end();
srv.stderr.pipe(process.stderr);
srv.stdout.pipe(process.stdout);

srv.on('exit', function (code) {
  process.exit(0);
});

