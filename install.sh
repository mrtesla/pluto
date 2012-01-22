#!/usr/bin/env bash

[[ "x" != "x$PREFIX"  ]] || PREFIX=/var/u
[[ "x" != "x$VERSION" ]] || VERSION=master

PLUTO_VERSION=$VERSION

if [[ "x" != "x$DEV_PREFIX" ]]
then
  echo "Installing Pluto ($DEV_PREFIX)"
else
  echo "Installing Pluto ($VERSION)"
fi

echo "root: $PREFIX"

[[ -f /usr/local/nvm/nvm.sh ]] && NVM_BOOT=/usr/local/nvm/nvm.sh
[[ -f $HOME/.nvm/nvm.sh     ]] && NVM_BOOT=$HOME/.nvm/nvm.sh

if [[ "x" != "x$NVM_BOOT" ]]
then
  NODE_VERSION=v0.6.8
  . $NVM_BOOT
  nvm use $NODE_VERSION 1>/dev/null
  echo "node: $NODE_VERSION"
fi

mkdir -p                  \
  $PREFIX                 \
  $PREFIX/services        \
  $PREFIX/script          \
  $PREFIX/script/generate \
  $PREFIX/script/destroy  \
  $PREFIX/script/hooks    \
  $PREFIX/script/utils

cd $PREFIX

rm -rf node_modules

if [[ "x" != "x$DEV_PREFIX" ]]
then
  npm install $DEV_PREFIX
else
  npm install git://github.com/mrtesla/pluto.git#$PLUTO_VERSION
fi

find script -type l | xargs rm
ln -s ../node_modules/pluto/script/start.sh       script/start
ln -s ../node_modules/pluto/script/stop.sh        script/stop

ln -s ../node_modules/pluto/script/run.sh         script/link
ln -s ../node_modules/pluto/script/run.sh         script/unlink

ln -s ../node_modules/pluto/script/run.sh         script/up
ln -s ../node_modules/pluto/script/run.sh         script/down
ln -s ../node_modules/pluto/script/restart.sh     script/restart
ln -s ../node_modules/pluto/script/run.sh         script/status

ln -s ../../node_modules/pluto/script/generate.sh script/generate/task
ln -s ../../node_modules/pluto/script/generate.sh script/generate/service

ln -s ../../node_modules/pluto/script/destroy.sh  script/destroy/service

ln -s ../../node_modules/pluto/script/utils.sh    script/utils/get-port

ln -s ../../node_modules/pluto/script/hooks.sh    script/hooks/starting
ln -s ../../node_modules/pluto/script/hooks.sh    script/hooks/terminated
find script -type l | xargs chmod a+x