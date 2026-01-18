#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

#include <awnn_lib.h>

void *load_file(const char *fn, unsigned *_sz)
{
    char *data;
    int sz;
    int fd;

    data = 0;
    fd = open(fn, O_RDONLY);
    if(fd < 0) return 0;

    sz = lseek(fd, 0, SEEK_END);
    if(sz < 0) goto oops;

    if(lseek(fd, 0, SEEK_SET) != 0) goto oops;

    data = (char*) malloc(sz + 1);
    if(data == 0) goto oops;

    if(read(fd, data, sz) != sz) goto oops;
    close(fd);
    data[sz] = 0;

    if(_sz) *_sz = sz;
    return data;

oops:
    close(fd);
    if(data != 0) free(data);
    return 0;
}

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
    unsigned int size;
    unsigned char *data = (unsigned char *)load_file(input, &size);
    void *input_buffers[] = {data};
    awnn_set_input_buffers(context, input_buffers);
    // process network
    awnn_run(context);
    // get result
    float **results = awnn_get_output_buffers(context);
    // post process
    for (int i = 0; i < 10; i++) {
        printf("%f ", results[0][i]);
    }
    printf("\n");

    free(data);
    // destroy network
    awnn_destroy(context);
    // npu uninit
    awnn_uninit();

    return 0;
}

