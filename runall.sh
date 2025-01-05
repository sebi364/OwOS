#!/usr/bin/bash
make clean
make
floating qemu-system-i386 -fda build/main_floppy.img