#!/bin/bash

function pegasus_setup()
{
    SCRIPTS_DIR=$(realpath ../scripts)
    source ${SCRIPTS_DIR}/pegasus_setup.sh $1
}

function pegasus_check_quantize()
{
    local NAME=${1%/}
    pushd $NAME
    local POSTFIX=$2

    [ -f ${NAME}_${POSTFIX}.quantize ]
    local ret=$?

    popd
    return $ret
}

function pegasus_clean_model()
{
    local NAME=${1%/}
    pushd $NAME
    rm -f ${NAME}.json ${NAME}.data ${NAME}_inputmeta.yml ${NAME}_postprocess_file.yml ${NAME}_*.quantize entropy.txt
    rm -rf inf wksp
    popd
}

function pegasus_one()
{
    pegasus_clean_model $1
    ${SCRIPTS_DIR}/pegasus_import.sh $1
    pegasus_channel_mean $1
    pegasus_check_quantize $1 uint8 || ${SCRIPTS_DIR}/pegasus_quantize.sh $1 uint8
    ${SCRIPTS_DIR}/pegasus_inference.sh $1 uint8
    ${SCRIPTS_DIR}/pegasus_inference.sh $1 float
    ${SCRIPTS_DIR}/pegasus_export_ovx.sh $1 uint8
}

function pegasus_auto()
{
    local models=($(ls -d */))
    local model
    for model in ${models[@]}; do
        echo $model
        pegasus_one $model
    done
}

function pegasus_clear()
{
    local sbfile=$(readlink -f ${BASH_SOURCE[0]})
    local function_pattern="^function \\([a-zA-Z][a-zA-Z0-9_-]*\\).*"
    local fun
    for fun in $(sed -n "s/${function_pattern}/\1/p" $sbfile); do
        unset $fun
    done
    unset SCRIPTS_DIR
}

if [ "$#" -lt 1 ]; then
    echo "Enter npu version (v1/v2/v3)"
else
    pegasus_setup $1
fi
