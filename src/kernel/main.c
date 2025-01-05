#include "stdint.h"
#include "stdio.h"
#include "colors.h"
#include "x86.h"

void _cdecl render_frame() {
    uint16_t x;
    uint16_t y;
    uint8_t color = 1;
    for (y = 0; y <= 200; y += 1){
        for (x = 0; x <= 320; x += 1) {
            x86_Video_WritePixelVideo(x, y, color);
        }
        color += 1;
    }
}

void _cdecl cstart_(uint16_t bootDrive) {
    render_frame();
    for (;;);
}
