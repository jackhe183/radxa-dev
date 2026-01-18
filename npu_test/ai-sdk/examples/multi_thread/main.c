/*
 * Company:    AW
 * Author:     Penng
 * Date:    2023/02/06
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef __linux__
#include <sys/time.h>
#elif defined(_WIN32)
#include <windows.h>
#endif

#include <pthread.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

#include <fcntl.h>
#include <awnn_lib.h>

#include "image_utils.h"

/*-------------------------------------------
        Macros and Variables
-------------------------------------------*/

struct thread_param {
	char* model_path;
	char* input_path;
};

/* run yolov5s */
void* network_0_demo(void* arg)
{
	struct thread_param *network_param = (struct thread_param*)arg;
	char *model_file = network_param->model_path;
	char *input_path = network_param->input_path;

	/* create network */
	Awnn_Context_t *context = awnn_create(model_file);

	/* copy input */
	unsigned int width = 640;
	unsigned int height = 640;
	unsigned int depth = 3;
	unsigned char *data = (unsigned char *) get_jpeg_image_data(input_path, width, height, depth);
	unsigned int sz = width * height * depth;
	unsigned char* plant_data = (unsigned char*) malloc(sz * sizeof(unsigned char));
	unsigned int i, j;
	/* trans RGBRGBRGB to BBBGGGRRR */
	for (i = 0; i < depth; i++) {
		unsigned int offset = width * height * (depth - 1 - i);
		for (j = 0; j < width * height; j++)
		{
			plant_data[j + offset] = data[j * depth + i]; /* FIXME */
		}
	}
	void *input_buffers[] = {plant_data};
	awnn_set_input_buffers(context, input_buffers);

	for (i = 0; i < 100; i++) {
		/* process network */
		printf("1\n");
		awnn_run(context);
		sleep(1);
	}

	/* get result */
	float **results = awnn_get_output_buffers(context);

	free(data);
	free(plant_data);
	/* destroy network */
	awnn_destroy(context);
	return 0;
}

void* network_1_demo(void* arg)
{
	struct thread_param *network_param = (struct thread_param*)arg;
	char *nbg = network_param->model_path;
	char *input = network_param->input_path;

	/* create network */
	Awnn_Context_t *context = awnn_create(nbg);
	/* copy input */
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
	/* trans RGBRGBRGB to BBBGGGRRR */
	for (i = 0; i < depth; i++) {
		unsigned int offset = width * height * i;
		float mean = means[i];
		float std = stds[i];
		for (j = 0; j < width * height; j++)
		{
			plant_data[j + offset] = (((float)data[j * depth + i] - mean) / std) / scale + zeropoint; /* Normalized and Quantized */
			/* plant_data[j + offset] = data[j * depth + i]; */
		}
	}
	void *input_buffers[] = {plant_data};
	awnn_set_input_buffers(context, input_buffers);

	for (i = 0; i < 100; i++) {
		/* process network */
		printf("2\n");
		awnn_run(context);
		sleep(1);
	}

	/* awnn_dump_io(context, "out/yolact"); */
	/* get result */
	float **results = awnn_get_output_buffers(context);

	free(data);
	free(plant_data);
	/* destroy network */
	awnn_destroy(context);
	return 0;
}

int main(int argc, char** argv)
{
	if (argc < 2) {
		printf("input error.\n");
		return -1;
	}
	char* model_file = argv[1];
	char* input_file = argv[2];
	char* model_1_file = argv[3];
	char* input_1_file = argv[4];

	printf("model_0_file=%s, input_0=%s, model_1_file=%s, input_1=%s \n", model_file, input_file, model_1_file, input_1_file);

	struct thread_param thread_0_param, thread_1_param;
	thread_0_param.model_path = model_file;
	thread_0_param.input_path = input_file;
	thread_1_param.model_path = model_1_file;
	thread_1_param.input_path = input_1_file;

	/* npu init */
	awnn_init();

	pthread_t mythread1, mythread2;
	void* thread_result;

	int res = 0;
	res = pthread_create(&mythread1, NULL, network_0_demo, (void*)&thread_0_param);
	if (res != 0) {
		printf("pthread 1 create fail. \n");
		return 0;
	}

	res = pthread_create(&mythread2, NULL, network_1_demo, (void*)&thread_1_param);
	if (res != 0) {
		printf("pthread 2 create fail. \n");
		return 0;
	}

	res = pthread_join(mythread1, &thread_result);
	res = pthread_join(mythread2, &thread_result);

	/* npu uninit */
	awnn_uninit();

	/*
	 * exit
	 * exit function run in NetworkItem::~NetworkItem()
	 */

	return res;
}

