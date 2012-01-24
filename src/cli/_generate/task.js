var L     = require('../../logger')
,   Tasks = require('../../api/tasks')
;

exports.run = function(command){
  if (arguments.length != 1) {
    L.error("Invalid arguments: ", arguments);
    help(arguments);
  }

  Tasks.generate(command, function(ok, task){
    if (ok) {
      process.stdout.write(task + "\n");
    } else {
      help(arguments);
    }
  });
};

function help(args){
  L.help("Usage: pluto generate task <options> <command>");
  L.help("       pluto help generate task");
  L.help("Note:  <command> must be passed as a single argument.");
  process.exit(1);
}
