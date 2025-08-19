#include "edge_c.h"

void edge_detect_c(uint8_t* input, uint8_t* output, int width, int height) {
    int kernel[3][3] = {
        {-1, -1, -1},
        {-1,  8, -1},
        {-1, -1, -1}
    };

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int sum = 0;

            for (int ky = -1; ky <= 1; ky++) {
                for (int kx = -1; kx <= 1; kx++) {
                    int px = x + kx;
                    int py = y + ky;

                    if (px < 0) px = 0;
                    if (py < 0) py = 0;
                    if (px >= width) px = width - 1;
                    if (py >= height) py = height - 1;

                    sum += input[py * width + px] * kernel[ky + 1][kx + 1];
                }
            }

            output[y * width + x] = (sum < 0) ? 0 : (sum > 255 ? 255 : sum);
        }
    }
}
