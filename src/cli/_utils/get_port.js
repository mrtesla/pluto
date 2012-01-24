var Utils = require('../../api/utils')
,   L     = require('../../logger')
;

exports.run = function(){
  if (arguments.length != 0) {
    help(arguments);
  }

  Utils.get_port(function(ok, port){
    if (ok) {
      process.stdout.write('' + port + "\n");
    } else {
      process.exit(1);
    }
  });
};

function help(args){
  L.error("Invalid aguments: ", arguments);
  L.help("Usage: pluto utils get-port");
  L.help("       pluto help utils get-port");
  process.exit(1);
}
