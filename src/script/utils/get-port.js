var Utils = require('../../api/utils')
;

Utils.get_port(function(ok, port){
  if (ok) {
    process.stdout.write('' + port + "\n");
  } else {
    process.exit(1);
  }
});
