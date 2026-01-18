#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

#include <awnn_lib.h>

#include "image_utils.h"
#include "yolov5_pre_process.h"
#include "yolov5_post_process.h"

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
    unsigned int input_width = 640;
    unsigned int input_height = 640;
    unsigned int input_depth = 3;

    unsigned int sz = input_width * input_height * input_depth;
    // unsigned char* plant_data = (unsigned char*) malloc(sz * sizeof(unsigned char));
    unsigned char* plant_data;
    unsigned int i, j;
    unsigned int file_size;

    // preprocess
    plant_data = yolov5_pre_process(input, &file_size);

    void *input_buffers[] = {plant_data};
    awnn_set_input_buffers(context, input_buffers);
    // process network
    awnn_run(context);
    // get result
    float **results = awnn_get_output_buffers(context);
    // post process
    yolov5_post_process(input, results);

    free(plant_data);
    // destroy network
    awnn_destroy(context);
    // npu uninit
    awnn_uninit();

    return 0;
}
