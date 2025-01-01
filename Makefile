SRC_DIR=./src
BUILD_DIR=./build

.PHONY: all floppy_image kernel bootloader clean always

#
# Floppy IMG
#
floppy_image: $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main_floppy.img: bootloader kernel
	# create new floppy image
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	# format with FAT12
	mkfs.fat -F 12 -n "NBOS" $(BUILD_DIR)/main_floppy.img
	# copy bootloader into filesystem
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	# copy kernel into filesystem
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"

#
# Bootloader
#
bootloader: $(BUILD_DIR)/bootloader.bin

$(BUILD_DIR)/bootloader.bin: always
	# Assemble bootloader
	nasm $(SRC_DIR)/bootloader/boot.asm  -f bin -o $(BUILD_DIR)/bootloader.bin

#
# Kernel
#
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always
	# Assemble kernel
	nasm $(SRC_DIR)/kernel/main.asm  -f bin -o $(BUILD_DIR)/kernel.bin

#
# Always
#
always:
	mkdir -p $(BUILD_DIR)

#
# Clean
#
clean:
	rm -rf $(BUILD_DIR)/*