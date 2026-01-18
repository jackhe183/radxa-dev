#ifndef __YOLOV5_PRE_PROCESS_H__
#define __YOLOV5_PRE_PROCESS_H__
#ifdef __cplusplus
extern "C" {
#endif

unsigned char* yolov5_pre_process(const char* imagepath, unsigned int *file_size);

#ifdef __cplusplus
}
#endif

#endif
