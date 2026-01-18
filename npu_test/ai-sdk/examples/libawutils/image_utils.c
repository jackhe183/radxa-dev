#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "jpeglib.h"

#include "image_utils.h"

static int convertJpegToBmpData(FILE * inputFile, unsigned char* bmpData, unsigned int *bmpWidth, unsigned int *bmpHeight)
{
    struct jpeg_decompress_struct cinfo;
    struct jpeg_error_mgr jerr;
    JSAMPARRAY buffer;
    unsigned char *point = NULL;
    unsigned long width, height;
    unsigned short depth = 0;

    cinfo.err = jpeg_std_error(&jerr);
    jpeg_create_decompress(&cinfo);
    jpeg_stdio_src(&cinfo, inputFile);
    jpeg_read_header(&cinfo,TRUE);

    cinfo.dct_method = JDCT_IFAST;

    if (bmpData == NULL)
    {
        width = cinfo.image_width;
        height = cinfo.image_height;
    }
    else
    {
        jpeg_start_decompress(&cinfo);

        width  = cinfo.output_width;
        height = cinfo.output_height;
        depth  = cinfo.output_components;

        buffer = (*cinfo.mem->alloc_sarray)
            ((j_common_ptr)&cinfo, JPOOL_IMAGE, width*depth, 1);

        point = bmpData;

        while (cinfo.output_scanline < height)
        {
            jpeg_read_scanlines(&cinfo, buffer, 1);
            memcpy(point, *buffer, width * depth);
            point += width * depth;
        }

        jpeg_finish_decompress(&cinfo);
    }

    jpeg_destroy_decompress(&cinfo);

    if (bmpWidth != NULL) *bmpWidth = width;
    if (bmpHeight != NULL) *bmpHeight = height;
    return depth;
}

// jpg file --> BMP data(dataformat: RGBRGBRGB...) --> BBBGGGRRR
unsigned int decode_jpeg(const char *name, unsigned char* bmpData)
{
    FILE *bmpFile = NULL;
    unsigned int width = 0, height = 0, depth = 0;

    bmpFile = fopen( name, "rb" );
    if (bmpFile == NULL) goto final;

    depth = convertJpegToBmpData(bmpFile, bmpData, &width, &height);

final:
    if(bmpFile)fclose(bmpFile);
    return width * height * depth;
}

void* get_jpeg_image_data(const char *name, unsigned int width, unsigned int height, unsigned int channels)
{
    unsigned char *bmpData;

    bmpData = (unsigned char*) malloc(width * height * channels * sizeof(unsigned char));
    if (bmpData == NULL) return NULL;
    memset(bmpData, 0, sizeof(unsigned char) * width * height * channels);

    decode_jpeg(name, bmpData);

    return bmpData;
}

static void convertBmpDataToJpeg(FILE * outputFile, unsigned char* bmpData, unsigned int width, unsigned int height)
{
    struct jpeg_compress_struct cinfo;
    struct jpeg_error_mgr jerr;
    JSAMPARRAY buffer;
    unsigned char *point = NULL;
    unsigned int depth = 3;

    cinfo.err = jpeg_std_error(&jerr);
    jpeg_create_compress(&cinfo);
    jpeg_stdio_dest(&cinfo, outputFile);

    cinfo.image_width = width;
    cinfo.image_height = height;
    cinfo.input_components = depth;
    cinfo.in_color_space = JCS_EXT_RGB;
    jpeg_set_defaults(&cinfo);
    jpeg_set_quality(&cinfo, 90, TRUE);
    cinfo.dct_method = JDCT_IFAST;
    jpeg_default_colorspace(&cinfo);

    jpeg_start_compress(&cinfo, TRUE);

    buffer = (*cinfo.mem->alloc_sarray)
        ((j_common_ptr)&cinfo, JPOOL_IMAGE, width*depth, 1);

    point = bmpData;

    while (cinfo.next_scanline < cinfo.image_height) {
        memcpy(*buffer, point, width * depth);
        jpeg_write_scanlines(&cinfo, buffer, 1);
        point += width * depth;
    }

    jpeg_finish_compress(&cinfo);

    jpeg_destroy_compress(&cinfo);

}

void save_jpeg(const char *name, unsigned char* bmpData, unsigned int width, unsigned int height)
{
    FILE *bmpFile = NULL;

    bmpFile = fopen( name, "wb" );
    if (bmpFile == NULL) goto final;

    convertBmpDataToJpeg(bmpFile, bmpData, width, height);

final:
    if(bmpFile)fclose(bmpFile);
}

void get_bin_data(const char *file_name, unsigned char *buffer, int len) {
    FILE *binFile;
    binFile = fopen(file_name, "rb");
    fread(buffer, len, 1, binFile);
    fclose(binFile);
}

void save_bin_data(const char *file_name, unsigned char *buffer, int len) {
    FILE *fp = fopen(file_name, "wb");
    if (fp != NULL) {
        fwrite(buffer, 1, len, fp);
        fclose(fp);
        fp = NULL;
    }
}
