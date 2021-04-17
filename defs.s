// COMPOTE Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Definitions

// 6502 processor registers
PC_REG		.req	w19
PC_REG_64	.req	x19
SP_REG		.req	w20
SP_REG_64	.req	x20
A_REG		.req	w21
X_REG		.req	w22
Y_REG		.req	w23
S_REG		.req	w24

// Other registers
MEM		.req	x25
INSTR		.req	x26
BREAKPOINT	.req	x27

// 6502 status register flags
	.equ	C_FLAG,0x01
	.equ	Z_FLAG,0x02
	.equ	I_FLAG,0x04
	.equ	D_FLAG,0x08
	.equ	B_FLAG,0x10
	.equ	X_FLAG,0x20
	.equ	V_FLAG,0x40
	.equ	N_FLAG,0x80

// linux API
	.equ	IOCTL,29
	.equ	OPENAT,56
	.equ	READ,63
	.equ	WRITE,64
	.equ	STDIN,0
	.equ	STDOUT,1
	.equ	TCGETS,0x5401
	.equ	TCSETS,0x5402
	.equ	C_LFLAG,12
	.equ	C_CC,17
	.equ	ICANON,0x2
	.equ	ECHO,0x8
	.equ	VTIME,5
	.equ	VMIN,6
