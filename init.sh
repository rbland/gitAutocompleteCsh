#!/bin/tcsh

set sourced=($_)
if ("$sourced" != "") then
    set scriptPath=($sourced[2])
else
    set scriptPath=($0)
endif

set relativeDirectory=`dirname $scriptPath`
set absoluteDirectory=`cd $relativeDirectory && pwd`

setenv PATH ${PATH}:$absoluteDirectory
complete git 'C/*/`gitAutocomplete.bash`/'

