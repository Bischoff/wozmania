ASFLAGS :=

DEBUG ?= false
ifneq ($(DEBUG), false)
  ASFLAGS += -g
  $(info enabling debug symbols)
endif

TRACE ?= false
ifneq ($(TRACE), false)
  ASFLAGS += --defsym TRACE=1
  $(info enabling trace output)
endif

BREAK ?= false
ifneq ($(BREAK), false)
  ASFLAGS += --defsym BREAK=1
  $(info enabling 6502 breakpoints)
endif

CHECK ?= false
ifneq ($(CHECK), false)
  ASFLAGS += --defsym CHECK=1
  $(info enabling register checks)
endif

F_READ ?= false
ifneq ($(F_READ), false)
  ASFLAGS += --defsym F_READ=1
  $(info enabling floppy read printout)
endif

F_WRITE ?= false
ifneq ($(F_WRITE), false)
  ASFLAGS += --defsym F_WRITE=1
  $(info enabling floppy write printout)
endif

$(info  )

sources := emulator.s processor.s memory.s langcard.s floppy.s keyboard.s screen.s config.s debug.s
objects := $(sources:.s=.o)

wozmania: $(objects)
	ld $(objects) -o $@

%.o: src/%.s src/defs.s src/macros.s
	as $(ASFLAGS) $< -o $@

.PHONY: install
install: wozmania wozmania.conf disks/blank.nib disks/blank.dsk
	cp wozmania /usr/bin
	cp wozmania.conf /etc
	mkdir -p /var/lib/wozmania/disks
	cp disks/blank.* /var/lib/wozmania/disks/
	mkdir -p /var/lib/wozmania/roms
	cp roms/* /var/lib/wozmania/roms

.PHONY: clean
clean:
	rm -f $(objects) wozmania
