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
IO		.req	w18
IO_64		.req	x18
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

// Routine and I/O addresses
	.equ	NMI,0x3FB
	.equ	LINE1,0x400
	.equ	KBD,0xC000
	.equ	KBDSTRB,0xC010
	.equ	IWM_PHASE0OFF,0xC0E0
	.equ	IWM_WRITEMODE,0xC0EF
	.equ	DISK2ROM,0xC600
	.equ	OLDRST,0xFF59

// 6502 opcodes
	.equ	JMP,0x4C

// Linux API
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
	.equ	ISIG,0x1
	.equ	ICANON,0x2
	.equ	ECHO,0x8
	.equ	VTIME,5
	.equ	VMIN,6

// Internal structures
	.equ	KBD_BUFFER,0
	.equ	KBD_STROBE,1
	.equ	KBD_LASTKEY,2
	.equ	KBD_ESCSEQ,3
	.equ	DRV_MODE,0
	.equ	DRV_PHASE,1
	.equ	DRV_HTRACK,2
	.equ	DRV_HEAD,3
