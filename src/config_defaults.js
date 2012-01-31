var Path = require('path')
,   Fs   = require('fs')
;

exports.overrides =
  { 'dir'          : process.cwd()
  , 'services_dir' : Path.join(process.cwd(), 'services')
  , 'prefix'       : Fs.realpathSync(__dirname + '/..')
  , 'node_version' : process.version
  };

exports.defaults =
  { 'user':
    { 'separation' : true
    , 'default'    : 'pluto'
    }

  , 'runit' :
    { 'dir': '/etc/service'
    }

  , 'syslog':
    { 'host'     : '127.0.0.1'
    , 'port'     : 514
    }

  , 'hooks':
    { 'starting'   : []
    , 'terminated' : []
    }
  };
