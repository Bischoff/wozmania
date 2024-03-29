// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021-2022
// Released under GPLv2 license
//
// Text output

.global prepare_terminal
.global disable_80col
.global enable_80col
.global screen_control
.global text40_write
.global text80_write
.global text80_read
.global videx80_read
.global videx80_write_register
.global videx80_write_value
.global clean_terminal
.global rom_c800
.global data_handle
.global screen

.include "defs.s"
.include "macros.s"

// Prepare text terminal
prepare_terminal:
	ldrb	w3,[CONFIG,#CFG_FLAGS]
	tst	w3,#CNF_GUI_E
	b.eq	prepare_ansi_terminal
	b	prepare_gui_terminal

prepare_ansi_terminal:
	adr	x3,msg_begin		// clear screen and hide cursor
	write	STDOUT,35
	br	lr

prepare_gui_terminal:
	mov	w0,0			// remove preceding socket file
	adr	x1,unix_domain_socket+2
	mov	w2,0
	mov	w8,#UNLINKAT
	svc	0
	mov	w0,#AF_UNIX		// create Unix domain socket
	mov	w1,#SOCK_STREAM
	mov	w2,#0
	mov	w8,#SOCKET
	svc	0
	cmp	x0,#-1
	b.eq	1f
	ldr	x1,=cnx_handle		// store connexion handle
	str	w0,[x1]
	adr	x1,unix_domain_socket	// bind it to filename
	mov	w2,#unix_domain_len
	mov	w8,#BIND
	svc	0
	cmp	x0,#-1
	b.eq	1f
	ldr	x1,=cnx_handle		// listen on it
	ldr	w0,[x1]
	mov	w1,#20
	mov	w8,#LISTEN
	svc	0
	cmp	x0,#-1
	b.eq	1f
	ldr	x1,=cnx_handle		// start accepting connexions
	ldr	w0,[x1]
	mov	x1,#0
	mov	x2,#0
	mov	w8,#ACCEPT
	svc	0
	cmp	x0,#-1
	b.eq	1f
	ldr	x1,=data_handle		// store data handle
	str	w0,[x1]
1:	br	lr

// Disable the 80 column card
disable_80col:
					// deactivate $C800 ROM
	and	MEM_FLAGS,MEM_FLAGS,#~(MEM_80_E | MEM_80_1 | MEM_80_2)
	br	lr

// Enable the 80 column card
enable_80col:
					// activate $C800 ROM
	and	MEM_FLAGS,MEM_FLAGS,#~(MEM_80_1 | MEM_80_2)
	orr	MEM_FLAGS,MEM_FLAGS,#MEM_80_E
	br	lr

// Screen control
screen_control:
	ldrb	VALUE,[SCREEN,#SCR_MODE]
	mov	w0,#TXTCLR
	sub	w1,ADDR,w0
	adr	x0,control_table
	ldr	x2,[x0,x1,LSL 3]
	br	x2
screen_control_2:
	strb	VALUE,[SCREEN,#SCR_MODE]
	br	lr
screen_txtclr:
	and	VALUE,VALUE,#~SCR_TXT
	b	screen_control_2
screen_txtset:
	orr	VALUE,VALUE,#SCR_TXT
	b	screen_control_2
screen_mixclr:
	and	VALUE,VALUE,#~SCR_MIX
	b	screen_control_2
screen_mixset:
	orr	VALUE,VALUE,#SCR_MIX
	b	screen_control_2
screen_lowscr:
	and	VALUE,VALUE,#~SCR_HI
	b	screen_control_2
screen_hiscr:
	orr	VALUE,VALUE,#SCR_HI
	b	screen_control_2
screen_lores:
	and	VALUE,VALUE,#~SCR_HGR
	b	screen_control_2
screen_hires:
	orr	VALUE,VALUE,#SCR_HGR
	b	screen_control_2
screen_setan0:				// return to 40 column mode
	tst	VALUE,#SCR_80COL
	b.eq	2f
	ldrb	w0,[CONFIG,#CFG_FLAGS]
	tst	w0,#CNF_GUI_E
	b.ne	1f
	adr	x3,msg_40col_ansi
	write	STDOUT,272
	b	2f
1:	adr	x3,msg_40col_gui
	tosocket 2
2:	mov	VALUE,#SCR_TXT
	b	screen_control_2
screen_clran0:				// change to 80 col mode
	tst	VALUE,#SCR_80COL
	b.ne	2f
	ldrb	w0,[CONFIG,#CFG_FLAGS]
	tst	w0,#CNF_GUI_E
	b.ne	1f
	adr	x3,msg_80col_ansi
	write	STDOUT,6
	b	2f
1:	adr	x3,msg_80col_gui
	tosocket 2
2:	mov	VALUE,#SCR_80COL
	b	screen_control_2

// write to 40 column buffer
text40_write:
	ldrb	w0,[SCREEN,#SCR_MODE]	// hi res graphic or 80 columns?
	tst	w0,#(SCR_HGR | SCR_80COL)
	b.ne	2f
	cmp	ADDR,#0x800		// screen 1
	b.ge	1f
	tst	w0,#SCR_HI
	b.ne	2f
	mov	w2,ADDR
	sub	w2,w2,#LINE1
	b	3f
1:	tst	w0,#SCR_HI		// screen 2 (at same place as program memory!)
	b.eq	2f
	mov	w2,ADDR
	sub	w2,w2,#PRGMEM
	b	3f
2:	br	lr
3:	and	w0,w2,#0x7F		// w2 = line, w5 = column
	lsr	w2,w2,#7
	mov	w4,#40
	udiv	w1,w0,w4
	msub	w5,w1,w4,w0
	cmp	w1,#3
	b.ge	screen_hole
	lsl	w1,w1,#3
	orr	w2,w2,w1
	ldrb	w0,[SCREEN,#SCR_MODE]	// low res graphic?
	tst	w0,#SCR_TXT
	b.ne	text
	tst	w0,#SCR_MIX		// mixed mode?
	b.eq	low_gr
	cmp	w2,#20			// mixed mode, row 0-19?
	b.lt	low_gr
	b	text

// low resolution graphics
low_gr:
	ldrb	w3,[CONFIG,#CFG_FLAGS]
	tst	w3,#CNF_GUI_E
	b.eq	gr_ansi_out
	b	gr_gui_out

// low resolution graphics on GUI terminal
gr_gui_out:
	ldr	x3,=msg_gui
	mov	w0,#'G'
	char	w0,0
	char	w5,1
	char	w2,2
	char	VALUE,3
1:	tosocket 4
	cmp	w0,#EAGAIN
	b.ne	2f
	adr	x0,retry_delay
	mov	w8,#NANOSLEEP
	svc	0
	b	1b
2:	br	lr

// low resolution graphics on ANSI terminal
gr_ansi_out:
	adr	x3,color_table
	mov	w6,VALUE		// w6 = top pixel (background)
	and	w6,w6,#0x0F
	ldrb	w6,[x3,x6]
	add	w6,w6,#10
	mov	w7,VALUE,lsr #4		// w7 = bottom pixel (foreground)
	and	w7,w7,#0x0F
	ldrb	w7,[x3,x7]
	ldr	x3,=msg_gr		// send to the terminal
	add	w2,w2,#1
	dec_8	w2,2
	add	w5,w5,#1
	dec_8	w5,5
	long_dec_8 w7,10
	long_dec_8 w6,14
	write	STDOUT,21
	br	lr

// 40 column text
text:
	mov	w1,VALUE		// w1 = character
	lsr	w0,w1,#2		// w4 = text effect
	and	w0,w0,#0xF8
	adr	x4,video_table
	ldr	x3,[x4,x0]
	br	x3
screen_hole:
	br	lr
inverse:
	add	w1,w1,#0x40
inverse1:
	mov	w6,#'I'
	b	text40_out
flash:
	sub	w1,w1,#0x40
	cmp	w1,#' '
	b.eq	inverse1		// normally, blinking inverse space
flash1:
	mov	w6,#'F'
	b	text40_out
normal:
	and	w1,w1,#0x7F
	mov	w6,#'N'
text40_out:
	ldrb	w3,[CONFIG,#CFG_FLAGS]
	tst	w3,#CNF_GUI_E
	b.eq	text_ansi_out
	b	text_gui_out

// Output character on ANSI terminal
//   input: w2 = line
//          w5 = column
//          w6 = effect
//          w1 = character
text_ansi_out:
	cmp	w6,'N'			// ANSI encoding of normal, inverse, flash
	b.ne	1f
	mov	w6,'0'
	b	3f
1:	cmp	w6,'I'
	b.ne	2f
	mov	w6,'7'
	b	3f
2:	mov	w6,'5'
	b	3f
3:	ldr	x3,=msg_text		// send to the terminal
	char	w1,12
	char	w6,10
	add	w2,w2,#1
	dec_8	w2,2
	add	w5,w5,#1
	dec_8	w5,5
	write	STDOUT,13
	br	lr

// Output character on GUI terminal
//   input: w2 = line
//          w5 = column
//          w6 = effect
//          w1 = character
text_gui_out:
	ldr	x3,=msg_gui
	char	w6,0
	char	w5,1
	char	w2,2
	char	w1,3
1:	tosocket 4
	cmp	w0,#EAGAIN
	b.ne	2f
	adr	x0,retry_delay
	mov	w8,#NANOSLEEP
	svc	0
	b	1b
2:	br	lr

// 80 columns - compute offset in buffer
//   input: MEM_FLAGS -> page
//          ADDR = emulated memory address ($CC00-$CDFF)
//   output: w10 = offset in buffer ($000-$7FF)
text80_offset:
	mov	w0,#0xCC00
	sub	w10,ADDR,w0
	and	w0,MEM_FLAGS,#(MEM_80_1 | MEM_80_2)
	lsl	w0,w0,#3		// assumes flags are at 0x40 and 0x80!
	add	w10,w10,w0
	br	lr

// 80 columns - compute screen address
//   input: w10 = offset in buffer ($000-$7FF)
//   output: x4 = screen address
text80_address:
	mov	w0,#0x4000		// $10000 (RAM) + $4000 (language card)
	movk	w0,#1,LSL #16
	add	x0,MEM,x0
	add	x4,x0,x10
	br	lr

// 80 columns - output character
//   input:   w10 = offset in buffer ($000-$7FF)
//             x4 = screen address
//          VALUE = character to print
text80_out:
	ldrb	w2,[SCREEN,#SCR_BASE_HI] // substract base address
	lsl	w2,w2,#8
	ldrb	w3,[SCREEN,#SCR_BASE_LO]
	orr	w2,w2,w3
	sub	w1,w10,w2
	and	w1,w1,#0x7FF
	cmp	w1,#(24*80)		// clean characters that are out of screen
	b.lt	1f
	mov	w0,#' '
	strb	w0,[x4]
	br	lr
1:	mov	w3,#80			// w5 = X coordinate, w2 = Y coordinate
	udiv	x2,x1,x3
	msub	x5,x2,x3,x1
	tst	VALUE,#0x80		// w6 = effect
	b.eq	2f
	and	VALUE,VALUE,#0x7F
	mov	w6,#'I'
	b	3f
2:	mov	w6,#'N'
3:	mov	w1,VALUE		// write character on screen
	ldrb	w3,[CONFIG,#CFG_FLAGS]
	tst	w3,#CNF_GUI_E
	b.eq	text_ansi_out
	b	text_gui_out

// 80 column text
text80_write:
	mov	x9,lr			// store byte in buffer
	bl	text80_offset
	bl	text80_address
	strb	VALUE,[x4]
	ldrb	w1,[SCREEN,#SCR_REFRESH] // output character, or...
	tst	w1,#0xFF
	b.ne	1f
	bl	text80_out
	br	x9
1:	mov	w1,#0			// ... refresh whole screen
	strb	w1,[SCREEN,#SCR_REFRESH]
	mov	w10,#0
2:	bl	text80_address
	ldrb	VALUE,[x4]
	bl	text80_out
	add	w10,w10,#1
	cmp	w10,#0x800
	b.lt	2b
	br	x9
text80_read:
	mov	x9,lr			// load byte from buffer
	bl	text80_offset
	bl	text80_address
	ldrb	VALUE,[x4]
	br	x9

// 80 column control - read
videx80_read:
	tst	MEM_FLAGS,#MEM_80_E
	b.eq	nothing_to_read
	mov	w0,#V80_PAGE0
	sub	w1,ADDR,w0
	adr	x0,col80_table
	ldr	x2,[x0,x1,LSL 3]
	br	x2

// 80 column control - read register value
videx80_read_value:
	ldrb	w1,[SCREEN,#SCR_REGISTER]
	add	w1,w1,#SCR_VALUES
	ldrb	VALUE,[SCREEN,x1]
	br	lr

// 80 column control - change to another page
videx80_page0:
	and	MEM_FLAGS,MEM_FLAGS,#~(MEM_80_1 | MEM_80_2)
	br	lr
videx80_page1:
	orr	MEM_FLAGS,MEM_FLAGS,#MEM_80_1
	and	MEM_FLAGS,MEM_FLAGS,#~MEM_80_2
	br	lr
videx80_page2:
	and	MEM_FLAGS,MEM_FLAGS,#~MEM_80_1
	orr	MEM_FLAGS,MEM_FLAGS,#MEM_80_2
	br	lr
videx80_page3:
	orr	MEM_FLAGS,MEM_FLAGS,#(MEM_80_1 | MEM_80_2)
	br	lr

// 80 column control - select register
videx80_write_register:
	tst	MEM_FLAGS,#MEM_80_E
	b.eq	1f
	cmp	VALUE,#17
	b.gt	1f
	strb	VALUE,[SCREEN,#SCR_REGISTER]
1:	br	lr

// 80 column control - write register value
videx80_write_value:
	tst	MEM_FLAGS,#MEM_80_E	// store register value
	b.eq	2f
	ldrb	w1,[SCREEN,#SCR_REGISTER]
	add	w1,w1,#SCR_VALUES
	ldrb	w2,[SCREEN,x1]
	strb	VALUE,[SCREEN,x1]
	cmp	w1,#SCR_BASE_HI		// if base address hase changed
	b.lt	2f
	cmp	w1,#SCR_BASE_LO
	b.gt	1f
	cmp	VALUE,w2
	b.eq	2f
	mov	w1,#1			// ... then schedule a screen refresh
	strb	w1,[SCREEN,#SCR_REFRESH]
1:	nop
// TODO: display cursor
2:	br	lr

// Cleanup terminal on exit
clean_terminal:
	ldrb	w3,[CONFIG,#CFG_FLAGS]
	tst	w3,#CNF_GUI_E
	b.eq	clean_ansi_terminal
	b	clean_gui_terminal

clean_ansi_terminal:
	adr	x3,msg_end		// go to line 26 and restore cursor
	write	STDOUT,13
	br	lr

clean_gui_terminal:
	ldr	x1,=data_handle		// close the socket
	ldr	w0,[x1]
	mov	w8,#CLOSE
	svc	0
	ldr	x1,=cnx_handle
	ldr	w0,[x1]
	mov	w8,#CLOSE
	svc	0
	br	lr


// Fixed data

color_table:
	.byte	30			// Apple black, ANSI black
	.byte	35			// Apple magenta, ANSI magenta
	.byte	34			// Apple dark blue, ANSI blue
	.byte	31			// Apple purple, ANSI red
	.byte	32			// Apple dark green, ANSI green
	.byte	37			// Apple grey 1, ANSI white
	.byte	94			// Apple medium blue, ANSI bright blue
	.byte	96			// Apple light blue, ANSI bright cyan
	.byte	33			// Apple brown, ANSI yellow
	.byte	91			// Apple orange, ANSI bright red
	.byte	90			// Apple grey 2, ANSI bright black
	.byte	95			// Apple pink, ANSI bright magenta
	.byte	92			// Apple green, ANSI bright green
	.byte	93			// Apple yellow, ANSI bright yellow
	.byte	36			// Apple aqua, ANSI cyan
	.byte	97			// Apple white, ANSI bright white
control_table:
	.quad	screen_txtclr
	.quad	screen_txtset
	.quad	screen_mixclr
	.quad	screen_mixset
	.quad	screen_lowscr
	.quad	screen_hiscr
	.quad	screen_lores
	.quad	screen_hires
	.quad	screen_setan0
	.quad	screen_clran0
video_table:
	.quad	inverse			// 00-3F
	.quad	inverse1
	.quad	flash1			// 40-7F
	.quad	flash
	.quad	normal			// 80-FF
	.quad	normal
	.quad	normal
	.quad	normal
col80_table:
	.quad	videx80_page0		// $C0B0
	.quad	videx80_read_value
	.quad	nothing_to_read
	.quad	nothing_to_read
	.quad	videx80_page1
	.quad	nothing_to_read
	.quad	nothing_to_read
	.quad	nothing_to_read
	.quad	videx80_page2		// $C0B8
	.quad	nothing_to_read
	.quad	nothing_to_read
	.quad	nothing_to_read
	.quad	videx80_page3
unix_domain_socket:
	.short	AF_UNIX
	.asciz	"/tmp/wozmania.sock"
unix_domain_len = . - unix_domain_socket
msg_begin:
	.ascii	"\x1B[2J\x1B[?25l\x1B[25;1H-- WozMania 0.2 --"
msg_end:
	.ascii	"\x1B[27;1H\x1B[?25h"
msg_40col_ansi:
	.ascii  "\x1B[?25l"		// hide cursor
	.ascii	"\x1B[1;41H\x1B[K"	// clear right of screen
	.ascii	"\x1B[2;41H\x1B[K"
	.ascii	"\x1B[3;41H\x1B[K"
	.ascii	"\x1B[4;41H\x1B[K"
	.ascii	"\x1B[5;41H\x1B[K"
	.ascii	"\x1B[6;41H\x1B[K"
	.ascii	"\x1B[7;41H\x1B[K"
	.ascii	"\x1B[8;41H\x1B[K"
	.ascii	"\x1B[9;41H\x1B[K"
	.ascii	"\x1B[10;41H\x1B[K"
	.ascii	"\x1B[11;41H\x1B[K"
	.ascii	"\x1B[12;41H\x1B[K"
	.ascii	"\x1B[13;41H\x1B[K"
	.ascii	"\x1B[14;41H\x1B[K"
	.ascii	"\x1B[15;41H\x1B[K"
	.ascii	"\x1B[16;41H\x1B[K"
	.ascii	"\x1B[17;41H\x1B[K"
	.ascii	"\x1B[18;41H\x1B[K"
	.ascii	"\x1B[19;41H\x1B[K"
	.ascii	"\x1B[20;41H\x1B[K"
	.ascii	"\x1B[21;41H\x1B[K"
	.ascii	"\x1B[22;41H\x1B[K"
	.ascii	"\x1B[23;41H\x1B[K"
	.ascii	"\x1B[24;41H\x1B[K"
	.ascii	"\x1B[25;41H\x1B[K"
msg_80col_ansi:
	.ascii  "\x1B[?25h"		// show cursor
msg_40col_gui:
	.ascii	"C4"
msg_80col_gui:
	.ascii	"C8"
retry_delay:
	.quad	0			// 0 second
	.quad	0x200000		// 2.1 milliseconds
rom_c800:
	.byte	0xad,0x7b,0x07,0x29,0xf8,0xc9,0x30,0xf0
	.byte	0x21,0xa9,0x30,0x8d,0x7b,0x07,0x8d,0xfb
	.byte	0x07,0xa9,0x00,0x8d,0xfb,0x06,0x20,0x61
	.byte	0xc9,0xa2,0x00,0x8a,0x8d,0xb0,0xc0,0xbd
	.byte	0xa1,0xc8,0x8d,0xb1,0xc0,0xe8,0xe0,0x10
	.byte	0xd0,0xf1,0x8d,0x59,0xc0,0x60,0xad,0xfb
	.byte	0x07,0x29,0x08,0xf0,0x09,0x20,0x93,0xfe
	.byte	0x20,0x22,0xfc,0x20,0x89,0xfe,0x68,0xa8
	.byte	0x68,0xaa,0x68,0x60,0x20,0xd1,0xc8,0xe6
	.byte	0x4e,0xd0,0x02,0xe6,0x4f,0xad,0x00,0xc0
	.byte	0x10,0xf5,0x20,0x5c,0xc8,0x90,0xf0,0x2c
	.byte	0x10,0xc0,0x18,0x60,0xc9,0x8b,0xd0,0x02
	.byte	0xa9,0xdb,0xc9,0x81,0xd0,0x0a,0xad,0xfb
	.byte	0x07,0x49,0x40,0x8d,0xfb,0x07,0xb0,0xe7
	.byte	0x48,0xad,0xfb,0x07,0x0a,0x0a,0x68,0x90
	.byte	0x1f,0xc9,0xb0,0x90,0x1b,0x2c,0x63,0xc0
	.byte	0x30,0x14,0xc9,0xb0,0xf0,0x0e,0xc9,0xc0
	.byte	0xd0,0x02,0xa9,0xd0,0xc9,0xdb,0x90,0x08
	.byte	0x29,0xcf,0xd0,0x04,0xa9,0xdd,0x09,0x20
	.byte	0x48,0x29,0x7f,0x8d,0x7b,0x06,0x68,0x38
	.byte	0x60,0x7b,0x50,0x5e,0x29,0x1b,0x08,0x18
	.byte	0x19,0x00,0x08,0xe0,0x08,0x00,0x00,0x00
	.byte	0x00,0x8d,0x7b,0x06,0xa5,0x25,0xcd,0xfb
	.byte	0x05,0xf0,0x06,0x8d,0xfb,0x05,0x20,0x04
	.byte	0xca,0xa5,0x24,0xcd,0x7b,0x05,0x90,0x03
	.byte	0x8d,0x7b,0x05,0xad,0x7b,0x06,0x20,0x89
	.byte	0xca,0xa9,0x0f,0x8d,0xb0,0xc0,0xad,0x7b
	.byte	0x05,0xc9,0x50,0xb0,0x13,0x6d,0x7b,0x04
	.byte	0x8d,0xb1,0xc0,0xa9,0x0e,0x8d,0xb0,0xc0
	.byte	0xa9,0x00,0x6d,0xfb,0x04,0x8d,0xb1,0xc0
	.byte	0x60,0x49,0xc0,0xc9,0x08,0xb0,0x1d,0xa8
	.byte	0xa9,0xc9,0x48,0xb9,0xf2,0xcb,0x48,0x60
	.byte	0xea,0xac,0x7b,0x05,0xa9,0xa0,0x20,0x71
	.byte	0xca,0xc8,0xc0,0x50,0x90,0xf8,0x60,0xa9
	.byte	0x34,0x8d,0x7b,0x07,0x60,0xa9,0x32,0xd0
	.byte	0xf8,0xa0,0xc0,0xa2,0x80,0xca,0xd0,0xfd
	.byte	0xad,0x30,0xc0,0x88,0xd0,0xf5,0x60,0xac
	.byte	0x7b,0x05,0xc0,0x50,0x90,0x05,0x48,0x20
	.byte	0xb0,0xc9,0x68,0xac,0x7b,0x05,0x20,0x71
	.byte	0xca,0xee,0x7b,0x05,0x2c,0x78,0x04,0x10
	.byte	0x07,0xad,0x7b,0x05,0xc9,0x50,0xb0,0x68
	.byte	0x60,0xac,0x7b,0x05,0xad,0xfb,0x05,0x48
	.byte	0x20,0x07,0xca,0x20,0x04,0xc9,0xa0,0x00
	.byte	0x68,0x69,0x00,0xc9,0x18,0x90,0xf0,0xb0
	.byte	0x23,0x20,0x67,0xc9,0x98,0xf0,0xe8,0xa9
	.byte	0x00,0x8d,0x7b,0x05,0x8d,0xfb,0x05,0xa8
	.byte	0xf0,0x12,0xce,0x7b,0x05,0x10,0x9d,0xa9
	.byte	0x4f,0x8d,0x7b,0x05,0xad,0xfb,0x05,0xf0
	.byte	0x93,0xce,0xfb,0x05,0x4c,0x04,0xca,0xa9
	.byte	0x30,0x8d,0x7b,0x07,0x68,0x09,0x80,0xc9
	.byte	0xb1,0xd0,0x67,0xa9,0x08,0x8d,0x58,0xc0
	.byte	0xd0,0x5b,0xc9,0xb2,0xd0,0x51,0xa9,0xfe
	.byte	0x2d,0xfb,0x07,0x8d,0xfb,0x07,0x60,0x8d
	.byte	0x7b,0x06,0x4e,0x78,0x04,0x4c,0xcb,0xc8
	.byte	0x20,0x27,0xca,0xee,0xfb,0x05,0xad,0xfb
	.byte	0x05,0xc9,0x18,0x90,0x4a,0xce,0xfb,0x05
	.byte	0xad,0xfb,0x06,0x69,0x04,0x29,0x7f,0x8d
	.byte	0xfb,0x06,0x20,0x12,0xca,0xa9,0x0d,0x8d
	.byte	0xb0,0xc0,0xad,0x7b,0x04,0x8d,0xb1,0xc0
	.byte	0xa9,0x0c,0x8d,0xb0,0xc0,0xad,0xfb,0x04
	.byte	0x8d,0xb1,0xc0,0xa9,0x17,0x20,0x07,0xca
	.byte	0xa0,0x00,0x20,0x04,0xc9,0xb0,0x95,0xc9
	.byte	0xb3,0xd0,0x0e,0xa9,0x01,0x0d,0xfb,0x07
	.byte	0xd0,0xa9,0xc9,0xb0,0xd0,0x9c,0x4c,0x09
	.byte	0xc8,0x4c,0x27,0xc9,0xad,0xfb,0x05,0x8d
	.byte	0xf8,0x04,0x0a,0x0a,0x6d,0xf8,0x04,0x6d
	.byte	0xfb,0x06,0x48,0x4a,0x4a,0x4a,0x4a,0x8d
	.byte	0xfb,0x04,0x68,0x0a,0x0a,0x0a,0x0a,0x8d
	.byte	0x7b,0x04,0x60,0xc9,0x0d,0xd0,0x06,0xa9
	.byte	0x00,0x8d,0x7b,0x05,0x60,0x09,0x80,0xc9
	.byte	0xa0,0xb0,0xce,0xc9,0x87,0x90,0x08,0xa8
	.byte	0xa9,0xc9,0x48,0xb9,0xb9,0xc9,0x48,0x60
	.byte	0x18,0x71,0x13,0xb2,0x48,0x60,0xaf,0x9d
	.byte	0xf2,0x13,0x13,0x13,0x13,0x13,0x13,0x13
	.byte	0x13,0x13,0x66,0x0e,0x13,0x38,0x00,0x14
	.byte	0x7b,0x18,0x98,0x6d,0x7b,0x04,0x48,0xa9
	.byte	0x00,0x6d,0xfb,0x04,0x48,0x0a,0x29,0x0c
	.byte	0xaa,0xbd,0xb0,0xc0,0x68,0x4a,0x68,0xaa
	.byte	0x60,0x0a,0x48,0xad,0xfb,0x07,0x4a,0x68
	.byte	0x6a,0x48,0x20,0x59,0xca,0x68,0xb0,0x05
	.byte	0x9d,0x00,0xcc,0x90,0x03,0x9d,0x00,0xcd
	.byte	0x60,0x48,0xa9,0xf7,0x20,0xa0,0xc9,0x8d
	.byte	0x59,0xc0,0xad,0x7b,0x07,0x29,0x07,0xd0
	.byte	0x04,0x68,0x4c,0x23,0xca,0x29,0x04,0xf0
	.byte	0x03,0x4c,0x87,0xc9,0x68,0x38,0xe9,0x20
	.byte	0x29,0x7f,0x48,0xce,0x7b,0x07,0xad,0x7b
	.byte	0x07,0x29,0x03,0xd0,0x15,0x68,0xc9,0x18
	.byte	0xb0,0x03,0x8d,0xfb,0x05,0xad,0xf8,0x05
	.byte	0xc9,0x50,0xb0,0x03,0x8d,0x7b,0x05,0x4c
	.byte	0x04,0xca,0x68,0x8d,0xf8,0x05,0x60,0xad
	.byte	0x00,0xc0,0xc9,0x93,0xd0,0x0f,0x2c,0x10
	.byte	0xc0,0xad,0x00,0xc0,0x10,0xfb,0xc9,0x83
	.byte	0xf0,0x03,0x2c,0x10,0xc0,0x60,0xa8,0xb9
	.byte	0x31,0xcb,0x20,0xf1,0xc8,0x20,0x44,0xc8
	.byte	0xc9,0xce,0xb0,0x08,0xc9,0xc9,0x90,0x04
	.byte	0xc9,0xcc,0xd0,0xea,0x4c,0xf1,0xc8,0xea
	.byte	0x2c,0xcb,0xff,0x70,0x31,0x38,0x90,0x18
	.byte	0xb8,0x50,0x2b,0x01,0x82,0x11,0x14,0x1c
	.byte	0x22,0x4c,0x00,0xc8,0x20,0x44,0xc8,0x29
	.byte	0x7f,0xa2,0x00,0x60,0x20,0xa7,0xc9,0xa2
	.byte	0x00,0x60,0xc9,0x00,0xf0,0x09,0xad,0x00
	.byte	0xc0,0x0a,0x90,0x03,0x20,0x5c,0xc8,0xa2
	.byte	0x00,0x60,0x91,0x28,0x38,0xb8,0x8d,0xff
	.byte	0xcf,0x48,0x85,0x35,0x8a,0x48,0x98,0x48
	.byte	0xa5,0x35,0x86,0x35,0xa2,0xc3,0x8e,0x78
	.byte	0x04,0x48,0x50,0x10,0xa9,0x32,0x85,0x38
	.byte	0x86,0x39,0xa9,0x07,0x85,0x36,0x86,0x37
	.byte	0x20,0x00,0xc8,0x18,0x90,0x6f,0x68,0xa4
	.byte	0x35,0xf0,0x1f,0x88,0xad,0x78,0x06,0xc9
	.byte	0x88,0xf0,0x17,0xd9,0x00,0x02,0xf0,0x12
	.byte	0x49,0x20,0xd9,0x00,0x02,0xd0,0x3b,0xad
	.byte	0x78,0x06,0x99,0x00,0x02,0xb0,0x03,0x20
	.byte	0xed,0xca,0xa9,0x80,0x20,0xf5,0xc9,0x20
	.byte	0x44,0xc8,0xc9,0x9b,0xf0,0xf1,0xc9,0x8d
	.byte	0xd0,0x05,0x48,0x20,0x01,0xc9,0x68,0xc9
	.byte	0x95,0xd0,0x12,0xac,0x7b,0x05,0x20,0x59
	.byte	0xca,0xb0,0x05,0xbd,0x00,0xcc,0x90,0x03
	.byte	0xbd,0x00,0xcd,0x09,0x80,0x8d,0x78,0x06
	.byte	0xd0,0x08,0x20,0x44,0xc8,0xa0,0x00,0x8c
	.byte	0x78,0x06,0xba,0xe8,0xe8,0xe8,0x9d,0x00
	.byte	0x01,0xa9,0x00,0x85,0x24,0xad,0xfb,0x05
	.byte	0x85,0x25,0x4c,0x2e,0xc8,0x68,0xac,0xfb
	.byte	0x07,0x10,0x08,0xac,0x78,0x06,0xc0,0xe0
	.byte	0x90,0x01,0x98,0x20,0xb1,0xc8,0x20,0xcf
	.byte	0xca,0xa9,0x7f,0x20,0xa0,0xc9,0xad,0x7b
	.byte	0x05,0xe9,0x47,0x90,0xd4,0x69,0x1f,0x18
	.byte	0x90,0xd1,0x60,0x38,0x71,0xb2,0x7b,0x00
	.byte	0x48,0x66,0xc4,0xc2,0xc1,0xff,0xc3,0xea


// Variable data

.data

cnx_handle:
	.word	0
data_handle:
	.word	0
msg_gui:
	.byte	'0',0,0,' '		// effects, x, y, character
msg_text:
	.ascii	"\x1B[..;..H"
	.ascii	"\x1B[.m"
	.ascii	"."
msg_gr:
	.ascii	"\x1B[..;..H"
	.ascii	"\x1B[...;...m"
	.ascii	"\xE2\x96\x84"
screen:
	.byte	1			// 1 = text, 2 = mixed, 4 = page2, 8 = hi-res, 10 = 80 col
	.byte	0			// register number
	.byte	0			// 1 = must refresh
	.byte	0x7b			// R0
	.byte	0x50			// R1
	.byte	0x62			// R2
	.byte	0x29			// R3
	.byte	0x1b			// R4
	.byte	0x08			// R5
	.byte	0x18			// R6
	.byte	0x19			// R7
	.byte	0x00			// R8
	.byte	0x08			// R9
	.byte	0xc0			// R10
	.byte	0x08			// R11
	.byte	0x00			// R12
	.byte	0x00			// R13
	.byte	0x00			// R14
	.byte	0x00			// R15
	.byte	0x00			// R16
	.byte	0x00			// R17
