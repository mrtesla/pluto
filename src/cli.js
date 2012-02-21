var Optimist = require('optimist')
;

var commands
;

commands =
{ 'help'         : 'help'

, 'list'         : 'list'
, 'show'         : 'show'
, 'status'       : 'status'

, 'start'        : 'start'
, 'restart'      : 'restart'
, 'stop'         : 'stop'

, 'link'         : 'link'
, 'unlink'       : 'unlink'

, 'up'           : 'up'
, 'down'         : 'down'

, 'generate'     :
  { 'task'       : '_generate/task'
  , 'service'    : '_generate/service'
  }

, 'destroy'      :
  { 'service'    : '_destroy/service'
  }

, 'hooks'        :
  { 'starting'   : '_hooks/starting'
  , 'terminated' : '_hooks/terminated'
  }

, 'utils'        :
  { 'dump-ports' : '_utils/dump_ports'
  , 'get-port'   : '_utils/get_port'
  }

};

exports.run = function(){
  var context
  ,   command
  ,   arguments
  ,   index
  ;

  context = commands;

  for (index = 0; index < Optimist.argv._.length; index++) {
    command = context[Optimist.argv._[index]];

    if (typeof command == 'string') {
      arguments = Optimist.argv._.slice(index + 1);
      break;
    } else if (typeof command == 'object') {
      context = command;
    } else {
      L.error('Unknown command: ' + Optimist.argv._.slice(0, index + 1).join(' '));
      Optimist.argv._ = ['help'];
      index           = 0;
      context         = commands;
    }
  }

  command = command || 'help';

  require('./cli/'+command).run.apply(this, arguments);
};
