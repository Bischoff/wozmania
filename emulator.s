// COMPOTE Apple ][ emulator for ARM processor
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

prepare_terminal:
	adr	x3,msg_cls	// clear screen and hide cursor
	write	10
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
	strb	w0,[x2,#(C_CC + VTIME)]
	mov	w0,#0
	strb	w0,[x2,#(C_CC + VMIN)]
	mov	w0,#STDIN
	mov	w1,#TCSETS
	ldr	x2,=termios
	mov	w8,#IOCTL
	svc	0
	br	lr

load_rom:
	mov	w0,#-100	// open ROM file
	adr	x1,filename
	mov	w2,#0
	mov	w8,#OPENAT
	svc	0
	ldr	x1,=rom		// read ROM file
	mov	w2,#0x5000
	mov	w8,#READ
	svc	0
	mov	w0,#0xC600	// for now, hide the disk by removing its signature
	mov	w1,#0x4C
        strb	w1,[MEM,x0]
	mov	w0,#0xC601
	mov	w1,#0xFF59
        strh	w1,[MEM,x0]
	mov	w0,#0x3FB	// jump to monitor in case of BRK
	mov	w1,#0x4C
        strh	w1,[MEM,x0]
	mov	w0,#0x3FC
	mov	w1,#0xFF59
        strh	w1,[MEM,x0]
	br	lr

reset:
	mov	A_REG,#0
	mov	X_REG,#0
	mov	Y_REG,#0
	mov	S_REG,#0
	mov	SP_REG,#0x1FF
	mov	x0,#0xFFFC
        ldrh	PC_REG,[MEM,x0]
	br	lr


// Input-output via memory

// input: w18 = address in range $C000-$C010
// output: w18 = character read
fetch_io:
	cmp	w18,#0xC000
	b.eq	read_key
	mov	w0,#0xC010
	cmp	w18,w0
	b.eq	clear_strobe
	b	nothing_to_read
read_key:
	ldr	x0,=keyboard_strobe
	ldrb	w1,[x0]
	tst	w1,#0xFF
	b.ne	1f
	mov	w1,#1
	strb	w1,[x0]
	mov	w0,#STDIN
	ldr	x1,=keyboard_buffer
	mov	w2,#1
	mov	w8,#READ
	svc	0
	cmp	w0,#1
	b.lt	clear_strobe
1:	ldr	x1,=keyboard_buffer
	ldrb	w18,[x1]
	cmp	w18,#0xA
	b.ne	2f
	mov	w18,#0xD
2:	orr	w18,w18,#0x80
	br	lr
clear_strobe:
	ldr	x0,=keyboard_strobe
	mov	w1,#0
	strb	w1,[x0]
nothing_to_read:
	mov	w18,#0
	br	lr

// input: w18 = address in range $0400-$0800
store_io:
	ldr	x3,=msg_text
	mov	w2,w18		// line and column
	sub	w2,w2,#0x400
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
	ldrb	w1,[MEM,x18]	// text effect and text
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
	write	13
screen_hole:
	br	lr

// Debugging utilities

// trace each instruction
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
	write	53
	br	lr

// break at a given 6502 address
break:
	ldrh	w0,[BREAKPOINT]
	tst	w0,#0xFFFF
	b.eq	here
	cmp	PC_REG,w0
	b.ne	1f
here:
	nop
1:	br	lr

// check that registers are still 8 bit values
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


// Main loop

_start:
	adr	INSTR,instr_table
	ldr	BREAKPOINT,=breakpoint
	ldr	MEM,=memory
	bl	prepare_terminal
	bl	load_rom
	bl	reset
emulate:
	//bl	trace		// uncomment these lines according to your debugging needs
	//bl	break
	//bl	check
next:				// trace each instruction with "b next"
	ldrb	w0,[MEM,PC_REG_64]
	add	PC_REG,PC_REG,#1
	ldr	x1,[INSTR,x0,LSL 3]
	br	x1


// Exit

undefined:
	sub	PC_REG,PC_REG,#1
	adr	x2,hex
	ldr	x3,=msg_undefined
	hex_8	w0,22
	hex_16	PC_REG,28
	write	33
	b	exit
invalid:
	sub	PC_REG,PC_REG,#1
	adr	x2,hex
	ldr	x3,=msg_invalid
	hex_16	PC_REG,26
	write	31
exit:
	mov	x0,#0
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
filename:
	.asciz	"APPLE2.ROM"
hex:
	.ascii	"0123456789ABCDEF"
msg_cls:
	.ascii	"\x1B[2J\x1B[?25l"


// Variable data

.data

msg_trace:
	.ascii	"PC: ....  SP: 01..  A: ..  X: ..  Y: ..  S: ........\n"
msg_undefined:
	.ascii	"Undefined instruction .. at ....\n"
msg_invalid:
	.ascii	"Invalid register value at ....\n"
msg_text:
	.ascii	"\x1B[01;01H\x1B[0m."
termios:
	.fill	60,1,0
keyboard_buffer:
	.byte	0
keyboard_strobe:
	.byte	0
breakpoint:
	.hword	0
	//.align	16	// 64k, for easier debugging
memory:
	.fill	0x10000,1,0
	.equ	rom,memory+0xB000
