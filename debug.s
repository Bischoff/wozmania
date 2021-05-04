// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Debugging utilities

.global trace
.global break
.global check
.global nibble_read
.global nibble_written
.global undefined
.global breakpoint

.include "defs.s"
.include "macros.s"

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
nibble_read:
	ldr	x3,=msg_disk
	mov	w0,#'R'
	char	w0,0
	b	print_nibble
nibble_written:
	ldr	x3,=msg_disk
	mov	w0,#'W'
	char	w0,0
print_nibble:
	adr	x2,hex
	ldrb	w0,[DRIVE,#DRV_NUMBER]
	char	w0,10
	hex_8	w6,21
	hex_16	w5,31
	hex_8	w9,44
	write	STDERR,47
	b	last_nibble

// Undefined instruction
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

// Invalid value for register
invalid:
	sub	PC_REG,PC_REG,#1
	adr	x3,msg_end	// go to line 25 and restore cursor
	write	STDOUT,14
	adr	x2,hex		// print error message
	ldr	x3,=msg_invalid
	hex_16	PC_REG,26
	write	STDERR,31
	b	exit

// Fixed data

hex:
	.ascii	"0123456789ABCDEF"

// Variable data

.data

msg_trace:
	.ascii	"PC: ....  SP: 01..  A: ..  X: ..  Y: ..  S: ........\n"
msg_disk:
	.ascii	".  DRIVE: .  HTRACK: ..  HEAD: ....  VALUE: ..\n"
msg_undefined:
	.ascii	"Undefined instruction .. at ....\n"
msg_invalid:
	.ascii	"Invalid register value at ....\n"
breakpoint:
	.hword	0
