var Optimist = require('optimist')
,   C        = require('../../config')
,   L        = require('../../logger')
;

exports.generate = function(command, callback){
  var task
  ;

  task =
    { "task"    : null
    , "user"    : C.get('user:default')
    , "root"    : process.env['ORIGINAL_PWD']
    , "command" : command
    , "env"     : []
    , "ports"   : []
  };

  delete Optimist.argv['_'];
  delete Optimist.argv['$0'];

  if (typeof Optimist.argv.task === 'string') {
    task['task'] = Optimist.argv.task;
    delete Optimist.argv['task'];
  }

  if (typeof Optimist.argv.user === 'string') {
    task['user'] = Optimist.argv.user;
    delete Optimist.argv['user'];
  }

  if (typeof Optimist.argv.root === 'string') {
    task['root'] = Optimist.argv.root;
    delete Optimist.argv['root'];
  }

  if (!task.task) {
    L.error("Missing argument: --task <name>");
    callback(false);
    return;
  }

  if (!task.user) {
    L.error("Missing argument: --user <name>");
    callback(false);
    return;
  }

  if (!task.root) {
    L.error("Missing argument: --root <path>");
    callback(false);
    return;
  }

  var matches
  ;

  matches = task.command.match(/[$]([A-Z0-9_]+_)?PORT\b/g) || [];
  matches.forEach(function(m){
    var name
    ,   type
    ,   port
    ;

    name = m.replace(/[^A-Z0-9_]+/g, '');
    type = name.replace(/_PORT$/, '').toLowerCase();

    if (type == 'port' || type == '') {
      type = 'http';
    }

    if (Optimist.argv[name] !== undefined) {
      port = parseInt(''+Optimist.argv[name], 10);
      delete Optimist.argv[name];
    }

    task.ports.push({ name: name, type: type, port: port });
  });

  Object.keys(Optimist.argv).forEach(function(name){
    task.env.push({ name: name, value: Optimist.argv[name] });
  });

  callback(true, JSON.stringify(task, null, "  "));
};

function _eshell(cmd){
  if (/^[a-zA-Z0-9\/_.-]+$/.test(cmd)) {
    return cmd;
  } else {
    return JSON.stringify(cmd.replace(/([$"`\\])/g,'\\$1'));
  }
}
