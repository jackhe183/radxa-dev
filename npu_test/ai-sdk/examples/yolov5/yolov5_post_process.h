#ifndef __YOLOV5_POST_PROCESS_H__
#define __YOLOV5_POST_PROCESS_H__
#ifdef __cplusplus
extern "C" {
#endif

int yolov5_post_process(const char *imagepath, float **output);

#ifdef __cplusplus
}
#endif

#endif
