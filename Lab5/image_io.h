#ifndef IMAGE_IO_H
#define IMAGE_IO_H

#include <stdint.h>

uint8_t* load_bmp_as_grayscale(const char* filename, int* width, int* height);
int save_grayscale_bmp(const char* filename, uint8_t* data, int width, int height);

#endif

