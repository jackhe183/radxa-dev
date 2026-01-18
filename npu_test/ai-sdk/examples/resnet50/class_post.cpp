/*
 * Company:    AW
 * Author:     Penng
 * Date:    2022/09/23
 */
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <iostream>
#include <stdio.h>
#include <vector>
#include <cmath>
#include <sys/time.h>

#include "label.h"
#include "class_post.h"

using namespace std;


/***************************  get top5  **************************************/
void get_top5(float *buf, unsigned int num)
{
	int j = 0;
	unsigned int class_idx[5] = {0};
	float max_prob[5] = {0.0};

	unsigned int *p_class_idx = class_idx;
	float *p_max_prob = max_prob;

	unsigned int i = 0;

	for (j = 0; j < 5; j++)
	{
		for (i=0; i<num; i++)
		{
			if ((i == *(p_class_idx+0)) || (i == *(p_class_idx+1)) || (i == *(p_class_idx+2)) ||
			    (i == *(p_class_idx+3)) || (i == *(p_class_idx+4)))
			{
				continue;
			}

			if (buf[i] > *(p_max_prob+j))
			{
				*(p_max_prob+j) = buf[i];
				*(p_class_idx+j) = i;
			}
		}
	}
	printf("========== top5 ========== \n");
	for (i=0; i<5; i++)
	{
		printf("class id: %3d, prob: %f, label: %s \n", p_class_idx[i], p_max_prob[i], labels[p_class_idx[i]]);
	}
}

int class_postprocess(float **output)
{
	printf("class_postprocess.cpp run. \n");

/*
 *	cv::Mat m = cv::imread(imagepath, 1);
 *	if (m.empty())
 *	{
 *		fprintf(stderr, "cv::imread %s failed\n", imagepath);
 *		return -1;
 *	}
 */

	get_top5(output[0], 1000);

	return 0;
}

