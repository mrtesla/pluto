var Tasks = require('../../api/tasks')
;

Tasks.generate(function(ok, task){
  if (ok) {
    process.stdout.write(task + "\n");
  } else {
    process.exit(1);
  }
});
