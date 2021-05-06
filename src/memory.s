// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Memory management

.global allocate_memory
.global load_rom
.global fetch_addr
.global nothing_to_read
.global store_addr
.global nothing_to_write
.global stat

.include "src/defs.s"
.include "src/macros.s"

// Allocate:
// - memory         0x10000
// - drive1         0x38e00
// - drive2         0x38e00
//                  -------
//                  0x81c00
allocate_memory:
	mov	w0,#0
	mov	w1,#0x1c00
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
	add	x0,x0,#0x10000
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
fetch_addr:
	cmp	ADDR,#0xC000
	b.ge	fetch_not_ram
	ldrb	VALUE,[MEM,ADDR_64]	// RAM
	br	lr
fetch_not_ram:
	cmp	ADDR,#0xD000		// I/O area
	b.lt	fetch_io
	ldrb	VALUE,[MEM,ADDR_64]	// ROM
	br	lr
fetch_io:
	ldrb	VALUE,[MEM,ADDR_64]
	mov	w0,#KBDSTRB		// $C000-$C010 keyboard
	cmp	ADDR,w0
	b.le	keyboard
	mov	w0,#IWM_PHASE0OFF	// $C0E0-$C0EF floppy disk
	cmp	ADDR,w0
	b.lt	nothing_to_read
	mov	w0,#IWM_WRITEMODE
	cmp	ADDR,w0
	b.le	floppy_disk_read
	br	lr
nothing_to_read:
	br	lr

// Store byte from memory, taking into account I/O
//   input: ADDR  = 6502 address of byte to write
//          VALUE = byte to write
//   this routine makes registers dirty and must be called very first when emulating an instruction
store_addr:
	cmp	ADDR,#0xC000
	b.ge	store_not_ram
	strb	VALUE,[MEM,ADDR_64]	// Normal RAM or text
	cmp	ADDR,#0x0400		// $0400-$07FF 40 columns text
	b.lt	1f
	cmp	ADDR,#0x0800
	b.lt	text
1:	br	lr
store_not_ram:
	cmp	ADDR,#0xD000		// I/O area
	b.lt	store_io
	br	lr			// ROM
store_io:
	strb	VALUE,[MEM,ADDR_64]
	mov	w0,#IWM_PHASE0OFF	// $C0E0-$C0EF floppy disk
	cmp	ADDR,w0
	b.lt	nothing_to_write
	mov	w0,#IWM_WRITEMODE
	cmp	ADDR,w0
	b.le	floppy_disk_write
	br	lr
nothing_to_write:
	br	lr

// Fixed data

rom_filename:
	.asciz	"APPLE2.ROM"
msg_err_memory:
	.ascii	"Failed to allocate memory\n"
msg_err_load_rom:
	.ascii	"Could not load ROM file APPLE2.ROM\n"


// Variable data

.data

stat:
	.fill	SIZEOF_STAT,1,0
