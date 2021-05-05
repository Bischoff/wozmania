// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Apple keyboard

.global prepare_keyboard
.global intercept_ctl_c
.global keyboard
.global clear_strobe
.global restore_keyboard
.global kbd

.include "src/defs.s"
.include "src/macros.s"

// Set non-blocking keyboard
prepare_keyboard:
	mov	w0,#STDIN	// get previous terminal definition
	mov	w1,#TCGETS
	ldr	x2,=termios
	mov	w8,#IOCTL
	svc	0
	ldr	x2,=termios	// amend it
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

// Intercept Ctrl-C
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

// Ctrl-C handler
// We emulate Ctrl-Reset key
ctl_reset:
	mov	w0,#1
	strb	w0,[KEYBOARD,#KBD_RESET]
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

// Restore keyboard on exit
restore_keyboard:
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
	br	lr

// Variable data

.data

termios:
	.fill	SIZEOF_TERMIOS,1,0
sigaction:
	.fill	SIZEOF_SIGACTION,1,0
kbd:
	.byte	0		// buffer
	.byte	0		// strobe
	.byte	0		// last key
	.byte	0		// key sequence
	.byte	0		// reset
