#!/usr/bin/env bash

# redirect STDERR to STDOUT
exec 2>&1

# load NVM
[[ -f /usr/local/nvm/nvm.sh ]]      && . /usr/local/nvm/nvm.sh

# load RVM
[[ -f /usr/local/rvm/scripts/rvm ]] && . /usr/local/rvm/scripts/rvm

# switch to Pluto NODE_VERSION
cd {{quote pluto_root}}
nvm use {{quote pluto_node_version}}
NPM_BIN=$(npm bin)

# tell pluto the process is about to start
#   this is when any start hooks are called
node $NPM_BIN/internal/emit/terminated.js {{quote task}}
