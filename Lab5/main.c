#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "image_io.h"
#include "edge_c.h"

extern void edge_detect_asm(uint8_t* input, uint8_t* output, int width, int height);

int main(int argc, char* argv[]) {
    if (argc < 4) {
        fprintf(stderr, "Usage: %s input.bmp output.bmp mode(c|asm)\n", argv[0]);
        return 1;
    }

    int width, height;
    uint8_t* gray = load_bmp_as_grayscale(argv[1], &width, &height);
    if (!gray) return 1;

    uint8_t* output = malloc(width * height);
    if (!output) {
        perror("malloc");
        free(gray);
        return 1;
    }

    if (strcmp(argv[3], "c") == 0) {
        edge_detect_c(gray, output, width, height);
    } else if (strcmp(argv[3], "asm") == 0) {
        edge_detect_asm(gray, output, width, height);
    } else {
        fprintf(stderr, "Invalid mode. Use 'c' or 'asm'\n");
        free(gray); free(output);
        return 1;
    }

    save_grayscale_bmp(argv[2], output, width, height);
    free(gray);
    free(output);
    return 0;
}

