var Net = require('net')
;

var server
,   address
;

server = Net.createServer();

server.on('listening', function(){
  address = server.address();
  server.close();

  process.stdout.write('' + address.port + "\n");
  process.exit(0);
});

server.on('error', function (e) {
  server.close();

  process.stderr.write("Failed to grab ephemeral port: " + e.message + "\n");
  porcess.exit(1);
});

server.listen(0);
