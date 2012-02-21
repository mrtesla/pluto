#!/usr/bin/env bash

# redirect STDERR to STDOUT
exec 2>&1

echo "*******************************************"
echo "*** Pluto is booting: {{task}}"
echo "*******************************************"


echo " * Loading Pluto environment"
PLUTO_ROOT={{quote pluto_root}}
PLUTO_NODE={{quote pluto_node}}
PLUTO_PREFIX={{quote pluto_prefix}}


# get port numbers
echo " * Allocating port numbers:"
{{#ports}}
  {{#if port}}
    export {{name}}={{quote port}}
    echo "   - {{name}}=${{name}}"
  {{/if}}
  {{#unless port}}
    export {{name}}=$(PLUTO_ROOT=$PLUTO_ROOT "$PLUTO_NODE" "$PLUTO_PREFIX/bin/pluto" utils get-port)
    echo "   - {{name}}=${{name}}"
  {{/unless}}
{{/ports}}
PLUTO_ROOT=$PLUTO_ROOT "$PLUTO_NODE" "$PLUTO_PREFIX/bin/pluto" utils dump-ports {{quote task}}


# export ENV
echo " * Exporting environment:"
{{#env}}
export {{name}}={{quote value}}
echo "   - {{name}}=${{name}}"
{{/env}}


# tell pluto the process is about to start
#   this is when any start hooks are called
echo " * Running hooks"
PLUTO_ROOT=$PLUTO_ROOT "$PLUTO_NODE" "$PLUTO_PREFIX/bin/pluto" hooks starting {{quote task}}


# switching to $NODE_VERSION
echo " * Selecting Node version: ${NODE_VERSION:-none}"
[[ "x$NODE_VERSION" != "x" ]] && export PATH="$PLUTO_ROOT/env/node/$NODE_VERSION/bin:$PATH"


# switching to $RUBY_VERSION
echo " * Selecting Ruby version: ${RUBY_VERSION:-none}"
[[ "x$RUBY_VERSION" != "x" ]] && export PATH="$PLUTO_ROOT/env/ruby/$RUBY_VERSION/bin:$PATH"


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
