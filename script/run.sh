#!/usr/bin/env bash

[[ "x" != "x$ORIGINAL_PWD" ]] || export ORIGINAL_PWD=$(pwd)
PROG=$0
NAME=$(basename $0)
LINK=$(readlink $0)
PREFIX=$(cd $(dirname $PROG) ; cd .. ; pwd)
PLUTO=$(cd $(dirname $PROG)  ; cd $(dirname $LINK)  ; cd .. ; pwd)

cd $PREFIX
exec node $PLUTO/src/script/$NAME.js "$@"
