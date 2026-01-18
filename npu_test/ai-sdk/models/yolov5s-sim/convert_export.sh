#!/bin/bash

if [ -z "$ACUITY_PATH" ]; then
    echo "Need to set environment variable ACUITY_PATH"
        exit 1
fi

if [ -z "$VIV_SDK" ]; then
    echo "Need to set environment variable VIV_SDK"
        exit 1
fi

PEGASUS=$ACUITY_PATH/pegasus
if [ ! -e "$PEGASUS" ]; then
    PEGASUS="python3 $PEGASUS.py"
fi

function rm_json_data()
{
    if [ -f ${NAME}.json ]; then
        echo -e "\033[31m rm  ${NAME}.json \033[0m"
        rm ${NAME}.json
    fi

    if [ -f ${NAME}.data ]; then
        echo -e "\033[31m rm  ${NAME}.data \033[0m"
        rm ${NAME}.data
    fi
}
function import_caffe_network()
{
    NAME=$1
    rm_json_data

    echo "=========== Converting $NAME Caffe model ==========="
    if [ -f ${NAME}.caffemodel ]; then
    cmd_import="$PEGASUS import caffe\
        --model         ${NAME}.prototxt \
        --weights       ${NAME}.caffemodel \
        --output-model  ${NAME}.json \
        --output-data   ${NAME}.data"
    else
    echo "=========== fake Caffe model data file==========="
    cmd_import="$PEGASUS import caffe\
        --model         ${NAME}.prototxt \
        --output-model  ${NAME}.json \
        --output-data   ${NAME}.data"
    fi
}

function import_tensorflow_network()
{
    NAME=$1
    rm_json_data

    echo "=========== Converting $NAME Tensorflow model ==========="
    cmd_import="$PEGASUS import tensorflow\
        --model         ${NAME}.pb \
        --output-model  ${NAME}.json \
        --output-data   ${NAME}.data \
        $(cat inputs_outputs.txt)"
}

function import_pytorch_network()
{
    NAME=$1
    rm_json_data

    echo "=========== Converting $NAME Pytorch model ==========="
    cmd_import="$PEGASUS import pytorch\
        --model         ${NAME}.pt \
        --output-model  ${NAME}.json \
        --output-data   ${NAME}.data \
        $(cat inputs_outputs.txt)"
}

function import_keras_network()
{
    NAME=$1
    rm_json_data

    echo "=========== Converting $NAME Keras model ==========="
    cmd_import="$PEGASUS import keras\
        --model         ${NAME}.h5 \
        --output-model  ${NAME}.json \
        --output-data   ${NAME}.data \
        $(cat inputs_outputs.txt)"
}

function import_onnx_network()
{
    NAME=$1
    rm_json_data

    echo "=========== Converting $NAME ONNX model ==========="
    cmd_import="$PEGASUS import onnx\
        --model         ${NAME}.onnx \
        --output-model  ${NAME}.json \
        --output-data   ${NAME}.data \
        $(cat inputs_outputs.txt)"
}

function import_tflite_network()
{
    NAME=$1
    rm_json_data

    echo "=========== Converting $NAME TFLite model ==========="
    cmd_import="$PEGASUS import tflite\
        --model         ${NAME}.tflite \
        --output-model  ${NAME}.json \
        --output-data   ${NAME}.data"
}

function import_darknet_network()
{
    NAME=$1
    rm_json_data

    echo "=========== Converting $NAME darknet model ==========="
    cmd_import="$PEGASUS import darknet\
        --model         ${NAME}.cfg \
        --weights       ${NAME}.weights \
        --output-model  ${NAME}.json \
        --output-data   ${NAME}.data"
}
function generate_inputmeta()
{
    NAME=$1

    echo "=========== Generate $NAME inputmeta file ==========="
    cmd_gen_inputmeta="$PEGASUS generate inputmeta\
        --model               ${NAME}.json \
        --separated-database \
        --input-meta-output   ${NAME}_inputmeta.yml"
}

function generate_postprocess_file()
{
    NAME=$1

    echo "=========== Generate $NAME postprocess_file file ==========="
    cmd_gen_postprocess="$PEGASUS generate postprocess-file \
        --model               ${NAME}.json \
        --postprocess-file-output    ${NAME}_postprocess_file.yml"
}

