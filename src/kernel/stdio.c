#include "stdio.h"
#include "x86.h"

void putc(char c) {
    x86_Video_WriteCharTeletype(c, 0);
}

void puts(const char* str){
    while(*str) {
        putc(*str);
        str++;
    }
}

void drawpixel() {
    x86_Video_WritePixelVideo(319, 100, 1); // 320 x 200 max
}
