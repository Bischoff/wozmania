// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Emulator main program

.global _start
.global emulate
.global fetch_io
.global nothing_to_read
.global store_io
.global nothing_to_write
.global exit
.global final_exit
.global stat

.include "src/defs.s"
.include "src/macros.s"

// Allocate memory (0x10000) and disk contents (0x38e00 each)
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
	mov	w0,#-100	// open ROM file
	adr	x1,rom_filename
	mov	w2,#O_RDONLY
	mov	w8,#OPENAT
	svc	0
	cmp	x0,#-1
	b.eq	load_failure_rom
	mov	w9,w0		// get file size
	mov	w4,#FLG_LOADED
	ldr	x1,=stat
	mov	w8,#FSTAT
	svc	0
	cmp	x0,#0
	b.lt	load_failure_rom
	ldr	x1,=stat
	ldr	x2,[x1,#ST_SIZE]
	mov	w0,w9		// read ROM file
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

// Put 6502 processor in initial state
reset:
	mov	A_REG,#0
	mov	X_REG,#0
	mov	Y_REG,#0
	mov	S_REG,#0
	mov	SP_REG,#0x1FF
	mov	x0,#0xFFFC
	ldrh	PC_REG,[MEM,x0]
	br	lr

// Fetch byte from memory, taking into account I/O
//   input:  ADDR          = address where to store the byte to read
//   output: [MEM,ADDR_64] = byte read
//   this routine makes registers dirty and must be called very last when emulating an instruction
fetch_io:
	cmp	ADDR,#KBD	// $C000-$C010 keyboard
	b.eq	keyboard
	mov	w0,#KBDSTRB
	cmp	ADDR,w0
	b.eq	clear_strobe
	mov	w0,#IWM_PHASE0OFF // $COE0-$C0EF floppy disk
	cmp	ADDR,w0
	b.lt	nothing_to_read
	mov	w0,#IWM_WRITEMODE
	cmp	ADDR,w0
	b.le	floppy_disk_read
nothing_to_read:
	br	lr

// Store byte from memory, taking into account I/O
//   input: ADDR          = 6502 address of byte to write
//          [MEM,ADDR_64] = byte to write
//   this routine makes registers dirty and must be called very first when emulating an instruction

store_io:
	cmp	ADDR,#LINE1	// $0400-$07FF 40 columns text
	b.lt	nothing_to_write
	cmp	ADDR,#PRGMEM
	b.lt	text
	mov	w0,#IWM_PHASE0OFF // $C0E0-$C0EF floppy disk
	cmp	ADDR,w0
	b.lt	nothing_to_write
	mov	w0,#IWM_WRITEMODE
	cmp	ADDR,w0
	b.le	floppy_disk_write
nothing_to_write:
	br	lr

// Main loop
_start:
	adr	INSTR,instr_table
	ldr	KEYBOARD,=kbd
	ldr	DRIVE,=drive1
	ldr	BREAKPOINT,=breakpoint
	bl	allocate_memory
	bl	load_rom
	bl	load_drive1
	bl	load_drive2
	//bl	disable_drives	// uncomment this line to disconnect the drives
	bl	prepare_terminal
	bl	prepare_keyboard
coldstart:
	bl	intercept_ctl_c
	bl	reset
emulate:
	//bl	trace		// uncomment these lines according to your debugging needs
	//bl	break
	//bl	check
	ldrb	w0,[KEYBOARD,#KBD_RESET]
	tst	w0,#0xFF
	b.ne	coldstart
next:				// trace each instruction with "b next"
	ldrb	w0,[MEM,PC_REG_64]
	add	PC_REG,PC_REG,#1
	ldr	x1,[INSTR,x0,LSL 3]
	br	x1


// Exit
exit:
	ldr	DRIVE,=drive1	// flush dirty drives
	bl	flush_drive
	ldr	DRIVE,=drive2
	bl	flush_drive
	bl	restore_keyboard // restore normal keyboard
final_exit:
	mov	x0,#0		// exit program
	mov	x8,#93
	svc	0

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
