var L     = require('../../logger')
,   S     = require('../../api/services')
;

exports.run = function(command){
  if (arguments.length > 0) {
    help(arguments);
  }

  read_task(function(task){
    S.generate(task, function(ok){
      process.exit(ok ? 0 : 1);
    });
  });
};

function help(args){
  L.error("Invalid arguments: ", args);
  L.help("Usage: pluto generate service");
  L.help("       pluto help generate service");
  process.exit(1);
}

function read_task(callback){
  var buffer
  ;

  buffer = "";

  process.stdin.resume();
  process.stdin.setEncoding('utf8');

  process.stdin.on('data', function (chunk) {
    buffer += chunk;
  });

  process.stdin.on('end', function () {
    callback(JSON.parse(buffer));
  });
}
