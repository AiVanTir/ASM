#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"
#include "image_io.h"
#include <stdio.h>
#include <stdlib.h>

uint8_t* load_bmp_as_grayscale(const char* filename, int* width, int* height) {
    int n;
    uint8_t* data = stbi_load(filename, width, height, &n, 1);
    if (!data) {
        fprintf(stderr, "Error loading image: %s\n", filename);
        return NULL;
    }
    return data;
}

int save_grayscale_bmp(const char* filename, uint8_t* data, int width, int height) {
    return stbi_write_bmp(filename, width, height, 1, data);
}


