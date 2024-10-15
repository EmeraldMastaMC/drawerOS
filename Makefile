AS = as
CC = gcc
CFLAGS = -fno-stack-protector -ffreestanding -m64 -Ttext 0x7E00
LINKER_SCRIPT = linker.ld
LINKER = ld -T $(LINKER_SCRIPT)
SRC_DIR = ./src
OBJ_DIR = ./obj
BIN = drawerOS

SRCS := $(shell find $(SRC_DIR) -name '*.s' -o -name '*.c')
OBJS := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRCS))
OBJS := $(patsubst $(SRC_DIR)/%.s,$(OBJ_DIR)/%.o,$(OBJS))

.PHONY: all build clean run

all: build

build: $(BIN)

$(BIN): $(OBJS)
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

clean:
	@echo '[INFO] Removing $(OBJ_DIR)'
	@rm -rf $(OBJ_DIR)
	@echo '[INFO] Removing $(BIN)'
	@rm -rf $(BIN)

run:
	@echo '[INFO] Running QEMU'
	@qemu-system-x86_64 -drive file=$(BIN),media=disk,format=raw
