#include "stdint.h"
#include "stdio.h"
#include "x86.h"

void _cdecl cstart_(uint16_t bootDrive) {
    uint16_t x = 0;
    uint16_t y = 0;
    for (x; x <= 320; x += 1){
        for (y; y <= 200; x += 1){
            x86_Video_WritePixelVideo(x, y);
        }
    }
    for (;;);
}
