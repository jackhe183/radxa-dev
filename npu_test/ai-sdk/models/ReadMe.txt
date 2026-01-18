

model                      | platform
-------------------------------------------------------
lenet                      | caffe          |
lstm_mnist                 | tensorflow     | lstm
mobilenet_v1_1.0_224_quant | tflite         | quant
yolov3_tiny                | darknet        |
MobileNetV2_Imagenet       | keras          |
squeezenet1_0              | pytorch        |
inception_v1               | onnx           |
deepspeech2                | tensorflow     |


usage
0. source env.sh v3 // env setup, npu version (v1/v2/v3)
1. export ACUITY_PATH=<path-of-acuity-toolkit>/bin/ and VIV_SDK=<path-of-VivanteIDE>/cmdtools
2. pegasus_auto // auto import, quantize uint8, and export all models
3. pegasus_one MODEL_NAME // auto import, quantize uint8, and export MODEL_NAME
4. shell scripts:
    pegasus_import.sh MODEL_NAME
    pegasus_inference.sh MODEL_NAME float
    pegasus_quantize.sh MODEL_NAME QType
    pegasus_inference.sh MODEL_NAME QType/float
    pegasus_dump.sh MODEL_NAME QType/float
    pegasus_export_ovx.sh MODEL_NAME QType/float

note:
1. QType include "uint8 / int16 / bf16 / pcq" .
2. it need to config mean scale in "channel_mean_value.txt", to auto change channel-mean value in inputmeta file with `pegasus_channel_mean` command.
3. for some models , it needs to config correct --inputs / --outputs / --input-size-list in "inputs_outputs.txt" before import
4. if the original model is already quanted, only quant-type are supported.
    for example, "mobilenet_v1_1.0_224_quant" is quant model with uint8 format, after import this model,
    the "*_uint8.quantize" file are generated, we don't need to re-quantized again, just use it and only can use it to do next series of operations.
5. when using float to export source code , "./pegasus_export_ovx.sh MODEL_NAME float", it will generated fp16 format source network.
6. it doesn't support bf16 / pcq format for some old H/W config , even running correctly on acuity software. so pls check it when you trying to use it.
