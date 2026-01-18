/*
 * Company:    AW
 * Author:     Penng
 * Date:    2022/09/22
 */

#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <iostream>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
/* #include <vector> */


void get_input_data(const char* image_file, unsigned char* input_data, int input_h, int input_w)
{
	cv::Mat sample = cv::imread(image_file, 1);
	cv::Mat img;

	if (sample.channels() == 1)
		cv::cvtColor(sample, img, cv::COLOR_GRAY2RGB);
	else
		cv::cvtColor(sample, img, cv::COLOR_BGR2RGB);

	if ((img.rows != input_h) || (img.cols != input_w))
		cv::resize(img, img, cv::Size(input_h, input_w));

	unsigned char* img_data = img.data;

	/* nhwc to nchw */
	for (int h = 0; h < input_h; h++)
	{
		for (int w = 0; w < input_w; w++)
		{
			for (int c = 0; c < 3; c++)
			{
				int in_index = h * input_w * 3 + w * 3 + c;
				int out_index = c * input_h * input_w + h * input_w + w;

				/* input dequant */
				input_data[out_index] = (unsigned char)(img_data[in_index]);	/* uint8 */
				/*input_data[out_index] = (int8_t)(img_data[in_index] - 128); */
			}
		}
	}
}


uint8_t *class_preprocess(const char* imagepath, unsigned int *file_size)
{
	printf("class_preprocess.cpp run. \n");

	int img_c = 3;

	/* set default  size */
	int input_size = 224;	/* 224 x 224 */
	int img_size = input_size * input_size * img_c;

	*file_size = img_size * sizeof(uint8_t);

	uint8_t *tensorData = NULL;
	tensorData = (uint8_t *)malloc(1 * img_size * sizeof(uint8_t));

	get_input_data(imagepath, tensorData, input_size, input_size);

	return tensorData;
}




