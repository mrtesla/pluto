var C     = require('../../config')
,   Spawn = require('child_process').spawn
;

var hooks = C.get('hooks:starting');
run_hook();

function run_hook(){
  if (hooks.length == 0) {
    process.exit(0);
  }

  var hook
  ,   proc
  ;

  hook = hooks.shift();

  process.stdout.write("   - "+hook+"\n");

  proc = Spawn('sh', ['-c', hook]);
  proc.stdin.end();
  proc.stdout.pipe(process.stdout);
  proc.stderr.pipe(process.stderr);
  proc.on('exit', function(code){
    if (code !== 0) {
      process.stderr.write("     hook failed: "+code+"\n");
      process.exit(1);
      return;
    }

    run_hook();
  });
}
