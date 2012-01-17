var Config   = require('./config')
,   Optimist = require('optimist')
;

Config.pluto_root = __dirname + '/..';

Optimist.default('root', '/var/u');

switch(Optimist.argv._.shift()) {
case 'start':
  require('./pluto/start').run(Optimist);
  break;

case 'restart':
  require('./pluto/restart').run(Optimist);
  break;

case 'stop':
  require('./pluto/stop').run(Optimist);
  break;

default:
  Optimist.showHelp();
  process.exit(1);
}
