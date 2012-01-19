var Optimist = require('optimist')
,   Config   = require('../../config')
;

var task
;

task =
  { "task":  null
  , "user":  Config.get('user:default')
  , "root":  process.env['ORIGINAL_PWD']
  , "command": Optimist.argv._.join(' ')
  , "env":   []
  , "ports": []
};

delete Optimist.argv['_'];
delete Optimist.argv['$0'];

if (typeof Optimist.argv.task === 'string') {
  task['task'] = Optimist.argv.task;
  delete Optimist.argv['task'];
} else {
  process.stderr.write("Missing parameter: --task\n");
  process.exit(1);
}

if (typeof Optimist.argv.user === 'string') {
  task['user'] = Optimist.argv.user;
  delete Optimist.argv['user'];
}

if (typeof Optimist.argv.root === 'string') {
  task['root'] = Optimist.argv.root;
  delete Optimist.argv['root'];
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

process.stdout.write(JSON.stringify(task, null, "  "));

function _eshell(cmd){
  if (/^[a-zA-Z0-9\/_.-]+$/.test(cmd)) {
    return cmd;
  } else {
    return JSON.stringify(cmd.replace(/([$"`\\])/g,'\\$1'));
  }
};
