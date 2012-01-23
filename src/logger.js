var Winston = require('winston')
,   TTY     = require('tty')
,   logger
;

logger = new (Winston.Logger)({
  transports: [
    new (Winston.transports.Console)()
  ]
});

if (TTY.isatty(1)) {
  logger.cli();
}

module.exports = logger;
