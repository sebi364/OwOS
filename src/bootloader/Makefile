BUILD_DIR?=./build/
ASM?=nasm

.PHONY: all clean bootloader

all: bootloader

bootloader: $(BUILD_DIR)/bootloader.bin

$(BUILD_DIR)/bootloader.bin:
	$(ASM) boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin

clean:
	rm -f $(BUILD_DIR)/bootloader.bin