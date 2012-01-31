var nconf  = require('nconf')
,   Fs     = require('fs')
,   Path   = require('path')
,   Config = require('./config_defaults')
;

nconf.overrides(
  { 'pluto' : Config.overrides
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
  { 'pluto':   Config.defaults
  , 'verbose': false
  });

module.exports = nconf;
