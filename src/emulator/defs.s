// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021-2022
// Released under GPLv2 license
//
// Definitions

// 6502 processor registers
PC_REG		.req	w17
SP_REG		.req	w18
SP_REG_64	.req	x18
A_REG		.req	w19
X_REG		.req	w20
Y_REG		.req	w21
S_REG		.req	w22

// "variable" registers
MEM_FLAGS	.req	w14
VALUE		.req	w15
ADDR		.req	w16
ADDR_64		.req	x16

// "static" registers
MEM		.req	x23
INSTR		.req	x24
CONFIG		.req	x25
SCREEN		.req	x26
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
	.equ	STACK,0x100		// processor stack
	.equ	LINE1,0x400		// 40 column text
	.equ	PRGMEM,0x800
	.equ	KBD,0xC000		// I/O area
	.equ	KBDSTRB,0xC010
	.equ	TXTCLR,0xC050
	.equ	TXTSET,0xC051
	.equ	MIXCLR,0xC052
	.equ	MIXSET,0xC053
	.equ	LOWSCR,0xC054
	.equ	HISCR,0xC055
	.equ	LORES,0xC056
	.equ	HIRES,0xC057
	.equ	SETAN0,0x0C058
	.equ	CLRAN0,0x0C059
	.equ	RAM_CTL_BEGIN,0xC080
	.equ	RAM_CTL_END,0xC08F
	.equ	V80_PAGE0,0xC0B0
	.equ	V80_REGISTER,0xC0B0
	.equ	V80_VALUE,0xC0B1
	.equ	V80_PAGE3,0xC0BC
	.equ	IWM_PHASE0OFF,0xC0E0
	.equ	IWM_WRITEMODE,0xC0EF
	.equ	DISK2ROM,0xC600		// ROMs
	.equ	COL80ROM,0xC800
	.equ	OLDRST,0xFF59		// vectors

// 6502 opcodes
	.equ	JMP,0x4C

// Linux system calls
	.equ	FCNTL,25
	.equ	IOCTL,29
	.equ	UNLINKAT,35
	.equ	OPENAT,56
	.equ	CLOSE,57
	.equ	READ,63
	.equ	WRITE,64
	.equ	FSTAT,80
	.equ	EXIT,93
	.equ	NANOSLEEP,101
	.equ	RT_SIGACTION,134
	.equ	SOCKET,198
	.equ	BIND,200
	.equ	LISTEN,201
	.equ	ACCEPT,202
	.equ	MMAP,222

// Linux structures
	.equ	C_LFLAG,12		// termios
	.equ	C_CC_VTIME,(17+5)
	.equ	C_CC_VMIN,(17+6)
	.equ	SIZEOF_TERMIOS,60
	.equ	ST_MODE,16		// stat
	.equ	ST_SIZE,48
	.equ	SIZEOF_STAT,128
	.equ	SA_HANDLER,0		// sigaction
	.equ	SIZEOF_SIGACTION,152

// Linux constants
	.equ	F_GETFL,3		// fcntl
	.equ	F_SETFL,4
	.equ	O_NONBLOCK,0x800
	.equ	TCGETS,0x5401		// ioctl
	.equ	TCSETS,0x5402
	.equ	ICANON,0x2
	.equ	ECHO,0x8
	.equ	O_RDONLY,0x0		// openat
	.equ	O_WRONLY,0x1
	.equ	STDIN,0			// write
	.equ	STDOUT,1
	.equ	STDERR,2
	.equ	EAGAIN,-11
	.equ	S_IWUSR,0x80		// fstat
	.equ	SIGINT,2		// rt_sigaction
	.equ	AF_UNIX,1		// socket
	.equ	SOCK_STREAM,1
	.equ	PROT_READ,0x1		// mmap
	.equ	PROT_WRITE,0x2
	.equ	MAP_PRIVATE,0x2
	.equ	MAP_ANONYMOUS,0x20

// Internal structures
	.equ	CFG_FLAGS,0		// configuration
	.equ	KBD_BUFFER,0		// keyboard
	.equ	KBD_STROBE,1
	.equ	KBD_LASTKEY,2
	.equ	KBD_POLL_RATIO,3
	.equ	KBD_WAIT,4
	.equ	KBD_KEYSEQ,6
	.equ	KBD_RESET,7
	.equ	SCR_MODE,0		// screen
	.equ	SCR_REGISTER,1
	.equ	SCR_REFRESH,2
	.equ	SCR_VALUES,3
	.equ	SCR_BASE_HI,SCR_VALUES+12
	.equ	SCR_BASE_LO,SCR_VALUES+13
	.equ	DRV_NUMBER,0		// floppy drive
	.equ	DRV_FLAGS,1
	.equ	DRV_LASTNIB,2
	.equ	DRV_NEXTNIB,3
	.equ	DRV_PHASE,4
	.equ	DRV_HTRACK,5
	.equ	DRV_HEAD,6
	.equ	DRV_TSIZE,8
	.equ	DRV_FNAME,10
	.equ	DRV_CONTENT,18
	.equ	DRV_DSK_CONTENT,26

// Internal constants
	.equ	SIZEOF_BUFFER,2048      // size of general purpose buffer
	.equ	CNF_LANGCARD_E,0x01	// configuration flags
	.equ	CNF_FLOPPY_E,0x02
	.equ	CNF_80COL_E,0x04
	.equ	CNF_GUI_E,0x08
	.equ	FLG_LOADED,0x01		// floppy disk flags
	.equ	FLG_WRITE,0x02
	.equ	FLG_DIRTY,0x04
	.equ	FLG_DSK,0x08
	.equ	FLG_READONLY,0x80
	.equ	SCR_TXT,0x01		// screen mode flags
	.equ	SCR_MIX,0x02
	.equ	SCR_HI,0x04
	.equ	SCR_HGR,0x08
	.equ	SCR_80COL,0x10
	.equ	SEQ,0			// keyboard sequence
	.equ	SEQ_ESC,1
	.equ	SEQ_ESC_BRA,2
	.equ	SEQ_ESC_O,3
	.equ	MEM_LC_E,0x01		// memory mapping flags
	.equ	MEM_LC_R,0x02
	.equ	MEM_LC_W,0x04
	.equ	MEM_LC_2,0x08
	.equ	MEM_FL_E,0x10
	.equ	MEM_80_E,0x20
	.equ	MEM_80_1,0x40
	.equ	MEM_80_2,0x80
