#!/usr/bin/env bash

# redirect STDERR to STDOUT
exec 2>&1


echo "*******************************************"
echo "*** Pluto is terminating: {{task}}"
echo "*******************************************"


# load NVM
echo " * Loading NVM"
[[ -f /usr/local/nvm/nvm.sh ]] && NVM_BOOT=/usr/local/nvm/nvm.sh
[[ -f $HOME/.nvm/nvm.sh     ]] && NVM_BOOT=$HOME/.nvm/nvm.sh
[[ "x" != "x$NVM_BOOT"      ]] && . $NVM_BOOT


# switch to Pluto NODE_VERSION
echo " * Loading Pluto environment"
cd {{quote pluto_root}}
nvm use {{quote pluto_node_version}}
PLUTO_PREFIX={{quote pluto_prefix}}


# tell pluto the process is about to start
#   this is when any start hooks are called
echo " * Running hooks"
node $PLUTO_PREFIX/internal/emit/terminated.js {{quote task}}


echo "*******************************************"
echo ""