function import_network()
{
    NAME=$1
    pushd $NAME

    if [ -f ${NAME}.prototxt ]; then
        import_caffe_network ${1%/}
    elif [ -f ${NAME}.pb ]; then
        import_tensorflow_network ${1%/}
    elif [ -f ${NAME}.pt ]; then
        import_pytorch_network ${1%/}
    elif [ -f ${NAME}.h5 ]; then
        import_keras_network ${1%/}
    elif [ -f ${NAME}.onnx ]; then
        import_onnx_network ${1%/}
    elif [ -f ${NAME}.tflite ]; then
        import_tflite_network ${1%/}
    elif [ -f ${NAME}.weights ]; then
        import_darknet_network ${1%/}
    else
        echo "=========== can not find suitable model files ==========="
    fi

    echo $cmd_import
    eval $cmd_import

    if [ -f ${NAME}.data -a -f ${NAME}.json ]; then
        echo -e "\033[31m import SUCCESS \033[0m"

        if [ -f ${NAME}_inputmeta.yml ]; then
            echo -e "\033[31m already has ${NAME}_inputmeta.yml \033[0m"
        else
            generate_inputmeta ${1%/}
            echo $cmd_gen_inputmeta
            eval $cmd_gen_inputmeta
            echo -e "\033[31m generate NAME inputmeta ! \033[0m"
            echo -e "\033[31m pls modify the contents of ${NAME}_inputmeta.yml ! \033[0m"
        fi

        if [ -f ${NAME}_postprocess_file.yml ]; then
            echo -e "\033[31m already has ${NAME}_postprocess_file.yml \033[0m"
        else
            generate_postprocess_file ${1%/}
            echo $cmd_gen_postprocess
            eval $cmd_gen_postprocess
            echo -e "\033[31m generate NAME postprocess_file ! \033[0m"
            echo -e "\033[31m pls modify the contents of ${NAME}_postprocess_file.yml ! \033[0m"
        fi

        if [ -f ${NAME}.quantize ]; then
            echo -e "\033[31m ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ \033[0m"
            echo -e "\033[31m !!! it's a quant model, in order to suit the naming rule , rename to ${NAME}_uint8.quantize !!! \033[0m"
            echo -e "\033[31m ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ \033[0m"
            mv ${NAME}.quantize ${NAME}_uint8.quantize
        fi
    else
        echo -e "\033[31m import model ERROR ! \033[0m"
    fi
    popd
}

