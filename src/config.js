var nconf = require('nconf')
,   Fs    = require('fs')
,   Path  = require('path')
;

nconf.overrides(
  { 'pluto' :
    { 'dir'          : process.cwd()
    , 'services_dir' : Path.join(process.cwd(), 'services')
    , 'prefix'       : Fs.realpathSync(__dirname + '/..')
    , 'node_version' : process.version
    }
});

//
// 2. `process.env`
// 3. `process.argv`
//
nconf.env();
nconf.argv();

//
// 4. Values in `config.json`
//
nconf.file({ file: 'config.json' });

//
// 5. Any default values
//
nconf.defaults(
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

});

module.exports = nconf;
