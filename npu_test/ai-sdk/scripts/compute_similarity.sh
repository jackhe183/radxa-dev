#!/bin/bash

if [ -z "$ACUITY_PATH" ]; then
    echo "Need to set environment variable ACUITY_PATH"
        exit 1
fi

COMPUTE_SIMILARITY="python3 $ACUITY_PATH/tools/compute_tensor_similarity.py"

function compute_tensor_similarity()
{
    T1=$1
    T2=$2
    cmd="$COMPUTE_SIMILARITY $T1 $T2"
    
    echo $cmd
    eval $cmd
    echo "=========== End compute $T1 $T2 similarity  ==========="
}

if [ "$#" -ne 2 ]; then
    echo "Enter two tensor!"
    exit -1
fi

compute_tensor_similarity ${1} ${2}
