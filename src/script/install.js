var Handlebars = require('handlebars')
,   Config     = require('../config')
,   Path       = require('path')
,   Fs         = require('fs')
;

Handlebars.Utils.escapeExpression = function(string){
  if (string == null || string === false) {
    return "";
  } else {
    return string;
  }
};

Handlebars.registerHelper('quote', function(text) {
  return '' + JSON.stringify(text);
});

var _read_task
;

_read_task = function(callback){
  buffer = "";

  process.stdin.resume();
  process.stdin.setEncoding('utf8');

  process.stdin.on('data', function (chunk) {
    buffer += chunk;
  });

  process.stdin.on('end', function () {
    callback(JSON.parse(buffer));
  });
};

_read_task(function(task){
  var src
  ,   srv
  ,   original_task
  ;

  original_task = JSON.stringify(task, null, '  ');

  task.pluto_root         = process.cwd();
  task.pluto_prefix       = Fs.realpathSync(__dirname + '/../..');
  task.pluto_node_version = process.version;
  task.pluto_logger       = Config.get('syslog');
  task.user               = task.user || Config.get('user:default');
  task.user_separation    = Config.get('user:separation');

  srv = Path.join(task.pluto_root, 'services', task.task.replace(/:/g, '.'));
  if (Path.existsSync(srv)) {
    process.stderr.write('[ERR] Task already exists: '+task.task);
    process.exit(1);
  }

  Fs.mkdirSync(srv, 0755);
  Fs.mkdirSync(Path.join(srv, 'log'), 0755);
  Fs.mkdirSync(Path.join(srv, 'log', 'main'), 0755);

  Fs.writeFileSync(Path.join(srv, 'task.json'), original_task);

  src = Fs.readFileSync(__dirname + '/../../templates/run_process.mu', 'utf8');
  tpl = Handlebars.compile(src);
  dst = tpl(task);
  Fs.writeFileSync(Path.join(srv, 'run'), dst);
  Fs.chmodSync(Path.join(srv, 'run'), 0755);

  src = Fs.readFileSync(__dirname + '/../../templates/finish_process.mu', 'utf8');
  tpl = Handlebars.compile(src);
  dst = tpl(task);
  Fs.writeFileSync(Path.join(srv, 'finish'), dst);
  Fs.chmodSync(Path.join(srv, 'finish'), 0755);

  src = Fs.readFileSync(__dirname + '/../../templates/run_logger.mu', 'utf8');
  tpl = Handlebars.compile(src);
  dst = tpl(task);
  Fs.writeFileSync(Path.join(srv, 'log', 'run'), dst);
  Fs.chmodSync(Path.join(srv, 'log', 'run'), 0755);

  src = Fs.readFileSync(__dirname + '/../../templates/config_logger.mu', 'utf8');
  tpl = Handlebars.compile(src);
  dst = tpl(task);
  Fs.writeFileSync(Path.join(srv, 'log', 'main', 'config'), dst);
});
