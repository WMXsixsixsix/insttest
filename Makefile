OBJ_DIR = build
SRCS = $(shell find src/ -name "*.S")
OBJS = $(patsubst %.S, $(OBJ_DIR)/%.o, $(SRCS))
APP = $(OBJ_DIR)/insttest-mips32-npc

CFLAGS  = -D_KERNEL -fno-builtin -nostdinc -nostdlib
CFLAGS += -EL -O2 -mno-abicalls -g -Iinclude -I.
CFLAGS += -DHAS_TLB

.DEAULT_GOAL = all

all: $(APP).elf

$(OBJ_DIR)/%.o: %.S
	@mkdir -p $(@D)
	@mips-linux-gnu-gcc -MMD $(CFLAGS) -c $< -o $@
	@echo + $<

-include $(OBJS:.o=.d)

$(APP).elf: $(OBJ_DIR)/src/start.o $(filter-out $(OBJ_DIR)/src/start.o,$(OBJS))
	@echo + $@
	@mips-linux-gnu-ld --gc-sections -EL -T ./loader.ld -e _start -o $@ --start-group $^ --end-group
	@mips-linux-gnu-objcopy --set-section-flags .bss=alloc,contents -O binary $@ $(APP).bin
	@echo + $(APP).bin
	@mips-linux-gnu-objdump -D $@ > $(APP).txt
	@echo + $(APP).txt
	@truncate -s %8 $(APP).bin
	@hexdump -ve '2/ "%08x " "\n"' $(APP).bin | awk '{print $$2$$1}' > $(APP).bin.txt
	@echo + $(APP).bin.txt

clean:
	rm -rf $(OBJ_DIR)
