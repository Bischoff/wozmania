// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Debugging utilities

	.ifdef	TRACE
.global trace
	.endif
	.ifdef	BREAK
.global break
	.endif
	.ifdef	CHECK
.global check
	.endif
	.ifdef	F_READ
.global f_read
	.endif
	.ifdef	F_WRITE
.global f_write
	.endif
	.ifdef	BREAK
.global breakpoint
	.endif

.include "src/defs.s"
.include "src/macros.s"

// Trace each instruction
	.ifdef	TRACE
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
	.endif

// Break at a given 6502 address
	.ifdef	BREAK
break:
	ldrh	w0,[BREAKPOINT]
	tst	w0,#0xFFFF
	b.eq	here
	cmp	PC_REG,w0
	b.ne	breakout
here:	nop				// use this symbol as your gdb breakpoint
breakout:				// pun intended
	br	lr
	.endif

// Check that registers are still 8 bit values
	.ifdef	CHECK
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
	.endif

// Print current nibble
	.ifdef	F_READ
f_read:
	ldr	x3,=msg_disk
	mov	w0,#'R'
	char	w0,0
	b	print_nibble
	.endif
	.ifdef	F_WRITE
f_write:
	ldr	x3,=msg_disk
	mov	w0,#'W'
	char	w0,0
	b	print_nibble
	.endif
	.if	(F_READ == 1) || (F_WRITE == 1)
print_nibble:
	adr	x2,hex
	ldrb	w0,[DRIVE,#DRV_NUMBER]
	char	w0,10
	hex_8	w6,21
	hex_16	w5,31
	hex_8	VALUE,44
	write	STDERR,47
	b	last_nibble
	.endif

// Invalid value for register
	.ifdef	CHECK
invalid:
	sub	PC_REG,PC_REG,#1
	adr	x2,hex
	ldr	x3,=msg_invalid
	hex_16	PC_REG,40
	write	STDERR,45
	b	exit
	.endif


// Fixed data

hex:
	.ascii	"0123456789ABCDEF"


// Variable data

.data

	.ifdef	TRACE
msg_trace:
	.ascii	"PC: ....  SP: 01..  A: ..  X: ..  Y: ..  S: ........\n"
	.endif
	.if	(F_READ == 1) || (F_WRITE == 1)
msg_disk:
	.ascii	".  DRIVE: .  HTRACK: ..  HEAD: ....  VALUE: ..\n"
	.endif
	.ifdef	CHECK
msg_invalid:
	.ascii	"\x1B[25;01H\x1B[?25hInvalid register value at ....\n"
	.endif
	.ifdef	BREAK
breakpoint:
	.hword	0
	.endif
