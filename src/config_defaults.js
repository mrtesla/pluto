var Path = require('path')
,   Fs   = require('fs')
;

exports.overrides =
  { 'dir'          : (process.env['PLUTO_ROOT']          || process.cwd())
  , 'services_dir' : (process.env['PLUTO_SRV_AVAILABLE'] || Path.join(process.cwd(), 'services'))
  , 'prefix'       : Fs.realpathSync(__dirname + '/..')
  , 'node_version' : process.version.slice(1)
  };

exports.defaults =
  { 'user':
    { 'separation' : true
    , 'default'    : 'pluto'
    }

  , 'runit' :
    { 'dir': (process.env['PLUTO_SRV_ENABLED'] || '/etc/service')
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
