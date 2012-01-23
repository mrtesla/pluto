var Service = require('../services')._Service
,   Path    = require('path')
,   Fs      = require('fs')
;

Service.prototype.task = function(){
  if (this._task === undefined) {
    var task
    ,   path
    ;

    try {
      path = Path.join(this.pluto_path(), 'task_out.json');
      task = JSON.parse(Fs.readFileSync(path));
    } catch(e) {
      task = null;
    }

    this._task = task;
  }

  return this._task;
};

Service.prototype.original_task = function(){
  if (this._original_task === undefined) {
    var task
    ,   path
    ;

    try {
      path = Path.join(this.pluto_path(), 'task_in.json');
      task = JSON.parse(Fs.readFileSync(path));
    } catch(e) {
      task = null;
    }

    this._original_task = task;
  }

  return this._original_task;
};
