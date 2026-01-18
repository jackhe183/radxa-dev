/*
 * Company:    AW
 * Author:     Penng
 * Date:    2023/01/16
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

#include <awnn_lib.h>

#include "image_utils.h"
#include "class_post.h"


/*-------------------------------------------
        Macros and Variables
-------------------------------------------*/


int main(int argc, char** argv)
{
	printf("%s nbg input\n", argv[0]);
	if(argc < 3)
	{
		printf("Arguments count %d is incorrect!\n", argc);
		return -1;
	}
	const char* nbg = argv[1];
	const char* input = argv[2];

	/* npu init */
	awnn_init();
	/* create network */
	Awnn_Context_t *context = awnn_create(nbg);
	/* copy input */
	unsigned int width = 224;
	unsigned int height = 224;
	unsigned int depth = 3;
	unsigned char *data = (unsigned char *) get_jpeg_image_data(input, width, height, depth);
	printf("get jpeg success.\n");
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
	printf("trans data success.\n");
	void *input_buffers[] = {plant_data};
	awnn_set_input_buffers(context, input_buffers);
	printf("awnn_set_input_buffers success.\n");
	/* process network */
	awnn_run(context);
	printf("awnn_run success.\n");
	/* get result */
	float **results = awnn_get_output_buffers(context);
	/* post process */
	class_postprocess(results);
	printf("class_postprocess success.\n");

	free(data);
	free(plant_data);
	/* destroy network */
	awnn_destroy(context);
	/* npu uninit */
	awnn_uninit();

	return 0;
}
