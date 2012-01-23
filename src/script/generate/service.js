var Optimist = require('optimist')
,   L        = require('../../logger')
,   S        = require('../../api/services')
;

if (Optimist.argv._.length > 0) {
  L.error("Invalid arguments: "+Optimist.argv._.join(' '));
  L.help("Usage: script/service/generate");
  process.exit(1);
}

var _read_task
;

_read_task = function(callback){
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
};

_read_task(function(task){
  S.generate(task, function(ok){
    process.exit(ok ? 0 : 1);
  });
});
