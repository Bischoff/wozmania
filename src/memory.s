// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Memory management

.global allocate_memory
.global load_rom
.global fetch_b_addr
.global fetch_h_addr
.global nothing_to_read
.global store_b_addr
.global nothing_to_write
.global language_card
.global stat

.include "src/defs.s"
.include "src/macros.s"

// Allocate:
// - memory         0x10000
// - language card   0x4000
// - drive1         0x38e00
// - drive2         0x38e00
//                  -------
//                  0x85c00
allocate_memory:
	mov	w0,#0
	mov	w1,#0x5c00
	movk	w1,#8,lsl #16
	mov	w2,#(PROT_READ|PROT_WRITE)
	mov	w3,#(MAP_PRIVATE|MAP_ANONYMOUS)
	mov	x4,#-1
	mov	w5,#0
	mov	w8,#MMAP
	svc	0
	cmp	x0,#-1
	b.eq	allocate_error
	mov	MEM,x0
	mov	w1,#0x4000
	movk	w1,#1,LSL #16
	add	x0,x0,x1
	ldr	x1,=drive1
	str	x0,[x1,#DRV_CONTENT]
	mov	w1,#0x8e00
	movk	w1,#3,lsl #16
	add	x0,x0,x1
	ldr	x1,=drive2
	str	x0,[x1,#DRV_CONTENT]
	br	lr
allocate_error:
	adr	x3,msg_err_memory
	write	STDERR,28
	b	final_exit

// Load ROM file
load_rom:
	mov	w0,#-100		// open ROM file
	adr	x1,rom_filename
	mov	w2,#O_RDONLY
	mov	w8,#OPENAT
	svc	0
	cmp	x0,#-1
	b.eq	load_failure_rom
	mov	w9,w0			// get file size
	mov	w4,#FLG_LOADED
	ldr	x1,=stat
	mov	w8,#FSTAT
	svc	0
	cmp	x0,#0
	b.lt	load_failure_rom
	ldr	x1,=stat
	ldr	x2,[x1,#ST_SIZE]
	mov	w0,w9			// read ROM file
	add	x1,MEM,#0x10000
	sub	x1,x1,x2
	cmp	x2,#0x10000
	b.ge	load_failure_rom
	mov	w8,#READ
	svc	0
	cmp	x0,x2
	b.ne	load_failure_rom
	br	lr
load_failure_rom:
	adr	x3,msg_err_load_rom
	write	STDERR,36
	b	final_exit

// Fetch byte from memory, taking into account I/O
//   input:  ADDR  = address where to store the byte to read
//   output: VALUE = byte read
//   this routine makes registers dirty and must be called very last when emulating an instruction
fetch_b_addr:
	cmp	ADDR,#0xC000
	b.ge	fetch_b_not_ram
	ldrb	VALUE,[MEM,ADDR_64]	// Normal RAM
	br	lr
fetch_b_not_ram:
	cmp	ADDR,#0xD000		// I/O area
	b.lt	fetch_b_io
	cmp	ADDR,#0xE000		// $D000-$DFFF card's bank 1 or bank 2 or normal ROM
	b.lt	fetch_b_d
					// $E000-$F7FF card's bank 1 or normal ROM
	b	fetch_b_ef		// $F800-$FFFF card's bank 1 or normal ROM or card's ROM
fetch_b_io:
	ldrb	VALUE,[MEM,ADDR_64]
	mov	w0,#KBDSTRB		// $C000-$C010 keyboard
	cmp	ADDR,w0
	b.le	keyboard
	mov	w0,#RAM_CTL_BEGIN	// $C080-$C08B language card control
	cmp	ADDR,w0
	b.lt	nothing_to_read
	mov	w0,#RAM_CTL_END
	cmp	ADDR,w0
	b.le	language_card
	mov	w0,#IWM_PHASE0OFF	// $C0E0-$C0EF floppy disk
	cmp	ADDR,w0
	b.lt	nothing_to_read
	mov	w0,#IWM_WRITEMODE
	cmp	ADDR,w0
	b.le	floppy_disk_read
	br	lr
fetch_b_d:
	tst	MEM_FLAGS,#LC_R
	b.ne	1f
	ldrb	VALUE,[MEM,ADDR_64]	// normal ROM, unchanged
	br	lr
1:	tst	MEM_FLAGS,#LC_2
	b.ne	2f
	add	ADDR,ADDR,#0x3000
	ldrb	VALUE,[MEM,ADDR_64]	// card's RAM, $D000 -> $10000
	br	lr
2:	add	ADDR,ADDR,#0x6000
	ldrb	VALUE,[MEM,ADDR_64]	// card's RAM 2, $D000 -> $13000
	br	lr
fetch_b_ef:
	tst	MEM_FLAGS,#LC_R
	b.ne	1f
	ldrb	VALUE,[MEM,ADDR_64]	// normal ROM, unchanged
	br	lr
1:	add	ADDR,ADDR,#0x3000	// card's RAM, $E000 -> $11000
	ldrb	VALUE,[MEM,ADDR_64]
	br	lr
nothing_to_read:
	br	lr

// Same, half-word
fetch_h_addr:
	cmp	ADDR,#0xC000
	b.ge	fetch_h_not_ram
	ldrh	VALUE,[MEM,ADDR_64]	// Normal RAM
	br	lr
fetch_h_not_ram:
	cmp	ADDR,#0xD000		// I/O area
	b.lt	fetch_h_io
	cmp	ADDR,#0xE000		// $D000-$DFFF card's bank 1 or bank 2 or normal ROM
	b.lt	fetch_h_d
					// $E000-$F7FF card's bank 1 or normal ROM
	b	fetch_h_ef		// $F800-$FFFF card's bank 1 or normal ROM or card's ROM
fetch_h_io:
	ldrh	VALUE,[MEM,ADDR_64]	// Optimization: don't trigger I/O when reading 16-bit addresses
	br	lr
fetch_h_d:
	tst	MEM_FLAGS,#LC_R
	b.ne	1f
	ldrh	VALUE,[MEM,ADDR_64]	// normal ROM, unchanged
	br	lr
1:	tst	MEM_FLAGS,#LC_2
	b.ne	2f
	add	ADDR,ADDR,#0x3000
	ldrh	VALUE,[MEM,ADDR_64]	// card's RAM, $D000 -> $10000
	br	lr
2:	add	ADDR,ADDR,#0x6000
	ldrh	VALUE,[MEM,ADDR_64]	// card's RAM 2, $D000 -> $13000
	br	lr
fetch_h_ef:
	tst	MEM_FLAGS,#LC_R
	b.ne	1f
	ldrh	VALUE,[MEM,ADDR_64]	// normal ROM, unchanged
	br	lr
1:	add	ADDR,ADDR,#0x3000	// card's RAM, $E000 -> $11000
	ldrh	VALUE,[MEM,ADDR_64]
	br	lr

// Store byte from memory, taking into account I/O
//   input: ADDR  = 6502 address of byte to write
//          VALUE = byte to write
//   this routine makes registers dirty and must be called very first when emulating an instruction
store_b_addr:
	cmp	ADDR,#0xC000
	b.ge	store_b_not_ram
	strb	VALUE,[MEM,ADDR_64]	// Normal RAM or text
	cmp	ADDR,#0x0400		// $0400-$07FF 40 columns text
	b.lt	1f
	cmp	ADDR,#0x0800
	b.lt	text
1:	br	lr
store_b_not_ram:
	cmp	ADDR,#0xD000		// I/O area
	b.lt	store_b_io
	cmp	ADDR,#0xE000		// $D000-$DFFF card's bank 1 or bank 2 or normal ROM
	b.lt	store_b_d
					// $E000-$F7FF card's bank 1 or normal ROM
	b	store_b_ef		// $F800-$FFFF card's bank 1 or normal ROM or card's ROM
store_b_io:
	strb	VALUE,[MEM,ADDR_64]
	mov	w0,#RAM_CTL_BEGIN	// $C080-$C08B language card control
	cmp	ADDR,w0
	b.lt	nothing_to_write
	mov	w0,#RAM_CTL_END
	cmp	ADDR,w0
	b.le	language_card
	mov	w0,#IWM_PHASE0OFF	// $C0E0-$C0EF floppy disk
	cmp	ADDR,w0
	b.lt	nothing_to_write
	mov	w0,#IWM_WRITEMODE
	cmp	ADDR,w0
	b.le	floppy_disk_write
	br	lr
store_b_d:
	tst	MEM_FLAGS,#LC_W
	b.ne	1f
	br	lr			// normal ROM or write-protected RAM
1:	tst	MEM_FLAGS,#LC_2
	b.ne	2f
	add	ADDR,ADDR,#0x3000	// card's RAM, $D000 -> $10000
	strb	VALUE,[MEM,ADDR_64]
	br	lr
2:	add	ADDR,ADDR,#0x6000	// card's RAM 2, $D000 -> $13000
	strb	VALUE,[MEM,ADDR_64]
	br	lr
store_b_ef:
	tst	MEM_FLAGS,#LC_W
	b.ne	1f
	br	lr			// normal ROM or card's ROM or write-protected RAM
1:	add	ADDR,ADDR,#0x3000	// card's RAM, $E000 -> $11000
	strb	VALUE,[MEM,ADDR_64]
	br	lr
nothing_to_write:
	br	lr

// Language card control
language_card:
	//br	disable_langcard	// Uncomment to deactivate the language card
	mov	w0,#RAM_CTL_BEGIN
	sub	w1,ADDR,w0
	adr	x0,language_table
	ldrb	MEM_FLAGS,[x0,x1]
disable_langcard:
	br	lr


// Fixed data

rom_filename:
	.asciz	"APPLE2.ROM"
msg_err_memory:
	.ascii	"Failed to allocate memory\n"
msg_err_load_rom:
	.ascii	"Could not load ROM file APPLE2.ROM\n"
language_table:
	.byte	LC_R        | LC_2 | LC_Z // $C080
	.byte	       LC_W | LC_2 | LC_Z
	.byte	              LC_2 | LC_Z
	.byte	LC_R | LC_W | LC_2 | LC_Z
	.byte	LC_R        | LC_2 | LC_Z
	.byte	       LC_W | LC_2 | LC_Z
	.byte	              LC_2 | LC_Z
	.byte	LC_R | LC_W | LC_2 | LC_Z
	.byte	LC_R               | LC_Z // $C088
	.byte	       LC_W        | LC_Z
	.byte	                     LC_Z
	.byte	LC_R | LC_W        | LC_Z
	.byte	LC_R               | LC_Z
	.byte	       LC_W        | LC_Z
	.byte	                     LC_Z
	.byte	LC_R | LC_W        | LC_Z


// Variable data

.data

stat:
	.fill	SIZEOF_STAT,1,0
