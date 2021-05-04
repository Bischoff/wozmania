// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Text output, 40 columns

.global prepare_terminal
.global text
.global clean_exit

.include "defs.s"
.include "macros.s"

// Prepare text terminal
prepare_terminal:
	adr	x3,msg_begin	// clear screen and hide cursor
	write	STDOUT,10
	br	lr

// 40 columns text
text:
	ldr	x3,=msg_text
	mov	w2,ADDR		// line and column
	sub	w2,w2,#LINE1
	and	w0,w2,#0x7F
	lsr	w2,w2,#7
	mov	w4,#40
	udiv	w1,w0,w4
	msub	w5,w1,w4,w0
	cmp	w1,#3
	b.ge	screen_hole
	lsl	w1,w1,#3
	orr	w2,w2,w1
	add	w2,w2,#1
	dec_8	w2,2
	add	w5,w5,#1
	dec_8	w5,5
	ldrb	w1,[MEM,ADDR_64] // text effect and text
	lsr	w0,w1,#2
	and	w0,w0,#0xF8
	adr	x4,video_table
	ldr	x2,[x4,x0]
	br	x2
inverse:
	add	w1,w1,#0x40
inverse1:
	mov	w2,#'7'
	b	effect
flash:
	sub	w1,w1,#0x40
	cmp	w1,#' '
	b.eq	inverse1	// normally, blinking inverse space
flash1:
	mov	w2,#'5'
	b	effect
normal:
	and	w1,w1,#0x7F
	mov	w2,#'0'
effect:
	char	w2,10
	char	w1,12
	write	STDOUT,13
screen_hole:
	br	lr

// Cleanup terminal on exit
clean_exit:
	adr	x3,msg_end	// go to line 25 and restore cursor
	write	STDOUT,14
	b	exit

// Fixed data

video_table:
	.quad	inverse		// 00-3F
	.quad	inverse1
	.quad	flash1		// 40-7F
	.quad	flash
	.quad	normal		// 80-FF
	.quad	normal
	.quad	normal
	.quad	normal
msg_begin:
	.ascii	"\x1B[2J\x1B[?25l"
msg_end:
	.ascii	"\x1B[25;01H\x1B[?25h"

// Variable data

.data

msg_text:
	.ascii	"\x1B[..;..H\x1B[.m."
