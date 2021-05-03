// WozMania Apple ][ emulator for ARM processor
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
KEYBOARD	.req	x27
DRIVE		.req	x28
BREAKPOINT	.req	x29

// 6502 status register flags
	.equ	C_FLAG,0x01
	.equ	Z_FLAG,0x02
	.equ	I_FLAG,0x04
	.equ	D_FLAG,0x08
	.equ	B_FLAG,0x10
	.equ	X_FLAG,0x20
	.equ	V_FLAG,0x40
	.equ	N_FLAG,0x80

// ROM routines and I/O addresses
	.equ	LINE1,0x400
	.equ	KBD,0xC000
	.equ	KBDSTRB,0xC010
	.equ	IWM_PHASE0OFF,0xC0E0
	.equ	IWM_WRITEMODE,0xC0EF
	.equ	DISK2ROM,0xC600
	.equ	OLDRST,0xFF59

// 6502 opcodes
	.equ	JMP,0x4C

// Linux system calls
	.equ	IOCTL,29
	.equ	OPENAT,56
	.equ	READ,63
	.equ	WRITE,64
	.equ	RT_SIGACTION,134
	.equ	MMAP,222

// Linux structures
	.equ	C_LFLAG,12
	.equ	C_CC_VTIME,(17+5)
	.equ	C_CC_VMIN,(17+6)
	.equ	SIZEOF_TERMIOS,60
	.equ	SA_HANDLER,0
	.equ	SIZEOF_SIGACTION,152

// Linux constants
	.equ	STDIN,0
	.equ	STDOUT,1
	.equ	STDERR,2
	.equ	SIGINT,2
	.equ	TCGETS,0x5401
	.equ	TCSETS,0x5402
	.equ	ICANON,0x2
	.equ	ECHO,0x8
	.equ	PROT_READ,0x1
	.equ	PROT_WRITE,0x2
	.equ	MAP_PRIVATE,0x2
	.equ	MAP_ANONYMOUS,0x20

// Internal structures
	.equ	KBD_BUFFER,0
	.equ	KBD_STROBE,1
	.equ	KBD_LASTKEY,2
	.equ	KBD_KEYSEQ,3
	.equ	KBD_RESET,4
	.equ	DRV_NUMBER,0
	.equ	DRV_FLAGS,1
	.equ	DRV_LASTNIB,2
	.equ	DRV_PHASE,3
	.equ	DRV_HTRACK,4
	.equ	DRV_HEAD,5
	.equ	DRV_CONTENT,7

// Internal constants
	.equ	F_LOADED,0x01
	.equ	F_WRITE,0x02
	.equ	SEQ,0
	.equ	SEQ_ESC,1
	.equ	SEQ_ESC_BRA,2
	.equ	SEQ_ESC_O,3
