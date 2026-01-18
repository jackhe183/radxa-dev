#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

#include <awnn_lib.h>

#include "image_utils.h"
#include "yolact_post_process.h"

int main(int argc, char **argv) {
    printf("%s nbg input\n", argv[0]);
    if(argc < 3)
    {
        printf("Arguments count %d is incorrect!\n", argc);
        return -1;
    }
    const char* nbg = argv[1];
    const char* input = argv[2];

    // npu init
    awnn_init();
    // create network
    Awnn_Context_t *context = awnn_create(nbg);
    // copy input
    unsigned int width = 550;
    unsigned int height = 550;
    unsigned int depth = 3;
    unsigned char *data = (unsigned char *) get_jpeg_image_data(input, width, height, depth);
    unsigned int sz = width * height * depth;
    unsigned char* plant_data = (unsigned char*) malloc(sz * sizeof(unsigned char));
    unsigned int i, j;
    float means[] = {123.68, 116.78, 103.94};
    float stds[] = {58.40, 57.12, 57.38};
    float scale = 0.017959;
    unsigned int zeropoint = 118;
    // trans RGBRGBRGB to BBBGGGRRR
    for (i = 0; i < depth; i++) {
        unsigned int offset = width * height * i;
        float mean = means[i];
        float std = stds[i];
        for (j = 0; j < width * height; j++)
        {
            plant_data[j + offset] = (((float)data[j * depth + i] - mean) / std) / scale + zeropoint; // Normalized and Quantized
            //plant_data[j + offset] = data[j * depth + i];
        }
    }
    void *input_buffers[] = {plant_data};
    awnn_set_input_buffers(context, input_buffers);
    // process network
    awnn_run(context);
    //awnn_dump_io(context, "out/yolact");
    // get result
    float **results = awnn_get_output_buffers(context);
    // post process
    yolact_post_process(results, data);

    free(data);
    free(plant_data);
    // destroy network
    awnn_destroy(context);
    // npu uninit
    awnn_uninit();

    return 0;
}

