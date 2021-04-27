// COMPOTE Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Macro instructions

.include "defs.s"

// Get address (for write operations)
	.macro	a_zp reg
	ldrb	\reg,[MEM,PC_REG_64]
	add	PC_REG,PC_REG,#1
	.endm

	.macro	a_zp_x reg
	ldrb	w0,[MEM,PC_REG_64]
	add	PC_REG,PC_REG,#1
	add	\reg,w0,X_REG
	and	\reg,\reg,#0xFF
	.endm

	.macro	a_abs reg
	ldrh	\reg,[MEM,PC_REG_64]
	add	PC_REG,PC_REG,#2
	.endm

	.macro	a_abs_x reg
	ldrh	w0,[MEM,PC_REG_64]
	add	PC_REG,PC_REG,#2
	add	\reg,w0,X_REG
	.endm

	.macro	a_abs_y reg
	ldrh	w0,[MEM,PC_REG_64]
	add	PC_REG,PC_REG,#2
	add	\reg,w0,Y_REG
	.endm

	.macro	a_ind_y reg
	ldrb	w0,[MEM,PC_REG_64]
	add	PC_REG,PC_REG,#1
	ldrh	w0,[MEM,x0]
	add	\reg,w0,Y_REG
	.endm

	.macro	a_rel reg
	ldrb	w0,[MEM,PC_REG_64]
	add	PC_REG,PC_REG,#1
	add	\reg,PC_REG,w0,SXTB
	.endm

// Get value (for read operations)
	.macro	v_imm reg
	ldrb	\reg,[MEM,PC_REG_64]
	add	PC_REG,PC_REG,#1
	.endm

	.macro	v_zp reg
	ldrb	w0,[MEM,PC_REG_64]
	add	PC_REG,PC_REG,#1
	fetch	\reg,x0
	.endm

	.macro	v_zp_x reg
	ldrb	w0,[MEM,PC_REG_64]
	add	PC_REG,PC_REG,#1
	add	w0,w0,X_REG
	and	w0,w0,#0xFF
	fetch	\reg,x0
	.endm

	.macro	v_abs reg
	ldrh	w0,[MEM,PC_REG_64]
	add	PC_REG,PC_REG,#2
	fetch	\reg,x0
	.endm

	.macro	v_abs_x reg
	ldrh	w0,[MEM,PC_REG_64]
	add	PC_REG,PC_REG,#2
	add	w0,w0,X_REG
	fetch	\reg,x0
	.endm

	.macro	v_abs_y reg
	ldrh	w0,[MEM,PC_REG_64]
	add	PC_REG,PC_REG,#2
	add	w0,w0,Y_REG
	fetch	\reg,x0
	.endm

	.macro	v_ind_x reg
	ldrb	w0,[MEM,PC_REG_64]
	add	PC_REG,PC_REG,#1
	add	w0,w0,X_REG
	and	w0,w0,#0xFF
	ldrh	w0,[MEM,x0]
	fetch	\reg,x0
	.endm

	.macro	v_ind_y reg
	ldrb	w0,[MEM,PC_REG_64]
	add	PC_REG,PC_REG,#1
	ldrh	w0,[MEM,x0]
	add	w0,w0,Y_REG
	fetch	\reg,x0
	.endm

// Stack usage
	.macro	push_b reg
	strb	\reg,[MEM,SP_REG_64]
	sub	SP_REG,SP_REG,#1
	.endm

	.macro	push_h reg
	sub	SP_REG,SP_REG,#1
	strh	\reg,[MEM,SP_REG_64]
	sub	SP_REG,SP_REG,#1
	.endm

	.macro	pop_b reg
	add	SP_REG,SP_REG,#1
	ldrb	\reg,[MEM,SP_REG_64]
	.endm

	.macro	pop_h reg
	add	SP_REG,SP_REG,#1
	ldrh	\reg,[MEM,SP_REG_64]
	add	SP_REG,SP_REG,#1
	.endm


// Set status register flags
	.macro	c_flag reg,mask
	tst	\reg,\mask
	b.ne	1f
	and	S_REG,S_REG,~C_FLAG
	b	2f
1:	orr	S_REG,S_REG,C_FLAG
2:
	.endm

	.macro	z_flag reg,mask
	tst	\reg,\mask
	b.eq	1f
	and	S_REG,S_REG,~Z_FLAG
	b	2f
