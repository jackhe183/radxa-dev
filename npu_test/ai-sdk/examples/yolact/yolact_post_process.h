#ifndef __YOLOV5_POST_PROCESS_H__
#define __YOLOV5_POST_PROCESS_H__
#ifdef __cplusplus
       extern "C" {
#endif

int yolact_post_process(float **results, unsigned char *pixels);

#ifdef __cplusplus
}
#endif

#endif
