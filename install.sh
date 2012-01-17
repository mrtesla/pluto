#!/usr/bin/env bash

[[ "x" != "x$PREFIX"  ]] || PREFIX=/var/u
[[ "x" != "x$VERSION" ]] || VERSION=master

PLUTO_VERSION=$VERSION
echo "Installing Pluto ($VERSION)"

echo "root: $PREFIX"

[[ -f /usr/local/nvm/nvm.sh ]] && NVM_BOOT=/usr/local/nvm/nvm.sh
[[ -f $HOME/.nvm/nvm.sh     ]] && NVM_BOOT=$HOME/.nvm/nvm.sh

if [[ "x" != "x$NVM_BOOT" ]]
then
  NODE_VERSION=v0.6.6
  source $NVM_BOOT
  nvm use $NODE_VERSION 1>/dev/null
  echo "node: $NODE_VERSION"
fi

mkdir -p $PREFIX
cd $PREFIX

npm install git://github.com/mrtesla/pluto.git#$PLUTO_VERSION

mkdir -p script
cd script
ln -s ../node_modules/pluto/script/start   start
ln -s ../node_modules/pluto/script/stop    stop
ln -s ../node_modules/pluto/script/restart restart
ln -s ../node_modules/pluto/script/status  status

