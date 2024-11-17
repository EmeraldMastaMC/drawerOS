AS = as
CC = gcc
ZC = zig build-obj
CFLAGS = -fno-stack-protector -ffreestanding -m64 -Ttext 0x7E00
ZFLAGS = -fno-stack-protector -target x86_64-freestanding-none -fbuiltin -OReleaseFast
LINKER_SCRIPT = linker.ld
LINKER = ld -T $(LINKER_SCRIPT)
SRC_DIR = ./src
OBJ_DIR = ./obj
BIN = drawerOS

SRCS := $(shell find $(SRC_DIR) -type f \( -name '*.s' -o -name '*.c' -o -name '*.zig' \))
OBJS := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRCS))
OBJS := $(patsubst $(SRC_DIR)/%.s,$(OBJ_DIR)/%.o,$(OBJS))
OBJS := $(patsubst $(SRC_DIR)/%.zig,$(OBJ_DIR)/%.o,$(OBJS))

.PHONY: all build clean run dissasemble

all: build

build: $(BIN)

$(BIN): $(OBJS) 
	@find $(OBJ_DIR) -type f -name '*.o.o' -delete
	@$(LINKER) $^ -o $@
	@echo '[LD] $^'

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(dir $@)
	@$(CC) $(CFLAGS) -c $< -o $@
	@echo '[CC] $<'

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.s
	@mkdir -p $(dir $@)
	@$(AS) -o $@ $<
	@echo '[AS] $<'

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.zig
	@mkdir -p $(dir $@)
	@$(ZC) $(ZFLAGS) -femit-bin=$@ $<
	@echo '[ZC] $<'


clean:
	@echo '[INFO] Removing $(OBJ_DIR)'
	@rm -rf $(OBJ_DIR)
	@echo '[INFO] Removing $(BIN)'
	@rm -rf $(BIN)

run:
	@echo '[INFO] Running QEMU'
	@qemu-system-x86_64 -device ich9-ahci,id=sata \
											-drive file=$(BIN),format=raw,media=disk \
											-d int \
											-m 4G \
											-device qemu-xhci \
											-bios /usr/share/qemu/bios-256k.bin \
											-machine pc,accel=kvm \
											-cpu host \
											-boot order=c \


run-nokvm:
	@echo '[INFO] Running QEMU'
	@qemu-system-x86_64 -drive file=$(BIN),media=disk,format=raw -d int -m 4G

dissasemble:
	@echo '[INFO] Disassembling $(BIN)'
	@objdump -b binary -m i386:x86-64 -D $(BIN)
