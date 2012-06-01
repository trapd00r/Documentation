#!/bin/bash

declare -A host_wm
host_wm[shiva]="$(which stumpwm  2> /dev/null)"
host_wm[dvdc]="$(which ratpoison 2> /dev/null)"

echo ${host_wm[dvdc]}
echo ${host_wm[$HOSTNAME]}

# vim: set ts=2 expandtab sw=2:
