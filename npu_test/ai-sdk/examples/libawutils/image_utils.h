#ifndef __IMAGE_UTILS_H_
#define __IMAGE_UTILS_H_

unsigned int decode_jpeg(const char *name, unsigned char* bmpData);
void save_jpeg(const char *name, unsigned char* bmpData, unsigned int width, unsigned int height);
void* get_jpeg_image_data(const char *name, unsigned int width, unsigned int height, unsigned int channels);
void get_bin_data(const char *file_name, unsigned char *buffer, int len);
void save_bin_data(const char *file_name, unsigned char *buffer, int len);

#endif
