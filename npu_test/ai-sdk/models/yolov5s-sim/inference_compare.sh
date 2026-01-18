#!/bin/bash

if [ -z "$ACUITY_PATH" ]; then
    echo "Need to set environment variable ACUITY_PATH"
        exit 1
fi

PEGASUS=$ACUITY_PATH/pegasus
if [ ! -e "$PEGASUS" ]; then
    PEGASUS="python3 $PEGASUS.py"
fi

COMPUTE_TENSOR_SIMILARITY=$ACUITY_PATH/tools/compute_tensor_similarity
if [ ! -e "$COMPUTE_TENSOR_SIMILARITY" ]; then
    COMPUTE_TENSOR_SIMILARITY="python3 $COMPUTE_TENSOR_SIMILARITY.py"
fi

function inference_network()
{
    NAME=$1
    QUANTIZED=$2


    if [ ${QUANTIZED} = 'float' ]; then
        echo "=========== do not need quantied==========="
        TYPE=float32;
        inf_path='./inf/${NAME}_non-quantized'
    elif [ ${QUANTIZED} = 'uint8' ]; then
        inf_path='./inf/${NAME}_uint8'
        TYPE=quantized;
    elif [ ${QUANTIZED} = 'int16' ]; then
        inf_path='./inf/${NAME}_int16'
        TYPE=quantized;
    elif [ ${QUANTIZED} = 'pcq' ]; then
        inf_path='./inf/${NAME}_pcq'
        TYPE=quantized;
    elif [ ${QUANTIZED} = 'bf16' ]; then
        inf_path='./inf/${NAME}_bf16'
        TYPE=quantized;
    else
        echo "=========== wrong quantization_type ! (float / bf16 / int16 / uint8 / pcq)==========="
        exit -1
    fi


    if [ ${TYPE} = 'float32' ]; then
        echo " ======================================================================="
        echo " =========== Start Inference $NAME model with type of float ============"
        echo " ======================================================================="

        cmd_inference="$PEGASUS inference \
        --model         ${NAME}.json \
        --model-data    ${NAME}.data \
        --dtype         ${TYPE} \
        --iterations    1 \
        --device        CPU \
        --output-dir    ${inf_path} \
        --postprocess-file  ${NAME}_postprocess_file.yml \
        --with-input-meta ${NAME}_inputmeta.yml"

    else
        echo " ======================================================================="
        echo " = Start Inference $NAME model with type of ${QUANTIZED} ======="
        echo " ======================================================================="

        if [ -f ${NAME}_${QUANTIZED}.quantize ]; then
            echo -e "\033[31m using  ${NAME}_${QUANTIZED}.quantize \033[0m"
        else
            echo -e "\033[31m Can not find  ${NAME}_${QUANTIZED}.quantize \033[0m"
            exit -1;
        fi

        cmd_inference="$PEGASUS inference \
        --model         ${NAME}.json \
        --model-data    ${NAME}.data \
        --dtype         ${TYPE} \
        --model-quantize ${NAME}_${QUANTIZED}.quantize\
        --iterations    1 \
        --device        CPU \
        --output-dir    ${inf_path} \
        --postprocess-file  ${NAME}_postprocess_file.yml \
        --with-input-meta ${NAME}_inputmeta.yml"
    fi

    echo $cmd_inference
    eval $cmd_inference
    echo "=========== End  inference $NAME model  ==========="

    #popd
}

if [ "$#" -lt 2 ]; then
    echo "Enter a network name and quantized type (float / bf16 / int16 / uint8 / pcq)"
    exit -1
fi

function compute_tensor_similarity()
{
    NAME=$1
    QUANTIZED=$2

    inf_path_float="./inf/${NAME}_non-quantized"
    if [ -d ${inf_path_float} ]; then
        echo -e "\033[31m using  ${inf_path_float} for gloden tensor \033[0m"
    else
        echo -e "\033[31m Can not find ${inf_path_float} \033[0m"
        exit -1;
    fi

    if [ ${QUANTIZED} = 'uint8' ]; then
        inf_path_type="./inf/${NAME}_uint8"
    elif [ ${QUANTIZED} = 'int16' ]; then
        inf_path_type="./inf/${NAME}_int16"
    elif [ ${QUANTIZED} = 'pcq' ]; then
        inf_path_type="./inf/${NAME}_pcq"
    elif [ ${QUANTIZED} = 'bf16' ]; then
        inf_path_type="./inf/${NAME}_bf16"
    else
        echo "=========== wrong quantization_type ! (bf16 / int16 / uint8 / pcq)==========="
        exit -1
    fi

    if [ -d ${inf_path_type} ]; then
        echo -e "\033[31m using  ${inf_path_type} for compare tensor \033[0m"
    else
        echo -e "\033[31m Can not find  ${inf_path_type} \033[0m"
        exit -1;
    fi

    for file in $(ls $inf_path_float)
    do
        echo -e "=========== \033[31m compute tensor similarity for ${file} \033[0m==========="
        cmd_similarity="$COMPUTE_TENSOR_SIMILARITY ${inf_path_type}/${file} ${inf_path_float}/${file}"
        echo $cmd_similarity
        eval $cmd_similarity
        echo "===========End compute for ${file}==========="
    done
}

function print_history_cmd()
{

    RED='\033[31m'
    GREEN='\033[32m'
    NC='\033[0m'
    echo -e "${GREEN} CMD History:${NC}"

    cmd_inference=$(sed 's|.*pegasus|pegasus|g' <<< $cmd_inference)
    cmd_inference=$(tr -s ' ' <<< $cmd_inference)
    echo -e "${GREEN} CMD:${cmd_inference} ${NC}"

    echo -e "${GREEN} CMD:${cmd_similarity} ${NC}"
}

inference_network ${1%/} 'float'
inference_network ${1%/} ${2%/}
compute_tensor_similarity ${1%/} ${2%/}
print_history_cmd
