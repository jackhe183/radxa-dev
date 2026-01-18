#!/bin/bash

if [ -z "$ACUITY_PATH" ]; then
    echo "Need to set environment variable ACUITY_PATH"
    exit 1
fi

PEGASUS=$ACUITY_PATH/pegasus 
if [ ! -e "$PEGASUS" ]; then
    PEGASUS="python3 $PEGASUS.py"
fi   


function export_ovx_network()
{
    NAME=$1
    pushd $NAME
    
    QUANTIZED=$2
    	
    if [ ${QUANTIZED} = 'float' ]; then 
        TYPE=float
        generate_path='./wksp/${NAME}_fp16'
    else
		TYPE=quantized
		generate_path='./wksp/${NAME}_${QUANTIZED}'
    fi

    echo " ======================================================================="
    echo " =========== Start Generate $NAME ovx C code with type of ${QUANTIZED} ==========="
    echo " ======================================================================="
    
    # if want to import c code into win IDE , change --target-ide-project command-line param from 'linux64' -> 'win32'
    if [ ${QUANTIZED} = 'float' ]; then 		
        cmd="$PEGASUS export ovxlib \
            --model                 ${NAME}.json \
            --model-data            ${NAME}.data \
            --dtype                 ${TYPE} \
            --target-ide-project    'linux64'\
            --with-input-meta       ${NAME}_inputmeta.yml \
            --output-path           ${generate_path}/${NAME}_fp16"
    else
    
        if [ -f ${NAME}_${QUANTIZED}.quantize ]; then
            echo -e "\033[31m using  ${NAME}_${QUANTIZED}.quantize \033[0m" 
        else
            echo -e "\033[31m Can not find  ${NAME}_${QUANTIZED}.quantize \033[0m" 
            exit -1;
        fi  

        local MODEL=
        if [ -f ${NAME}_${QUANTIZED}.quantize.json ]; then
            echo -e "\033[31m using  ${NAME}_${QUANTIZED}.quantize.json \033[0m" 
            MODEL=${NAME}_${QUANTIZED}.quantize.json
        else
            MODEL=${NAME}.json
        fi
        cmd="$PEGASUS export ovxlib \
            --model                 ${MODEL} \
            --model-data            ${NAME}.data \
            --dtype                 ${TYPE} \
            --model-quantize        ${NAME}_${QUANTIZED}.quantize\
            --target-ide-project    'linux64'\
            --with-input-meta       ${NAME}_inputmeta.yml \
            --output-path           ${generate_path}/${NAME}_${QUANTIZED}"

        if [ ! -z "$VSIMULATOR_CONFIG" ]; then
            cmd+=" \
                --save-fused-graph \
                --postprocess-file      ${NAME}_postprocess_file.yml \
                --pack-nbg-unify \
                --optimize              ${VSIMULATOR_CONFIG} \
                --viv-sdk               ${VIV_SDK} "
        fi
    fi  
  
    echo $cmd
    eval $cmd
    
    echo " ======================================================================="
    echo " =========== End  Generate $NAME ovx C code with type of ${quantization_type} ==========="
    echo " ======================================================================="
    
    popd
}

if [ "$#" -lt 2 ]; then
    echo "Enter a network name and quantized type (float / uint8 / int16 / bf16 / pcq)"
    exit -1
fi

export_ovx_network ${1%/} ${2%/}
