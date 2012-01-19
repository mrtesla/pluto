#!/usr/bin/env bash

# redirect STDERR to STDOUT
exec 2>&1

echo "*******************************************"
echo "*** Pluto is booting: {{task}}"
echo "*******************************************"


# load NVM
echo " * Loading NVM"
[[ -f /usr/local/nvm/nvm.sh ]] && NVM_BOOT=/usr/local/nvm/nvm.sh
[[ -f $HOME/.nvm/nvm.sh     ]] && NVM_BOOT=$HOME/.nvm/nvm.sh
[[ "x" != "x$NVM_BOOT"      ]] && . $NVM_BOOT

# load RVM
echo " * Loading RVM"
export rvm_project_rvmrc=0
export rvm_pretty_print=0
[[ -f /usr/local/rvm/scripts/rvm ]] && RVM_BOOT=/usr/local/rvm/scripts/rvm
[[ -f $HOME/.rvm/scripts/rvm     ]] && RVM_BOOT=$HOME/.rvm/scripts/rvm
[[ "x" != "x$RVM_BOOT"           ]] && . $RVM_BOOT

# switch to Pluto NODE_VERSION
echo " * Loading Pluto environment"
cd {{quote pluto_root}}
nvm use {{quote pluto_node_version}}
PLUTO_PREFIX={{quote pluto_prefix}}

# get port numbers
echo " * Allocating port numbers:"
{{#ports}}
  {{#if port}}
    export {{name}}={{quote port}}
    echo "   - {{name}}=${{name}}"
  {{/if}}
  {{#unless port}}
    export {{name}}=$(script/utils/get-port)
    echo "   - {{name}}=${{name}}"
  {{/unless}}
{{/ports}}

# export ENV
echo " * Exporting environment:"
{{#env}}
export {{name}}={{quote value}}
echo "   - {{name}}=${{name}}"
{{/env}}

# tell pluto the process is about to start
#   this is when any start hooks are called
echo " * Running hooks"
script/hooks/starting {{quote task}}

# deactivate Pluto node
echo " * Unloading Pluto environment"
nvm deactivate | grep -v 'removed from'
unset RVM_BOOT
unset NVM_BOOT
unset NVM_PATH
unset NVM_DIR
unset NVM_BIN
unset PLUTO_PREFIX

# switching to $NODE_VERSION
echo " * Selecting Node version: ${NODE_VERSION:-none}"
[[ "x$NODE_VERSION" != "x" ]] && nvm use $NODE_VERSION

# switching to $RUBY_VERSION
echo " * Selecting Ruby version: ${RUBY_VERSION:-none}"
[[ "x$RUBY_VERSION" != "x" ]] && rvm use $RUBY_VERSION

echo " * Switching to user: {{user}}"
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
