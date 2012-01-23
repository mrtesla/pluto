var Net = require('net')
,   L   = require('../../logger')
;

exports.get_port = function(callback){
  var server
  ,   address
  ;

  server = Net.createServer();

  server.on('listening', function(){
    address = server.address();
    server.close();

    callback(true, address.port);
  });

  server.on('error', function (e) {
    server.close();

    L.error('Failed to grab ephemeral port.');
    L.error(e);

    callback(false);
  });

  server.listen(0);
};
