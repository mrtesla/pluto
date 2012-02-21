#!/usr/bin/env bash

# redirect STDERR to STDOUT
exec 2>&1

echo "*******************************************"
echo "*** Pluto is terminating: {{task}}"
echo "*******************************************"

export EXIT_CODE="$1"
export EXIT_STATUS="$2"

echo " * Loading Pluto environment"
PLUTO_ROOT={{quote pluto_root}}
PLUTO_NODE={{quote pluto_node}}
PLUTO_PREFIX={{quote pluto_prefix}}

echo " * Running hooks"
PLUTO_ROOT=$PLUTO_ROOT "$PLUTO_NODE" "$PLUTO_PREFIX/bin/pluto" hooks terminated {{quote task}}

echo "*******************************************"
echo ""
