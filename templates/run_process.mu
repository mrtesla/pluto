#!/usr/bin/env bash

# redirect STDERR to STDOUT
exec 2>&1

# load NVM
[[ -f /usr/local/nvm/nvm.sh ]] && NVM_BOOT=/usr/local/nvm/nvm.sh
[[ -f $HOME/.nvm/nvm.sh     ]] && NVM_BOOT=$HOME/.nvm/nvm.sh
[[ "x" != "x$NVM_BOOT"      ]] && . $NVM_BOOT

# load RVM
[[ -f /usr/local/rvm/scripts/rvm ]] && . /usr/local/rvm/scripts/rvm

# switch to Pluto NODE_VERSION
cd {{quote pluto_root}}
nvm use {{quote pluto_node_version}}
NPM_BIN=$(npm bin)

# get port numbers
{{#ports}}
export {{name}}=$(node $NPM_BIN/internal/utils/get_port.js)
{{/ports}}

# export ENV
{{#env}}
export {{name}}={{quote value}}
{{/env}}

# tell pluto the process is about to start
#   this is when any start hooks are called
node $NPM_BIN/internal/emit/starting.js {{quote task}}

# deactivate Pluto node
nvm deactivate
unset NVM_PATH
unset NVM_DIR
unset NVM_BIN
unset NPM_BIN

# switching to $NODE_VERSION
[[ "x$NODE_VERSION" != "x" ]] && nvm use $NODE_VERSION

# switching to $RUBY_VERSION
[[ "x$RUBY_VERSION" != "x" ]] && rvm use $RUBY_VERSION

export rvm_project_rvmrc=0
export USER={{quote user}}
export HOME="$(eval echo ~$USER)"
cd {{quote root}}

# start the process
exec chpst -u $USER -U $USER -0 {{command}}
