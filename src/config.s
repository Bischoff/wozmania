// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Configuration options

.global load_conf
.global conf_flags

.include "src/defs.s"
.include "src/macros.s"

// Load configuration settings
load_conf:
	mov	w0,#-100		// open configuration file
	adr	x1,conf_filename
	mov	w2,#O_RDONLY
	mov	w8,#OPENAT
	svc	0
	cmp	x0,#-1
	b.eq	1f
	ldr	x1,=buffer		// read configuration file
	mov	w2,#SIZEOF_BUFFER
	mov	w8,#READ
	svc	0
	b	parse_conf
1:	br	lr

// Parse configuration file
//   input: w0 = file length
parse_conf:
	ldr	x1,=buffer		// x1 = pointer to current character
	add	x0,x0,x1		// x0 = pointer to end of file
	mov	w2,#1			// w2 = line number
parse_line:
	mov	x3,x1			// x3 = pointer to start of line
1:	ldrb	w9,[x1],#1
	cmp	w9,#'\n'
	b.eq	2f
	cmp	x1,x0
	b.lt	1b
	mov	x4,x1			// x4 = pointer to end of line
	b	parse_key
2:	sub	x4,x1,#1
parse_key:
	mov	x5,x3			// x5 = pointer to end of key
1:	ldrb	w9,[x5],#1
	cmp	w9,#' '
	b.eq	2f
	cmp	w9,#'#'
	b.eq	3f
	cmp	x5,x4
	b.lt	1b
	cmp	x4,x3			// empty line
	b.eq	end_of_line
	b	syntax_error
2:	sub	x5,x5,#1		// space at end of key
	cmp	x5,x3
	b.eq	syntax_error
	b	skip_space
3:	sub	x5,x5,#1		// comment sign at beginning of line
	cmp	x5,x3
	b.eq	end_of_line
	b	syntax_error
skip_space:
	mov	x6,x5			// x6 = pointer to beginning of value
1:	ldrb	w9,[x6],#1
	cmp	w9,#' '
	b.ne	parse_value
	cmp	x6,x4
	b.lt	1b
	b	syntax_error
parse_value:
	sub	x6,x6,#1
	mov	x7,x6			// x7 = pointer to end of value
1:	ldrb	w9,[x7],#1
	cmp	w9,#' '
	b.eq	2f
	cmp	w9,#'#'
	b.eq	3f
	cmp	x7,x4
	b.lt	1b
	b	recognize_key
2:	sub	x7,x7,#1		// space at end of value
	b	skip_space_2
3:	sub	x7,x7,#1		// comment sign at end of value
	cmp	x7,x6
	b.eq	syntax_error
	b	end_of_line
skip_space_2:
	mov	x8,x7
1:	ldrb	w9,[x8],#1
	cmp	w9,#' '
	b.ne	2f
	cmp	x8,x4
	b.lt	1b
	b	recognize_key
2:	cmp	w9,#'#'
	b.ne	syntax_error
recognize_key:
	adr	x4,key_rom
	strcmp	x3,x5,x4,r_rom
	adr	x4,key_drive1
	strcmp	x3,x5,x4,r_drive1
	adr	x4,key_drive2
	strcmp	x3,x5,x4,r_drive2
	adr	x4,key_langcard
	strcmp	x3,x5,x4,r_langcard
	adr	x4,key_floppy
	strcmp	x3,x5,x4,r_floppy
	adr	x4,key_80col
	strcmp	x3,x5,x4,r_80col
	b	syntax_error
r_rom:
	strcpy	x6,x7,rom_filename
	b	end_of_line
r_drive1:
	strcpy	x6,x7,drive1_filename
	b	end_of_line
r_drive2:
	strcpy	x6,x7,drive2_filename
	b	end_of_line
r_langcard:
	adr	x4,value_disable
	strcmp	x6,x7,x4,end_of_line
	adr	x4,value_enable
	strcmp	x6,x7,x4,r_langcard_enable
	b	syntax_error
r_floppy:
	adr	x4,value_disable
	strcmp	x6,x7,x4,end_of_line
	adr	x4,value_enable
	strcmp	x6,x7,x4,r_floppy_enable
	b	syntax_error
r_80col:
	adr	x4,value_disable
	strcmp	x6,x7,x4,end_of_line
	adr	x4,value_enable
	strcmp	x6,x7,x4,r_80col_enable
	b	syntax_error
r_langcard_enable:
	option	CNF_LANGCARD_E
	b	end_of_line
r_floppy_enable:
	option	CNF_FLOPPY_E
	b	end_of_line
r_80col_enable:
	option	CNF_80COL_E
	b	end_of_line
end_of_line:
	add	w2,w2,#1
	cmp	x1,x0
	b.lt	parse_line
	br	lr
syntax_error:
	ldr	x3,=msg_err_conf
	dec_8	w2,40
	write	STDERR,43
	b	final_exit


// Fixed data

conf_filename:
	.asciz	"/etc/wozmania.conf"
key_rom:
	.asciz	"rom"
key_drive1:
	.asciz	"drive1"
key_drive2:
	.asciz	"drive2"
key_langcard:
	.asciz	"langcard"
key_floppy:
	.asciz	"floppy"
key_80col:
	.asciz	"80col"
value_enable:
	.asciz	"enable"
value_disable:
	.asciz	"disable"


// Variable data

.data

msg_err_conf:
	.ascii	"Syntax error in file wozmania.conf line ..\n"
conf_flags:
	.byte	0			// configuration flags
