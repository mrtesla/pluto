var Optimist = require('optimist')
,   C        = require('../../config')
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
pluto_srv  = Path.join(C.get('pluto:dir'), 'services', task.replace(/:/g, '.'));
runit_srv  = Path.join(C.get('runit:dir'), task.replace(/:/g, '.'));

if (!Path.existsSync(pluto_srv)) {
  process.stderr.write("[ERR] No such task: "+task+"\n");
  process.exit(1);
}

if (Path.existsSync(runit_srv)) {
  process.stderr.write("[ERR] Still linked task: "+task+"\n");
  process.exit(1);
}

srv = Spawn('rm', ['-rf', pluto_srv]);

srv.stdin.end();
srv.stderr.pipe(process.stderr);
srv.stdout.pipe(process.stdout);

srv.on('exit', function (code) {
  process.exit(code);
});

