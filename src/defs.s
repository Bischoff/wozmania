// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Definitions

// 6502 processor registers
PC_REG		.req	w19
SP_REG		.req	w20
SP_REG_64	.req	x20
A_REG		.req	w21
X_REG		.req	w22
Y_REG		.req	w23
S_REG		.req	w24

// "variable" registers
MEM_FLAGS	.req	w16
VALUE		.req	w17
ADDR		.req	w18
ADDR_64		.req	x18

// "static" registers
MEM		.req	x25
INSTR		.req	x26
KEYBOARD	.req	x27
DRIVE		.req	x28
		.ifdef	BREAK
BREAKPOINT	.req	x29
		.endif

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
	.equ	STACK,0x100
	.equ	LINE1,0x400
	.equ	KBD,0xC000
	.equ	KBDSTRB,0xC010
	.equ	RAM_CTL_BEGIN,0xC080
	.equ	RAM_CTL_END,0xC08F
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
	.equ	FSTAT,80
	.equ	RT_SIGACTION,134
	.equ	MMAP,222

// Linux structures
	.equ	C_LFLAG,12
	.equ	C_CC_VTIME,(17+5)
	.equ	C_CC_VMIN,(17+6)
	.equ	SIZEOF_TERMIOS,60
	.equ	ST_MODE,16
	.equ	ST_SIZE,48
	.equ	SIZEOF_STAT,128
	.equ	SA_HANDLER,0
	.equ	SIZEOF_SIGACTION,152

// Linux constants
	.equ	STDIN,0
	.equ	STDOUT,1
	.equ	STDERR,2
	.equ	SIGINT,2
	.equ	O_RDONLY,0x0
	.equ	O_WRONLY,0x1
	.equ	TCGETS,0x5401
	.equ	TCSETS,0x5402
	.equ	ICANON,0x2
	.equ	ECHO,0x8
	.equ	S_IWUSR,0x80
	.equ	PROT_READ,0x1
	.equ	PROT_WRITE,0x2
	.equ	MAP_PRIVATE,0x2
	.equ	MAP_ANONYMOUS,0x20

// Internal structures
	.equ	KBD_BUFFER,0
	.equ	KBD_STROBE,1
	.equ	KBD_LASTKEY,2
	.equ	KBD_WAIT,3
	.equ	KBD_KEYSEQ,4
	.equ	KBD_RESET,5
	.equ	DRV_NUMBER,0
	.equ	DRV_FLAGS,1
	.equ	DRV_LASTNIB,2
	.equ	DRV_NEXTNIB,3
	.equ	DRV_PHASE,4
	.equ	DRV_HTRACK,5
	.equ	DRV_HEAD,6
	.equ	DRV_CONTENT,8

// Internal constants
	.equ	FLG_LOADED,0x01
	.equ	FLG_WRITE,0x02
	.equ	FLG_DIRTY,0x04
	.equ	FLG_READONLY,0x80
	.equ	SEQ,0
	.equ	SEQ_ESC,1
	.equ	SEQ_ESC_BRA,2
	.equ	SEQ_ESC_O,3
	.equ	LC_Z,0x0
	.equ	LC_R,0x1
	.equ	LC_W,0x2
	.equ	LC_2,0x4
