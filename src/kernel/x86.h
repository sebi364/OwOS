#pragma once
#include "stdint.h"

void _cdecl x86_Video_WriteCharTeletype(char c, uint8_t page);
void _cdecl x86_Video_WritePixelVideo(uint16_t x, uint16_t y, uint8_t color);
