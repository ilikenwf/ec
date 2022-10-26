# SPDX-License-Identifier: GPL-3.0-or-later

# Set flash ROM parameters
FLASH_OFFSET=2048
FLASH_SIZE=1024
CFLAGS+=-DFLASH_OFFSET=$(FLASH_OFFSET) -DFLASH_SIZE=$(FLASH_SIZE)

# Copy parameters to use when compiling flash ROM
FLASH_INCLUDE=$(INCLUDE)
FLASH_CFLAGS=$(CFLAGS)

# Include flash source.
FLASH_DIR=$(SYSTEM76_COMMON_DIR)/flash
# Note: main.c *must* be first to ensure that flash_start is at the correct address
FLASH_SRC=$(FLASH_DIR)/main.c
FLASH_INCLUDE+=$(wildcard $(FLASH_DIR)/include/flash/*.h) $(FLASH_DIR)/flash.mk
FLASH_CFLAGS+=-I$(FLASH_DIR)/include -D__FLASH__

FLASH_BUILD=$(BUILD)/flash
FLASH_OBJ=$(sort $(patsubst src/%.c,$(FLASH_BUILD)/%.rel,$(FLASH_SRC)))
FLASH_CC=\
	sdcc \
	-mmcs51 \
	--model-large \
	--opt-code-size \
	--acall-ajmp \
	--code-loc $(FLASH_OFFSET) \
	--code-size $(FLASH_SIZE) \
	--Werror

# Convert from binary file to C header
$(BUILD)/include/flash.h: $(FLASH_BUILD)/flash.rom
	@mkdir -p $(@D)
	xxd -include < $< > $@

# Convert from Intel Hex file to binary file
$(FLASH_BUILD)/flash.rom: $(FLASH_BUILD)/flash.ihx
	@mkdir -p $(@D)
	objcopy -I ihex -O binary $< $@

# Link object files into Intel Hex file
$(FLASH_BUILD)/flash.ihx: $(FLASH_OBJ)
	@mkdir -p $(@D)
	$(FLASH_CC) -o $@ $^

# Compile C files into object files
$(FLASH_OBJ): $(FLASH_BUILD)/%.rel: src/%.c $(FLASH_INCLUDE)
	@mkdir -p $(@D)
	$(FLASH_CC) $(FLASH_CFLAGS) -o $@ -c $<

# Include flash header in main firmware
CFLAGS+=-I$(BUILD)/include
LDFLAGS+=-Wl -g_flash_entry=$(FLASH_OFFSET)
INCLUDE+=$(BUILD)/include/flash.h
SRC+=$(FLASH_DIR)/wrapper.c
