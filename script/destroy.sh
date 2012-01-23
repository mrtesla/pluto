#!/usr/bin/env bash

[[ "x" != "x$ORIGINAL_PWD" ]] || export ORIGINAL_PWD=$(pwd)
PROG=$0
NAME=$(basename $0)
LINK=$(readlink $0)
PREFIX=$(cd $(dirname $PROG) ; cd ../.. ; pwd)
PLUTO=$(cd $(dirname $PROG)  ; cd $(dirname $LINK)  ; cd .. ; pwd)

[[ -f /usr/local/nvm/nvm.sh ]] && NVM_BOOT=/usr/local/nvm/nvm.sh
[[ -f $HOME/.nvm/nvm.sh     ]] && NVM_BOOT=$HOME/.nvm/nvm.sh
[[ "x" != "x$NVM_BOOT"      ]] && . $NVM_BOOT
nvm use $(cat $PLUTO/NODE_VERSION) 1>/dev/null

cd $PREFIX
exec node $PLUTO/src/script/destroy/$NAME.js "$@"
