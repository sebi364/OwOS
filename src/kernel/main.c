#include "stdint.h"
#include "stdio.h"
#include "colors.h"
#include "x86.h"

// simple demo to render a frame with all available colors.
// this is very inefficient and takes +/- 8s per frame
void _cdecl render_frame() {
    uint16_t x;
    uint16_t y;
    uint8_t color = 1;
    // print something to tty
    puts("\nThis is a Text, lol");
    // draw colors
    for (y = 0; y <= 180; y += 1){
        for (x = 0; x <= 320; x += 1) {
            x86_Video_WritePixelVideo(x, y + 20, color);
            color += 1;
        }
    }
}

void _cdecl cstart_(uint16_t bootDrive) {
    render_frame();
    for (;;);
}
