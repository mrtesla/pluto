#!/usr/bin/env bash

export ORIGINAL_PWD=$(pwd)
PROG=$0
LINK=$(readlink $0)
PREFIX=$(cd $(dirname $PROG) ; cd .. ; pwd)
PLUTO=$(cd $(dirname $PROG)  ; cd $(dirname $LINK)  ; cd .. ; pwd)

cd $PREFIX
exec node $PLUTO/src/script/task.js "$@"
