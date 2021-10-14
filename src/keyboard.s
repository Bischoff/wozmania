// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Apple keyboard

.global prepare_keyboard
.global intercept_ctl_c
.global keyboard_read
.global keyboard_write
.global no_key
.global restore_keyboard
.global kbd

.include "src/defs.s"
.include "src/macros.s"

// Set non-blocking keyboard
prepare_keyboard:
	mov	w0,#STDIN		// get previous terminal definition
	mov	w1,#TCGETS
	ldr	x2,=termios
	mov	w8,#IOCTL
	svc	0
	ldr	x2,=termios		// amend it
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
	ldr	x1,=sigaction		// SA_MASK and SA_FLAGS entries are already zero
	adr	x0,ctl_reset
	str	x0,[x1,#SA_HANDLER]
	mov	w0,#SIGINT
	mov	x2,#0
	mov	w3,#8
	mov	w8,#RT_SIGACTION
	svc	0
	mov	w0,#0			// clear previous reset
	strb	w0,[KEYBOARD,#KBD_RESET]
	br	lr

// Ctrl-C handler
// We emulate Ctrl-Reset key
ctl_reset:
	mov	w0,#1
	strb	w0,[KEYBOARD,#KBD_RESET]
	br	lr

// Keyboard I/O addresses
keyboard_read:
	cmp	ADDR,#KBD
	b.eq	read_key
	mov	w0,#KBDSTRB
	cmp	ADDR,w0
	b.eq	clear_strobe
	b	nothing_to_read

keyboard_write:
	mov	w0,#KBDSTRB
	cmp	ADDR,w0
	b.eq	clear_strobe
	b	nothing_to_read

// Read a key and set key strobe if successful
// Part of this code is extra complicated due to the fact we use an ANSI terminal
// That will go away when we switch to a real graphical window of our own
read_key:
	ldrb	w0,[KEYBOARD,#KBD_STROBE]
	tst	w0,#0xFF
	b.eq	slow_polling
	mov	w0,#KBD_LASTKEY
	b	analyze_key
slow_polling:
	ldrh	w0,[KEYBOARD,#KBD_WAIT]
	add	w0,w0,#1
	strh	w0,[KEYBOARD,#KBD_WAIT]
	ldrb	w1,[KEYBOARD,#KBD_POLL_RATIO]
	lsr	w0,w0,w1
	tst	w0,#0xFF
	b.eq	no_key
	mov	w0,#0
	strh	w0,[KEYBOARD,#KBD_WAIT]
get_key:
	mov	w0,#STDIN
	mov	x1,KEYBOARD
	mov	w2,#1
	mov	w8,#READ
	svc	0
	cmp	w0,#1
	b.lt	no_key
	mov	w0,#KBD_BUFFER
analyze_key:
	ldrb	VALUE,[KEYBOARD,x0]
	ldrb	w0,[KEYBOARD,#KBD_KEYSEQ]
	cmp	w0,#SEQ
	b.ne	escape
	cmp	VALUE,#0x0A		// carriage return
	b.ne	1f
	mov	VALUE,#0x8D
	b	found_key
1:	cmp	VALUE,#0x1B
	b.ne	2f
	mov	w0,#SEQ_ESC
	strb	w0,[KEYBOARD,#KBD_KEYSEQ]
	b	no_key
2:	orr	VALUE,VALUE,#0x80
	b	found_key
escape:
	cmp	w0,#SEQ_ESC
	b.ne	escape_bracket
	cmp	VALUE,#'['
	b.ne	1f
	mov	w0,#SEQ_ESC_BRA
	b	3f
1:	cmp	VALUE,#'O'
	b.ne	2f
	mov	w0,#SEQ_ESC_O
	b	3f
2:	mov	w0,#SEQ
3:	strb	w0,[KEYBOARD,#KBD_KEYSEQ]
	b	no_key
escape_bracket:
	cmp	w0,#SEQ_ESC_BRA
	b.ne	escape_o
	cmp	VALUE,#'A'		// up
	b.ne	1f
	mov	VALUE,#0x8B
	b	5f
1:	cmp	VALUE,#'B'		// down
	b.ne	2f
	mov	VALUE,#0x8A
	b	5f
2:	cmp	VALUE,#'C'		// right
	b.ne	3f
	mov	VALUE,#0x95
	b	5f
3:	cmp	VALUE,#'D'		// left
	b.ne	4f
	mov	VALUE,#0x88
	b	5f
4:	mov	w0,#SEQ
	strb	w0,[KEYBOARD,#KBD_KEYSEQ]
	b	no_key
5:	mov	w0,#SEQ
	strb	w0,[KEYBOARD,#KBD_KEYSEQ]
	b	found_key
escape_o:
	cmp	VALUE,#'P'		// F1 = flush floppy disks
	b.ne	1f
	mov	w0,#SEQ
	strb	w0,[KEYBOARD,#KBD_KEYSEQ]
	b	flush_disks
1:	cmp	VALUE,#'R'		// F3 = Ctrl-C
	b.ne	2f
	mov	VALUE,#0x83
	b	4f
2:	cmp	VALUE,#'S'		// F4 = power off
	b.ne	3f
	b	exit
3:	mov	w0,#SEQ
	strb	w0,[KEYBOARD,#KBD_KEYSEQ]
	b	no_key
4:	mov	w0,#SEQ
	strb	w0,[KEYBOARD,#KBD_KEYSEQ]
	b	found_key
found_key:
	strb	VALUE,[KEYBOARD,#KBD_LASTKEY]
	mov	w0,#1
	strb	w0,[KEYBOARD,#KBD_STROBE]
	br	lr
no_key:
	mov	VALUE,#0x00
	mov	w0,#0
	strb	w0,[KEYBOARD,#KBD_STROBE]
	br	lr

// Clear strobe to prepare for next read
clear_strobe:
	b	no_key

// Flush all disks on demand
flush_disks:
	mov	x14,lr
	mov	x13,DRIVE
	ldr	DRIVE,=drive1
	bl	flush_drive
	ldr	DRIVE,=drive2
	bl	flush_drive
	mov	DRIVE,x13
	mov	lr,x14
	b	no_key

// Restore keyboard on exit
restore_keyboard:
	ldr	x2,=termios		// restore normal keyboard
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
	.byte	0			// buffer
	.byte	0			// strobe
	.byte	0			// last key
	.byte	8			// poll ratio
	.hword	0			// wait counter to slow down polling
	.byte	0			// key sequence
	.byte	0			// reset