function pegasus_channel_mean()
{
    local NAME=${1%/}
    pushd $NAME
    if [ -f ${NAME}_inputmeta.yml -a -f channel_mean_value.txt ]; then
        local means=($(cat channel_mean_value.txt))
        local channel=($(sed -n "/mean/,/preproc_node_params/=" ${NAME}_inputmeta.yml))
        local values=${#means[@]}
        local lines=${#channel[@]}
        if [ $lines -eq 4 ]; then
            sed -i "${channel[1]}s/- 0$/- ${means[0]}/g" ${NAME}_inputmeta.yml
            sed -i "${channel[2]}s/1.0$/${means[1]}/g" ${NAME}_inputmeta.yml
        elif [ $lines -eq 6 ]; then
            sed -i "${channel[1]}s/- 0$/- ${means[0]}/g" ${NAME}_inputmeta.yml
            sed -i "${channel[2]}s/- 0$/- ${means[1]}/g" ${NAME}_inputmeta.yml
            sed -i "${channel[3]}s/- 0$/- ${means[2]}/g" ${NAME}_inputmeta.yml
            sed -i "${channel[4]}s/1.0$/${means[3]}/g" ${NAME}_inputmeta.yml
        elif [ $lines -eq 9 ]; then
            if [ $values -eq 6 ]; then
                sed -i "${channel[1]}s/- 0$/- ${means[0]}/g" ${NAME}_inputmeta.yml
                sed -i "${channel[2]}s/- 0$/- ${means[1]}/g" ${NAME}_inputmeta.yml
                sed -i "${channel[3]}s/- 0$/- ${means[2]}/g" ${NAME}_inputmeta.yml
                sed -i "${channel[5]}s/- 1.0$/- ${means[3]}/g" ${NAME}_inputmeta.yml
                sed -i "${channel[6]}s/- 1.0$/- ${means[4]}/g" ${NAME}_inputmeta.yml
                sed -i "${channel[7]}s/- 1.0$/- ${means[5]}/g" ${NAME}_inputmeta.yml
            else
                sed -i "${channel[1]}s/- 0$/- ${means[0]}/g" ${NAME}_inputmeta.yml
                sed -i "${channel[2]}s/- 0$/- ${means[1]}/g" ${NAME}_inputmeta.yml
                sed -i "${channel[3]}s/- 0$/- ${means[2]}/g" ${NAME}_inputmeta.yml
                sed -i "${channel[5]}s/- 1.0$/- ${means[3]}/g" ${NAME}_inputmeta.yml
                sed -i "${channel[6]}s/- 1.0$/- ${means[3]}/g" ${NAME}_inputmeta.yml
                sed -i "${channel[7]}s/- 1.0$/- ${means[3]}/g" ${NAME}_inputmeta.yml
            fi
        else
            echo "unknown channel lines: $line"
        fi
    fi
    popd
}

function quantize_network()
{
    NAME=$1
    pushd $NAME

    QUANTIZED=$2
    POSTFIX=$2
    if [ ${QUANTIZED} = 'float' ]; then
        echo "=========== do not need quantied, pls change the 2rd param like ( uint8 / int16 / bf16 / pcq )============"
        exit -1
    elif [ ${QUANTIZED} = 'uint8' ]; then
        QUANTIZER="asymmetric_affine"
    elif [ ${QUANTIZED} = 'int16' ]; then
        QUANTIZER="dynamic_fixed_point"
    elif [ ${QUANTIZED} = 'pcq' ]; then
        QUANTIZER="perchannel_symmetric_affine"
        QUANTIZED="int8"
        POSTFIX="pcq"
    elif [ ${QUANTIZED} = 'bf16' ]; then
        QUANTIZER="qbfloat16"
        QUANTIZED="qbfloat16"
        POSTFIX="bf16"
    else
        echo "=========== wrong quantization_type ! ( uint8 / int16 / bf16 / pcq )==========="
        exit -1
    fi

    echo " ======================================================================="
    echo " ==== Start Quantizing $NAME model with type of ${quantization_type} ==="
    echo " ======================================================================="

    if [ -f ${NAME}_${POSTFIX}.quantize ]; then
        echo -e "\033[31m rm  ${NAME}_${POSTFIX}.quantize \033[0m"
        rm ${NAME}_${POSTFIX}.quantize
    fi

    cmd_quantize="$PEGASUS quantize \
        --model         ${NAME}.json \
        --model-data    ${NAME}.data \
        --device        CPU \
        --with-input-meta ${NAME}_inputmeta.yml \
        --compute-entropy \
        --rebuild  \
        --model-quantize  ${NAME}_${POSTFIX}.quantize \
        --quantizer ${QUANTIZER} \
        --qtype  ${QUANTIZED} "

    echo $cmd_quantize
    eval $cmd_quantize

    if [ -f ${NAME}_${POSTFIX}.quantize ]; then
        echo -e "\033[31m SUCCESS \033[0m"
    else
        echo -e "\033[31m ERROR ! \033[0m"
    fi

    popd
}

function export_ovx_network()
{
    NAME=$1
    pushd $NAME

    QUANTIZED=$2
    OPTIMIZED=$3
    VIV_SDK=$4
    echo "${OPTIMIZED}  ${VIV_SDK}"

    if [ ${QUANTIZED} = 'float' ]; then
        TYPE=float
        generate_path="./wksp/${NAME}_fp16"
    else
        TYPE=quantized
        generate_path="./wksp/${NAME}_${QUANTIZED}"
    fi

    echo " ======================================================================="
    echo " =========== Start Generate $NAME ovx C code with type of ${QUANTIZED} ==========="
    echo " ======================================================================="

    # if want to import c code into win IDE , change --target-ide-project command-line param from 'linux64' -> 'win32'
    # if need to generate nb which running on viplite driver , pls replace '--pack-nbg-unify' with  '--pack-nbg-viplite'
    if [ ${QUANTIZED} = 'float' ]; then
        cmd_export="$PEGASUS export ovxlib \
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

        cmd_export="$PEGASUS export ovxlib \
            --model                 ${NAME}.json \
            --model-data            ${NAME}.data \
            --dtype                 ${TYPE} \
            --model-quantize        ${NAME}_${QUANTIZED}.quantize\
            --batch-size            1       \
            --save-fused-graph              \
            --target-ide-project    'linux64'\
            --optimize              ${OPTIMIZED} \
            --viv-sdk               ${VIV_SDK} \
            --pack-nbg-unify  \
            --with-input-meta       ${NAME}_inputmeta.yml \
            --postprocess-file      ${NAME}_postprocess_file.yml \
            --output-path           ${generate_path}/${NAME}_${QUANTIZED}"
    fi

    echo $cmd_export
    eval $cmd_export

    echo " ======================================================================="
    echo " =========== End  Generate $NAME ovx C code with type of ${quantization_type} ==========="
    echo " ======================================================================="

    popd
}

function convert_platform_to_optimize()
{
    PLATFORM=$1
    echo "convert PLATFORM=${PLATFORM}"

    if [ ${PLATFORM} = 'v85x' ]; then
        OPTIMIZE=VIP9000PICO_PID0XEE
    elif [ ${PLATFORM} = 'r853' ]; then
        OPTIMIZE=VIP9000PICO_PID0XEE
    elif [ ${PLATFORM} = 'mr527' ]; then
        OPTIMIZE=VIP9000NANOSI_PLUS_PID0X10000016
    elif [ ${PLATFORM} = 'ai985' ]; then
        OPTIMIZE=VIP9000NANOSI_PLUS_PID0X10000016
    elif [ ${PLATFORM} = 't527' ]; then
        OPTIMIZE=VIP9000NANOSI_PLUS_PID0X10000016
    elif [ ${PLATFORM} = 'mr536' ] || [ ${PLATFORM} = 't536' ]; then
        OPTIMIZE=VIP9000NANODI_PLUS_PID0X1000003B
    else
        echo "=========== wrong platform ! ( v85x / r853 / mr527/ ai985 / t527)==========="
        echo "=========== wrong platform ! ( mr536 / t536)==========="
        exit -1
    fi
}

function copy_nbg()
{
    echo "${generate_path}_nbg_unify/network_binary.nb"
    if [ -f "${generate_path}_nbg_unify/network_binary.nb" ]; then
        echo -e "\033[31m copy network_binary.nb to ${NAME}_${QUANTIZED}.nb \033[0m"
        cpcmd="cp ${generate_path}_nbg_unify/network_binary.nb ./${NAME}_${QUANTIZED}.nb"
        echo $cpcmd
        eval $cpcmd
    fi
}

function print_history_cmd()
{

    RED='\033[31m'
    GREEN='\033[32m'
    NC='\033[0m'
    echo -e "${GREEN} CMD History:${NC}"

    cmd_import=$(sed 's|.*pegasus|pegasus|g' <<< $cmd_import)
    cmd_import=$(tr -s ' ' <<< $cmd_import)
    echo -e "${GREEN} CMD:${cmd_import} ${NC}"

    if [ -z "$cmd_gen_inputmeta" ]; then
        echo -e "\033[31m already has ${NAME}_inputmeta.yml \033[0m"
    else
        cmd_gen_inputmeta=$(sed 's|.*pegasus|pegasus|g' <<< $cmd_gen_inputmeta)
        cmd_gen_inputmeta=$(tr -s ' ' <<< $cmd_gen_inputmeta)
        echo -e "${GREEN} CMD:${cmd_gen_inputmeta} ${NC}"
    fi

    if [ -z "$cmd_gen_postprocess" ]; then
        echo -e "\033[31m already has ${NAME}_postprocess_file.yml \033[0m"
    else
        cmd_gen_postprocess=$(sed 's|.*pegasus|pegasus|g' <<< $cmd_gen_postprocess)
        cmd_gen_postprocess=$(tr -s ' ' <<< $cmd_gen_postprocess)
        echo -e "${GREEN} CMD:${cmd_gen_postprocess} ${NC}"
    fi

    cmd_quantize=$(sed 's|.*pegasus|pegasus|g' <<< $cmd_quantize)
    cmd_quantize=$(tr -s ' ' <<< $cmd_quantize)
    echo -e "${GREEN} CMD:${cmd_quantize} ${NC}"

    cmd_export=$(sed 's|.*pegasus|pegasus|g' <<< $cmd_export)
    cmd_export=$(tr -s ' ' <<< $cmd_export)
    echo -e "${GREEN} CMD:${cmd_export} ${NC}"
}

if [ "$#" -lt 3 ]; then
    echo -e "\033[31m  Enter three parameters \033[0m"
    echo "Usage: convert_export.sh <model_name> <quantize_type> <platform>"
    echo "quantize_type    : uint8 / int16 / bf16 / pcq"
    echo "platform         : v85x / r853 / mr527/ ai985 / t527 / mr536 / t536"
    exit -1
fi

convert_platform_to_optimize ${3%/}
import_network ${1%/}
pegasus_channel_mean ${1%/}
quantize_network ${1%/} ${2%/}
export_ovx_network ${1%/} ${2%/}  ${OPTIMIZE} $VIV_SDK
copy_nbg
print_history_cmd
