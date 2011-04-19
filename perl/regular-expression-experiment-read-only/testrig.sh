#!/bin/sh
exec 2>&1
set -x

#input=/etc/hosts
input=/var/tmp/sample-apache-logfile.txt

: get the size of the input file for reference
ls -l $input

: get a sense of how long the raw read I/O takes / preload buffercache
time cat $input > /dev/null

: run the scripts
for testscript in simple*pl three*pl complex*.pl hybrid*.pl # *.pl,bug # uncomment to include
do
    : storing a reference copy of the output for $testscript
    $testscript $input > saved-$testscript-output.dat~
    # use tilde to make it easy to remove

    : start time trial for $testscript
    date
    time $testscript $input > /dev/null
    time $testscript $input > /dev/null
    time $testscript $input > /dev/null
    : finish time trial for $testscript
    date

    :
    : ------------------------------------------------------------------
    : ------------------------------------------------------------------
    : ------------------------------------------------------------------
    :
done

: done.
