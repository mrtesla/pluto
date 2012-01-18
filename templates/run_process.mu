#!/usr/bin/env bash

# redirect STDERR to STDOUT
exec 2>&1

echo "*******************************************"
echo "*** Pluto is booting: {{task}}"
echo "*******************************************"

# load NVM
[[ -f /usr/local/nvm/nvm.sh ]] && NVM_BOOT=/usr/local/nvm/nvm.sh
[[ -f $HOME/.nvm/nvm.sh     ]] && NVM_BOOT=$HOME/.nvm/nvm.sh
[[ "x" != "x$NVM_BOOT"      ]] && . $NVM_BOOT

# load RVM
export rvm_project_rvmrc=0
export rvm_pretty_print=0
[[ -f /usr/local/rvm/scripts/rvm ]] && RVM_BOOT=/usr/local/rvm/scripts/rvm
[[ -f $HOME/.rvm/scripts/rvm     ]] && RVM_BOOT=$HOME/.rvm/scripts/rvm
[[ "x" != "x$RVM_BOOT"           ]] && . $RVM_BOOT

# switch to Pluto NODE_VERSION
cd {{quote pluto_root}}
nvm use {{quote pluto_node_version}}
NPM_BIN={{quote pluto_prefix}}

# get port numbers
{{#ports}}
  {{#if port}}
    export {{name}}={{quote port}}
  {{/if}}
  {{#unless port}}
    export {{name}}=$(node $NPM_BIN/internal/utils/get_port.js)
  {{/unless}}
{{/ports}}

# export ENV
{{#env}}
export {{name}}={{quote value}}
{{/env}}

# tell pluto the process is about to start
#   this is when any start hooks are called
# node $NPM_BIN/internal/emit/starting.js {{quote task}}

# deactivate Pluto node
nvm deactivate
unset RVM_BOOT
unset NVM_BOOT
unset NVM_PATH
unset NVM_DIR
unset NVM_BIN
unset NPM_BIN

# switching to $NODE_VERSION
[[ "x$NODE_VERSION" != "x" ]] && nvm use $NODE_VERSION

# switching to $RUBY_VERSION
[[ "x$RUBY_VERSION" != "x" ]] && rvm use $RUBY_VERSION

export USER={{quote user}}
export HOME="$(eval echo ~$USER)"
cd {{quote root}}

echo "*******************************************"
echo ""

{{#if user_separation}}
# start the process
exec chpst -u $USER -U $USER -0 {{command}}
{{/if}}
{{#unless user_separation}}
# start the process
exec chpst -0 {{command}}
{{/unless}}