1:	orr	S_REG,S_REG,Z_FLAG
2:
	.endm

	.macro	n_flag reg,mask
	tst	\reg,\mask
	b.ne	1f
	and	S_REG,S_REG,~N_FLAG
	b	2f
1:	orr	S_REG,S_REG,N_FLAG
2:
	.endm

	.macro	v_flag reg,mask
	tst	\reg,\mask
	b.ne	1f
	and	S_REG,S_REG,~V_FLAG
	b	2f
1:	orr	S_REG,S_REG,V_FLAG
2:
	.endm

	.macro	c_inv
	eor	S_REG,S_REG,C_FLAG
	.endm

	// http://www.righto.com/2012/12/the-6502-overflow-flag-explained.html
	.macro	overflow result,op1,op2
	eor	w4,\op1,\result
	eor	w5,\op2,\result
	and	w6,w4,w5
	v_flag	w6,#0x80
	.endm

	.macro	compare reg,with
	sub	w1,\reg,\with
	c_flag	w1,#0x100
	c_inv
	z_flag	w1,#0xFF
	n_flag	w1,#0x80
	.endm

// Transfer carry from 6502 status register to ARM 64 status register
	.macro	t_carry
	mrs	x3,nzcv
	tst	S_REG,C_FLAG
	b.eq	1f
	orr	w3,w3,#0x20000000
	b	2f
1:	and	w3,w3,#0xDFFFFFFF
2:	msr	nzcv,x3
	.endm

// Access to memory
// Handles special I/O addresses
	.macro	fetch reg,where
	cmp	\where,#0xC000		// Read I/O
	b.lt	1f
	mov	IO_64,#0xC100
	cmp	\where,IO_64
	b.ge	1f
	mov	IO_64,\where
	bl	fetch_io
	mov	\reg,IO
	b	2f
1:	ldrb	\reg,[MEM,\where]	// Load the byte
2:
	.endm

	.macro	store reg,where
	cmp	\where,#0xD000		// Don't write in ROM!
	b.ge	1f
	strb	\reg,[MEM,\where]	// Store the byte
	cmp	\where,#0x0400		// Write I/O
	b.lt	1f
	cmp	\where,#0x0800
	b.ge	1f
	mov	IO_64,\where
	bl	store_io
1:
	.endm

// Text output
	.macro	char reg,where
	strb	\reg,[x3,#\where]
	.endm

	.macro	hex_8 reg,where
	mov	w1,\reg,LSR #4
	and	w1,w1,#0xF
	and	w0,\reg,#0xF
	ldrb	w4,[x2,x1]
	strb	w4,[x3,#\where]
	ldrb	w4,[x2,x0]
	strb	w4,[x3,#(\where+1)]
	.endm

	.macro	hex_16 reg,where
	mov	w0,\reg,LSR #12
	and	w0,w0,#0xF
	ldrb	w4,[x2,x0]
	strb	w4,[x3,#\where]
	mov	w0,\reg,LSR #8
	and	w0,w0,#0xF
	ldrb	w4,[x2,x0]
	strb	w4,[x3,#(\where+1)]
	mov	w0,\reg,LSR #4
	and	w0,w0,#0xF
	ldrb	w4,[x2,x0]
	strb	w4,[x3,#(\where+2)]
	mov	w0,\reg
	and	w0,w0,#0xF
	ldrb	w4,[x2,x0]
	strb	w4,[x3,#(\where+3)]
	.endm

	.macro	dec_8 reg,where
	mov	w4,#10
	udiv 	w0,\reg,w4
	msub	w1,w0,w4,\reg
	add	w0,w0,#'0'
	strb	w0,[x3,#\where]
	add	w1,w1,#'0'
	strb	w1,[x3,#(\where+1)]
	.endm

	.macro	s_bit flag,letter,where
	tst	S_REG,#\flag
	b.eq	1f
	mov	w0,\letter
	b	2f
1:	mov	w0,'.'
2:	strb	w0,[x3,#\where]
	.endm

	.macro	write len
	mov	w0,#STDOUT
	mov	x1,x3
	mov	w2,#\len
	mov	w8,#WRITE
	svc	0
	.endm
