var nconf = require('nconf')
,   Fs    = require('fs')
;

nconf.overrides(
  { 'pluto' :
    { 'dir'    : process.cwd()
    , 'prefix' : Fs.realpathSync(__dirname + '/..')
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

});

module.exports = nconf;
