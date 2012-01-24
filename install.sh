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
  $PREFIX/bin             \
  $PREFIX/services

cd $PREFIX

rm -rf node_modules

if [[ "x" != "x$DEV_PREFIX" ]]
then
  npm install $DEV_PREFIX
else
  npm install git://github.com/mrtesla/pluto.git#$PLUTO_VERSION
fi

rm -f bin/pluto
ln -s ../node_modules/.bin/pluto bin/pluto
chmod a+x bin/pluto
