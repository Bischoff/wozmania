// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Emulator main program

.global _start
.global emulate
.global undefined
.global fetch_io
.global store_io

.include "defs.s"
.include "macros.s"


// Initialization

// allocate memory (0x10000) and disk contents (0x38e00 each)
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

// load ROM file
load_rom:
	mov	w0,#-100	// open ROM file
	adr	x1,rom_filename
	mov	w2,#O_RDONLY
	mov	w8,#OPENAT
	svc	0
	cmp	x0,#-1
	b.eq	load_failure_rom
	add	x1,MEM,#0xB000	// read ROM file
	mov	w2,#0x5000
	mov	w8,#READ
	svc	0
	cmp	x0,x2
	b.ne	load_failure_rom
	br	lr
load_failure_rom:
	adr	x3,msg_err_load_rom
	write	STDERR,36
	b	final_exit

// load drive file
load_drive1:
	ldr	DRIVE,=drive1
	mov	w5,#'1'
	b	load_drive
load_drive2:
	ldr	DRIVE,=drive2
	mov	w5,#'2'
load_drive:
	ldr	x1,=drive_filename // open disk file
	strb	w5,[x1,#5]
	mov	w0,#-100
	mov	w2,#O_RDONLY
	mov	w8,#OPENAT
	svc	0
	cmp	x0,#0
	b.lt	no_disk
	ldr	x1,[DRIVE,#DRV_CONTENT] // read disk file
	mov	w2,#0x8e00
	movk	w2,#3,lsl #16
	mov	w8,#READ
	svc	0
	cmp	x0,x2
	b.ne	load_failure_drive
	mov	w0,#FLG_LOADED	// disk is loaded
	strb	w0,[DRIVE,#DRV_FLAGS]
no_disk:
	strb	w5,[DRIVE,#DRV_NUMBER]
	br	lr
load_failure_drive:
	ldr	x3,=msg_err_load_drive
	char	w5,31
	write	STDERR,37
	b	final_exit

// optional: hide the disks by removing controller's signature
disable_drives:
	mov	w0,#DISK2ROM
	mov	w1,#JMP
	strb	w1,[MEM,x0]
	mov	w0,#(DISK2ROM + 1)
	mov	w1,#OLDRST
	strh	w1,[MEM,x0]
	br	lr

// prepare text terminal
prepare_terminal:
	adr	x3,msg_begin	// clear screen and hide cursor
	write	STDOUT,10
	mov	w0,#STDIN	// set non-blocking keyboard
	mov	w1,#TCGETS
	ldr	x2,=termios
	mov	w8,#IOCTL
	svc	0
	ldr	x2,=termios
	ldr	w0,[x2,#C_LFLAG]
	and	w0,w0,#~ICANON
	and	w0,w0,#~ECHO
	str	w0,[x2,#C_LFLAG]
	mov	w0,#1
	strb	w0,[x2,#C_CC_VTIME]
	mov	w0,#0
	strb	w0,[x2,#C_CC_VMIN]
	mov	w0,#STDIN
	mov	w1,#TCSETS
	ldr	x2,=termios
	mov	w8,#IOCTL
	svc	0
	br	lr

// intercept Ctrl-C
intercept_ctl_c:
	ldr	x1,=sigaction	// SA_MASK and SA_FLAGS entries are already zero
	adr	x0,ctl_reset
	str	x0,[x1,#SA_HANDLER]
	mov	w0,#SIGINT
	mov	x2,#0
	mov	w3,#8
	mov	w8,#RT_SIGACTION
	svc	0
	mov	w0,#0		// clear previous reset
	strb	w0,[KEYBOARD,#KBD_RESET]
	br	lr

// put 6502 processor in initial state
reset:
	mov	A_REG,#0
	mov	X_REG,#0
	mov	Y_REG,#0
	mov	S_REG,#0
	mov	SP_REG,#0x1FF
	mov	x0,#0xFFFC
	ldrh	PC_REG,[MEM,x0]
	br	lr


// Ctrl-C handler
// We emulate Ctrl-Reset key

ctl_reset:
	mov	w0,#1
	strb	w0,[KEYBOARD,#KBD_RESET]


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

// Keyboard
// Part of this code is extra complicated due to the fact we use an ANSI terminal
// That will go away when we switch to a real graphical window of our own
keyboard:
	ldrb	w0,[KEYBOARD,#KBD_STROBE]
	tst	w0,#0xFF
	b.eq	read_key
	mov	w0,#KBD_LASTKEY
	b	analyze_key
read_key:
	mov	w0,#STDIN
	mov	x1,KEYBOARD
	mov	w2,#1
	mov	w8,#READ
	svc	0
	cmp	w0,#1
	b.lt	no_key
	mov	w0,#KBD_BUFFER
analyze_key:
	ldrb	w9,[KEYBOARD,x0]
	ldrb	w0,[KEYBOARD,#KBD_KEYSEQ]
	cmp	w0,#SEQ
	b.ne	escape
	cmp	w9,#0x0A	// carriage return
	b.ne	1f
	mov	w9,#0x8D
	b	found_key
1:	cmp	w9,#0x1B
	b.ne	2f
	mov	w0,#SEQ_ESC
	strb	w0,[KEYBOARD,#KBD_KEYSEQ]
	b	no_key
2:	orr	w9,w9,#0x80
	b	found_key
escape:
	cmp	w0,#SEQ_ESC
	b.ne	escape_bracket
	cmp	w9,#'['
	b.ne	1f
	mov	w0,#SEQ_ESC_BRA
	b	3f
1:	cmp	w9,#'O'
	b.ne	2f
	mov	w0,#SEQ_ESC_O
	b	3f
2:	mov	w0,#SEQ
3:	strb	w0,[KEYBOARD,#KBD_KEYSEQ]
	b	no_key
escape_bracket:
	cmp	w0,#SEQ_ESC_BRA
	b.ne	escape_o
	cmp	w9,#'A'		// up
	b.ne	1f
	mov	w9,#0x8B
	b	5f
1:	cmp	w9,#'B'		// down
	b.ne	2f
	mov	w9,#0x8A
	b	5f
2:	cmp	w9,#'C'		// right
	b.ne	3f
	mov	w9,#0x95
	b	5f
3:	cmp	w9,#'D'		// left
	b.ne	4f
	mov	w9,#0x88
	b	5f
4:	mov	w0,#SEQ
	strb	w0,[KEYBOARD,#KBD_KEYSEQ]
	b	no_key
5:	mov	w0,#SEQ
	strb	w0,[KEYBOARD,#KBD_KEYSEQ]
	b	found_key
escape_o:
	cmp	w9,#'R'		// Ctrl-C
	b.ne	1f
	mov	w9,#0x83
	b	3f
1:	cmp	w9,#'S'		// power off
	b.ne	2f
	b	clean_exit
2:	mov	w0,#SEQ
	strb	w0,[KEYBOARD,#KBD_KEYSEQ]
	b	no_key
3:	mov	w0,#SEQ
	strb	w0,[KEYBOARD,#KBD_KEYSEQ]
	b	found_key
found_key:
	strb	w9,[KEYBOARD,#KBD_LASTKEY]
	mov	w0,#1
	strb	w0,[KEYBOARD,#KBD_STROBE]
	strb	w9,[MEM,ADDR_64]
	br	lr
no_key:
	mov	w0,#0
	strb	w0,[KEYBOARD,#KBD_STROBE]
	strb	w0,[MEM,ADDR_64]
	br	lr

// Keyboard strobe
clear_strobe:
	b	no_key

// Floppy disk (read)
floppy_disk_read:
	mov	w0,#IWM_PHASE0OFF
	sub	w1,ADDR,w0
	adr	x0,disk_table
	ldr	x2,[x0,x1,LSL 3]
	br	x2
change_track:
	lsr	w0,w1,#1	// w0 = new phase, w3 = old phase
	ldrb	w3,[DRIVE,#DRV_PHASE]
	strb	w0,[DRIVE,#DRV_PHASE]
	ldr	x2,=htrack_delta // w4 = half-track delta
	lsl	w3,w3,#2
	add	w3,w3,w0
	ldrsb	w4,[x2,x3]
	ldrb	w5,[DRIVE,#DRV_HTRACK] // compute new half-track
	adds	w5,w5,w4
	b.pl	1f
	mov	w5,#0
	b	2f
1:	cmp	w5,#80
	b.lt	2f
	mov	w5,#79
2:	strb	w5,[DRIVE,#DRV_HTRACK]
	br	lr
select_drive1:
	ldr	DRIVE,=drive1
	b	last_nibble
select_drive2:
	ldr	DRIVE,=drive2
	br	lr
transfer_nibble:
	ldr	x1,[DRIVE,#DRV_CONTENT]
	ldrb	w2,[DRIVE,#DRV_FLAGS]
	mov	w4,#6656
	ldrh	w5,[DRIVE,#DRV_HEAD]
	ldrb	w6,[DRIVE,#DRV_HTRACK]
	lsr	w7,w6,#1
	mul	w7,w7,w4
	add	w7,w7,w5
	mov	w9,#0
	tst	w2,#FLG_WRITE
	b.ne	write_nibble
read_nibble:
	and	w2,w2,#~FLG_DIRTY // only read when loaded + read mode
	and	w2,w2,#~FLG_READONLY
	cmp	w2,#FLG_LOADED
	b.ne	2f
	ldrb	w9,[x1,x7]	// read nibble at (track * 6656 + head position)
	add	w0,w5,#1	// move head forward
	cmp	w0,w4
	b.lt	1f
	mov	w0,#0
1:	strh	w0,[DRIVE,#DRV_HEAD]
2:	strb	w9,[DRIVE,#DRV_LASTNIB]
	strb	w9,[MEM,ADDR_64]
	//b	print_nibble	// uncomment this line to debug
	b	last_nibble
write_nibble:
	and	w2,w2,#~FLG_DIRTY // only write when loaded + write mode + not read-only
	cmp	w2,#(FLG_LOADED|FLG_WRITE)
	b.ne	2f
	ldrb	w9,[DRIVE,#DRV_NEXTNIB]	// write nibble to (track * 6656 + head position)
	strb	w9,[x1,x7]
	add	w0,w5,#1	// move head forward
	cmp	w0,w4
	b.lt	1f
	mov	w0,#0
1:	strh	w0,[DRIVE,#DRV_HEAD]
	orr	w2,w2,#FLG_DIRTY
	strb	w2,[DRIVE,#DRV_FLAGS]
2:
	//b	print_nibble	// uncomment this line to debug
	b	last_nibble
sense_protection:
	ldrb	w0,[DRIVE,#DRV_FLAGS]
	and	w9,w0,#FLG_READONLY
	strb	w9,[DRIVE,#DRV_LASTNIB]
	br	lr
read_mode:
	ldrb	w0,[DRIVE,#DRV_FLAGS]
	and	w0,w0,#~FLG_WRITE
	strb	w0,[DRIVE,#DRV_FLAGS]
	b	last_nibble
last_nibble:
	ldrb	w9,[DRIVE,#DRV_LASTNIB]
	strb	w9,[MEM,ADDR_64]
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

// 40 columns text
text:
	ldr	x3,=msg_text
	mov	w2,ADDR		// line and column
	sub	w2,w2,#LINE1
	and	w0,w2,#0x7F
	lsr	w2,w2,#7
	mov	w4,#40
	udiv	w1,w0,w4
	msub	w5,w1,w4,w0
	cmp	w1,#3
	b.ge	screen_hole
	lsl	w1,w1,#3
	orr	w2,w2,w1
	add	w2,w2,#1
	dec_8	w2,2
	add	w5,w5,#1
	dec_8	w5,5
	ldrb	w1,[MEM,ADDR_64] // text effect and text
	lsr	w0,w1,#2
	and	w0,w0,#0xF8
	adr	x4,video_table
	ldr	x2,[x4,x0]
	br	x2
inverse:
	add	w1,w1,#0x40
inverse1:
	mov	w2,#'7'
	b	effect
flash:
	sub	w1,w1,#0x40
	cmp	w1,#' '
	b.eq	inverse1	// normally, blinking inverse space
flash1:
	mov	w2,#'5'
	b	effect
normal:
	and	w1,w1,#0x7F
	mov	w2,#'0'
effect:
	char	w2,10
	char	w1,12
	write	STDOUT,13
screen_hole:
	br	lr

// Floppy disk (write)
floppy_disk_write:
	mov	w0,IWM_WRITEMODE
	cmp	ADDR,w0
	b.ne	load_next_nibble
write_mode:
	ldrb	w0,[DRIVE,#DRV_FLAGS]
	orr	w0,w0,#FLG_WRITE
	strb	w0,[DRIVE,#DRV_FLAGS]
load_next_nibble:
	ldrb	w9,[MEM,ADDR_64]
	strb	w9,[DRIVE,#DRV_NEXTNIB]
	br	lr


// Debugging utilities

// Trace each instruction
trace:
	adr	x2,hex
	ldr	x3,=msg_trace
	hex_16	PC_REG,4
	hex_8	SP_REG,16
	hex_8	A_REG,23
	hex_8	X_REG,30
	hex_8	Y_REG,37
	s_bit	C_FLAG,'C',51
	s_bit	Z_FLAG,'Z',50
	s_bit	I_FLAG,'I',49
	s_bit	D_FLAG,'D',48
	s_bit	B_FLAG,'B',47
	s_bit	X_FLAG,'1',46
	s_bit	V_FLAG,'V',45
	s_bit	N_FLAG,'N',44
	write	STDERR,53
	br	lr

// Break at a given 6502 address
break:
	ldrh	w0,[BREAKPOINT]
	tst	w0,#0xFFFF
	b.eq	here
	cmp	PC_REG,w0
	b.ne	1f
here:
	nop
1:	br	lr

// Check that registers are still 8 bit values
check:
	cmp	PC_REG,#0x10000
	b.ge	invalid
	cmp	SP_REG,#0x200
	b.ge	invalid
	cmp	SP_REG,#0x100
	b.lt	invalid
	cmp	A_REG,#0x100
	b.ge	invalid
	cmp	X_REG,#0x100
	b.ge	invalid
	cmp	Y_REG,#0x100
	b.ge	invalid
	cmp	S_REG,#0x100
	b.ge	invalid
	tst	S_REG,#(X_FLAG | B_FLAG)
	b.ne	invalid
	br	lr

// Print current nibble
print_nibble:
	adr	x2,hex
	ldr	x3,=msg_disk
	ldrb	w0,[DRIVE,#DRV_NUMBER]
	char	w0,7
	hex_8	w6,18
	hex_16	w5,28
	hex_8	w9,41
	write	STDERR,44
	b	last_nibble


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
	bl	intercept_ctl_c
coldstart:
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

flush_drive:
	ldrb	w0,[DRIVE,#DRV_FLAGS]
	tst	w0,#FLG_DIRTY
	b.eq	1f
	and	w0,w0,#~FLG_DIRTY	// clean dirty flag
	strb	w0,[DRIVE,#DRV_FLAGS]
	ldrb	w5,[DRIVE,#DRV_NUMBER]	// open disk file
	ldr	x1,=drive_filename
	strb	w5,[x1,#5]
	mov	w0,#-100
	mov	w2,#O_WRONLY
	mov	w8,#OPENAT
	svc	0
	cmp	x0,#0
	b.lt	flush_failure_drive
	ldr	x1,[DRIVE,#DRV_CONTENT]	// read disk file
	mov	w2,#0x8e00
	movk	w2,#3,lsl #16
	mov	w8,#WRITE
	svc	0
	cmp	x0,x2
	b.ne	flush_failure_drive
1:	br	lr
flush_failure_drive:
	ldr	x3,=msg_err_flush_drive
	char	w5,31
	write	STDERR,37
	br	lr

undefined:
	sub	PC_REG,PC_REG,#1
	adr	x3,msg_end	// go to line 25 and restore cursor
	write	STDOUT,14
	adr	x2,hex		// print error message
	ldr	x3,=msg_undefined
	hex_8	w0,22
	hex_16	PC_REG,28
	write	STDERR,33
	b	exit

invalid:
	sub	PC_REG,PC_REG,#1
	adr	x3,msg_end	// go to line 25 and restore cursor
	write	STDOUT,14
	adr	x2,hex		// print error message
	ldr	x3,=msg_invalid
	hex_16	PC_REG,26
	write	STDERR,31
	b	exit

clean_exit:
	adr	x3,msg_end	// go to line 25 and restore cursor
	write	STDOUT,14
exit:
	ldr	DRIVE,=drive1	// flush dirty drives
	bl	flush_drive
	ldr	DRIVE,=drive2
	bl	flush_drive
	ldr	x2,=termios	// restore normal keyboard
	ldr	w0,[x2,#C_LFLAG]
	orr	w0,w0,#ICANON
	orr	w0,w0,#ECHO
	str	w0,[x2,#C_LFLAG]
	mov	w0,#0
	strb	w0,[x2,#C_CC_VTIME]
	mov	w0,#1
	strb	w0,[x2,#C_CC_VMIN]
	mov	w0,#STDIN
	mov	w1,#TCSETS
	ldr	x2,=termios
	mov	w8,#IOCTL
	svc	0
final_exit:
	mov	x0,#0		// exit program
	mov	x8,#93
	svc	0


// Fixed data

video_table:
	.quad	inverse		// 00-3F
	.quad	inverse1
	.quad	flash1		// 40-7F
	.quad	flash
	.quad	normal		// 80-FF
	.quad	normal
	.quad	normal
	.quad	normal
disk_table:
	.quad	last_nibble	// $C0E0
	.quad	change_track
	.quad	last_nibble
	.quad	change_track
	.quad	last_nibble
	.quad	change_track
	.quad	last_nibble
	.quad	change_track
	.quad	last_nibble	// $C0E8
	.quad	nothing_to_read
	.quad	select_drive1
	.quad	select_drive2
	.quad	transfer_nibble
	.quad	sense_protection
	.quad	read_mode
	.quad	nothing_to_read
htrack_delta:
	.byte	 0, +1, +2, -1
	.byte	-1,  0, +1, +2
	.byte	-2, -1,  0, +1
	.byte	+1, -2, -1,  0
rom_filename:
	.asciz	"APPLE2.ROM"
hex:
	.ascii	"0123456789ABCDEF"
msg_err_memory:
	.ascii	"Failed to allocate memory\n"
msg_err_load_rom:
	.ascii	"Could not load ROM file APPLE2.ROM\n"
msg_begin:
	.ascii	"\x1B[2J\x1B[?25l"
msg_end:
	.ascii	"\x1B[25;01H\x1B[?25h"


// Variable data

.data

drive_filename:
	.asciz	"drive..nib"
msg_trace:
	.ascii	"PC: ....  SP: 01..  A: ..  X: ..  Y: ..  S: ........\n"
msg_disk:
	.ascii	"DRIVE: .  HTRACK: ..  HEAD: ....  VALUE: ..\n"
msg_undefined:
	.ascii	"Undefined instruction .. at ....\n"
msg_invalid:
	.ascii	"Invalid register value at ....\n"
msg_err_load_drive:
	.ascii	"Could not load drive file drive..nib\n"
msg_err_flush_drive:
	.ascii	"Could not save drive file drive..nib\n"
msg_text:
	.ascii	"\x1B[..;..H\x1B[.m."
termios:
	.fill	SIZEOF_TERMIOS,1,0
sigaction:
	.fill	SIZEOF_SIGACTION,1,0
breakpoint:
	.hword	0
kbd:
	.byte	0		// buffer
	.byte	0		// strobe
	.byte	0		// last key
	.byte	0		// key sequence
	.byte	0		// reset
drive1:				// 35 tracks, 13 sectors of 512 nibbles
	.byte	0		// drive '1' or '2'
	.byte	0		// flags: loaded, write, dirty, read-only
	.byte	0		// last nibble read
	.byte	0		// next nibble written
	.byte	0		// phase 0-3
	.byte	0		// half-track 0-69
	.hword	0		// head 0-6655
	.quad	0		// pointer to content
drive2:
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.hword	0
	.quad	0
