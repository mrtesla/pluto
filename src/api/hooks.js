var C     = require('../config')
,   L     = require('../logger')
,   Spawn = require('child_process').spawn
,   F     = require('futures')
;


exports.run = function(service, name, callback){
  var hooks
  ;

  hooks = C.get('pluto:hooks:'+name);
  hooks = hooks || [];

  F.forEachAsync(hooks, function(next, hook){
    var module
    ,   func
    ;

    if (typeof hook === 'string') {
      hook = ['_sh', hook];
    }

    if (hook[0] === '_sh'){
      hook.shift();
      hook = ['pluto/src/api/hooks', 'sh'].concat(hook);
    }

    if (hook.length < 2) {
      L.error('     invalid hook: ' + JSON.stringify(hook));
      callback(false);
      return;
    }

    try {
      module = require(hook[0]);
    } catch(e) {
      L.error('     invalid hook: ' + e.message);
      callback(false);
      return;
    }

    func = module[hook[1]];

    if (typeof func !== 'function') {
      L.error('     invalid hook: ' + JSON.stringify(hook));
      callback(false);
      return;
    }

    clb = function(ok, reason){
      if (ok) {
        next();
      } else {
        if (reason) {
          L.error('     hook failed: '+reason);
        } else {
          L.error('     hook failed for no reason!');
        }
        callback(false);
      }
    };

    func.apply({}, [clb, service].concat(hook.slice(2)));
  });
};


exports.sh = function(callback, service){
  var proc
  ;

  command = Array.prototype.slice.call(arguments, 2);

  proc = Spawn('sh', ['-c'].concat(command));
  proc.stdin.end();
  proc.stdout.pipe(process.stdout);
  proc.stderr.pipe(process.stderr);
  proc.on('exit', function(code){
    if (code !== 0) {
      callback(false, ''+code);
    } else {
      callback(true);
    }
  });
};
