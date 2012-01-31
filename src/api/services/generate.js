var Handlebars = require('handlebars')
,   Path       = require('path')
,   Fs         = require('fs')
,   C          = require('../../config')
,   L          = require('../../logger')
,   Service    = require('../services')._Service
;

Service.prototype.generate = function(task, callback){
  var original_task
  ;

  if (this.is_present()) {
    L.error(this.name(), 'is already present');
    callback(false);
    return;
  }

  original_task = JSON.stringify(task, null, '  ');

  task.pluto_root         = C.get('pluto:dir');
  task.pluto_prefix       = C.get('pluto:prefix');
  task.pluto_node_version = C.get('pluto:node_version');
  task.pluto_logger       = C.get('pluto:syslog');
  task.user               = task.user || C.get('pluto:user:default');
  task.user_separation    = C.get('pluto:user:separation');

  task.env.push({ name: 'PLUTO_SERVICE', value: task.task });

  try {
    Fs.mkdirSync(this.pluto_path(), 0755);
    Fs.mkdirSync(Path.join(this.pluto_path(), 'log'), 0755);
    Fs.mkdirSync(Path.join(this.pluto_path(), 'log', 'main'), 0755);
    Fs.mkdirSync(Path.join(this.pluto_path(), 'supervise'), 0755);

    write(this, ['task_in.json'],      0644, original_task);
    write(this, ['task_out.json'],     0644, JSON.stringify(task, null, '  '));
    write(this, ['supervise', 'lock'], 0644, '');

    compile(this, 'run_process',    ['run'],                   0755, task);
    compile(this, 'finish_process', ['finish'],                0755, task);
    compile(this, 'run_logger',     ['log', 'run'],            0755, task);
    compile(this, 'config_logger',  ['log', 'main', 'config'], 0644, task);

    L.info(this.name(), "is generated.");
    callback(true);
  } catch(e) {
    L.error(this.name(), "Failed to generate.");
    L.error(e);
    this.destroy(function(){});
    callback(false);
  }
};

function compile(srv, src, dst, mode, task){
  var tpl
  ,   src
  ;

  src = Fs.readFileSync(Path.join(C.get('pluto:prefix'), 'templates', src+'.mu'), 'utf8');
  tpl = Handlebars.compile(src);
  str = tpl(task);

  write(srv, dst, mode, str);
}

function write(srv, dst, mode, content){
  dst = Path.join.apply(Path, [srv.pluto_path()].concat(dst));
  Fs.writeFileSync(dst, content);
  Fs.chmodSync(dst, mode);
}

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
