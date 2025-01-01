SRC_DIR=./src
BUILD_DIR=./build

# assemble bootloader
$(BUILD_DIR)/main.bin: $(SRC_DIR)/main.asm
	nasm $(SRC_DIR)/main.asm  -f bin -o $(BUILD_DIR)/main.bin

# copy compiled file and truncate it so
# so the resulting image has 1.4 MB
$(BUILD_DIR)/main_floppy.img: $(BUILD_DIR)/main.bin
	cp $(BUILD_DIR)/main.bin $(BUILD_DIR)/main_floppy.img
	truncate -s  1440K $(BUILD_DIR)/main_floppy.img