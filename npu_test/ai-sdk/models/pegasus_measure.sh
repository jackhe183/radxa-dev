#!/bin/bash

if [ -z "$ACUITY_PATH" ]; then
    echo "Need to set environment variable ACUITY_PATH"
        exit 1
fi

PEGASUS=$ACUITY_PATH/pegasus 
if [ ! -e "$PEGASUS" ]; then
    PEGASUS="python3 $PEGASUS.py"
fi   

function measure_network()
{
    NAME=$1
    pushd $NAME

    cmd="$PEGASUS measure \
    --model         ${NAME}.json"
    
    echo $cmd
    eval $cmd
    echo "=========== End measure $NAME model  ==========="
    
    popd
}

if [ "$#" -ne 1 ]; then
    echo "Enter a network name !"
    exit -1
fi

measure_network ${1%/}
