// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Macro instructions

// Get address (for write operations)
	.macro	a_zp reg
	fetch_b	\reg,PC_REG
	add	PC_REG,PC_REG,#1
	.endm

	.macro	a_zp_x reg
	fetch_b	w0,PC_REG
	add	PC_REG,PC_REG,#1
	add	\reg,w0,X_REG
	and	\reg,\reg,#0xFF
	.endm

	.macro	a_zp_y reg
	fetch_b	w0,PC_REG
	add	PC_REG,PC_REG,#1
	add	\reg,w0,Y_REG
	and	\reg,\reg,#0xFF
	.endm

	.macro	a_abs reg
	fetch_h	\reg,PC_REG
	add	PC_REG,PC_REG,#2
	.endm

	.macro	a_abs_x reg
	fetch_h	w0,PC_REG
	add	PC_REG,PC_REG,#2
	add	\reg,w0,X_REG
	.endm

	.macro	a_abs_y reg
	fetch_h	w0,PC_REG
	add	PC_REG,PC_REG,#2
	add	\reg,w0,Y_REG
	.endm

	.macro	a_ind_x reg
	fetch_b	w0,PC_REG
	add	PC_REG,PC_REG,#1
	add	w0,w0,X_REG
	and	w0,w0,#0xFF
	fetch_h	\reg,w0
	.endm

	.macro	a_ind_y reg
	fetch_b	w0,PC_REG
	add	PC_REG,PC_REG,#1
	fetch_h	w0,w0
	add	\reg,w0,Y_REG
	.endm

	.macro	a_rel reg
	fetch_b	w0,PC_REG
	add	PC_REG,PC_REG,#1
	add	\reg,PC_REG,w0,SXTB
	.endm

// Get value (for read operations)
	.macro	v_imm reg
	fetch_b	\reg,PC_REG
	add	PC_REG,PC_REG,#1
	.endm

	.macro	v_zp reg
	fetch_b	w0,PC_REG
	add	PC_REG,PC_REG,#1
	fe_zp_b	\reg,w0
	.endm

	.macro	v_zp_x reg
	fetch_b	w0,PC_REG
	add	PC_REG,PC_REG,#1
	add	w0,w0,X_REG
	and	w0,w0,#0xFF
	fe_zp_b	\reg,w0
	.endm

	.macro	v_zp_y reg
	fetch_b	w0,PC_REG
	add	PC_REG,PC_REG,#1
	add	w0,w0,Y_REG
	and	w0,w0,#0xFF
	fe_zp_b	\reg,w0
	.endm

	.macro	v_abs reg
	fetch_h	w0,PC_REG
	add	PC_REG,PC_REG,#2
	fetch_b	\reg,w0
	.endm

	.macro	v_abs_x reg
	fetch_h	w0,PC_REG
	add	PC_REG,PC_REG,#2
	add	w0,w0,X_REG
	fetch_b	\reg,w0
	.endm

	.macro	v_abs_y reg
	fetch_h	w0,PC_REG
	add	PC_REG,PC_REG,#2
	add	w0,w0,Y_REG
	fetch_b	\reg,w0
	.endm

	.macro	v_ind_x reg
	fetch_b	w0,PC_REG
	add	PC_REG,PC_REG,#1
	add	w0,w0,X_REG
	and	w0,w0,#0xFF
	fe_zp_h	w0,w0
	fetch_b	\reg,w0
	.endm

	.macro	v_ind_y reg
	fetch_b	w0,PC_REG
	add	PC_REG,PC_REG,#1
	fe_zp_h	w0,w0
	add	w0,w0,Y_REG
	fetch_b	\reg,w0
	.endm

// Stack usage
	.macro	push_b reg
	strb	\reg,[MEM,SP_REG_64]
	sub	SP_REG,SP_REG,#1
	and	SP_REG,SP_REG,#0xFF
	orr	SP_REG,SP_REG,#0x100
	.endm

	.macro	push_h reg
	sub	SP_REG,SP_REG,#1
	strh	\reg,[MEM,SP_REG_64]	// might dirty address $FF :-(
	sub	SP_REG,SP_REG,#1
	and	SP_REG,SP_REG,#0xFF
	orr	SP_REG,SP_REG,#0x100
	.endm

	.macro	pop_b reg
	add	SP_REG,SP_REG,#1
	ldrb	\reg,[MEM,SP_REG_64]
	and	SP_REG,SP_REG,#0xFF
	orr	SP_REG,SP_REG,#0x100
	.endm

	.macro	pop_h reg
	add	SP_REG,SP_REG,#1
	ldrh	\reg,[MEM,SP_REG_64]	// might dirty address $200 :-(
	add	SP_REG,SP_REG,#1
	and	SP_REG,SP_REG,#0xFF
	orr	SP_REG,SP_REG,#0x100
	.endm

// Set status register flags
	.macro	c_flag reg,mask
	tst	\reg,\mask
	b.ne	1f
	and	S_REG,S_REG,#~C_FLAG
	b	2f
1:	orr	S_REG,S_REG,#C_FLAG
2:
	.endm

	.macro	z_flag reg,mask
	tst	\reg,\mask
	b.eq	1f
	and	S_REG,S_REG,#~Z_FLAG
	b	2f
1:	orr	S_REG,S_REG,#Z_FLAG
2:
	.endm

	.macro	n_flag reg,mask
	tst	\reg,\mask
	b.ne	1f
	and	S_REG,S_REG,#~N_FLAG
	b	2f
1:	orr	S_REG,S_REG,#N_FLAG
2:
	.endm

	.macro	v_flag reg,mask
	tst	\reg,\mask
	b.ne	1f
	and	S_REG,S_REG,#~V_FLAG
	b	2f
1:	orr	S_REG,S_REG,#V_FLAG
2:
	.endm

	.macro	c_inv
	eor	S_REG,S_REG,#C_FLAG
	.endm

	.macro	overflow result,op1,op2
	eor	w4,\op1,\result
	eor	w5,\op2,\result
	and	w6,w4,w5
	v_flag	w6,#0x80
	.endm

// Transfer carry from 6502 status register to ARM 64 status register
	.macro	t_carry
	mrs	x3,nzcv
	tst	S_REG,#C_FLAG
	b.eq	1f
	orr	w3,w3,#0x20000000
	b	2f
1:	and	w3,w3,#0xDFFFFFFF
2:	msr	nzcv,x3
	.endm

// Full instructions
	.macro	compare reg,with
	sub	w1,\reg,\with
	c_flag	w1,#0x100
	c_inv
	z_flag	w1,#0xFF
	n_flag	w1,#0x80
	.endm

	.macro	sub_a,what
	mov	w2,A_REG
	t_carry
	sbc	A_REG,A_REG,\what
	c_flag	A_REG,#0x100
	c_inv
	and	A_REG,A_REG,#0xFF
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	eor	\what,\what,#0xFF
	overflow A_REG,w2,\what
	.endm

	.macro	add_a,what
	mov	w2,A_REG
	t_carry
	adc	A_REG,A_REG,\what
	c_flag	A_REG,#0x100
	and	A_REG,A_REG,#0xFF
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	overflow A_REG,w2,\what
	.endm

	.macro	and_a,what
	and	A_REG,A_REG,\what
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	.endm

	.macro	or_a,what
	orr	A_REG,A_REG,\what
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	.endm

	.macro	eor_a,what
	eor	A_REG,A_REG,\what
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	.endm

	.macro	bit_a,what
	z_flag	\what,A_REG
	n_flag	\what,#0x80
	v_flag	\what,#0x40
	.endm

	.macro	op_asl,reg
	lsl	\reg,\reg,#1
	c_flag	\reg,#0x100
	and	\reg,\reg,#0xFF
	z_flag	\reg,#0xFF
	n_flag	\reg,#0x80
	.endm

	.macro	op_lsr,reg
	c_flag	\reg,#0x01
	lsr	\reg,\reg,#1
	z_flag	\reg,#0xFF
	n_flag	\reg,#0x80
	.endm

	.macro	op_rol,reg
	lsl	\reg,\reg,#1
	and	w2,S_REG,#C_FLAG
	orr	\reg,\reg,w2
	c_flag	\reg,#0x100
	and	\reg,\reg,#0xFF
	z_flag	\reg,#0xFF
	n_flag	\reg,#0x80
	.endm

	.macro	op_ror,reg
	mov	w3,\reg
	lsr	\reg,\reg,#1
	and	w2,S_REG,#C_FLAG
	lsl	w2,w2,#7
	orr	\reg,\reg,w2
	c_flag	w3,#0x01
	z_flag	\reg,#0xFF
	n_flag	\reg,#0x80
	.endm

	.macro	op_dec,reg
	sub	\reg,\reg,#1
	and	\reg,\reg,#0xFF
	z_flag	\reg,#0xFF
	n_flag	\reg,#0x80
	.endm

	.macro	op_inc,reg
	add	\reg,\reg,#1
	and	\reg,\reg,#0xFF
	z_flag	\reg,#0xFF
	n_flag	\reg,#0x80
	.endm

// Access to emulated memory
	.macro	fe_zp_b reg,where
	mov	ADDR,\where
	ldrb	\reg,[MEM,ADDR_64]
	.endm

	.macro	fetch_b reg,where
	mov	ADDR,\where
	bl	fetch_b_addr
	mov	\reg,VALUE
	.endm

	.macro	fe_zp_h reg,where
	mov	ADDR,\where
	ldrh	\reg,[MEM,ADDR_64]
	.endm

	.macro	fetch_h reg,where
	mov	ADDR,\where
	bl	fetch_h_addr
	mov	\reg,VALUE
	.endm

	.macro	st_zp_b reg,where
	mov	ADDR,\where
	strb	\reg,[MEM,ADDR_64]
	.endm

	.macro	store_b reg,where
	mov	ADDR,\where
	mov	VALUE,\reg
	bl	store_b_addr
	.endm

// Floppy disk encoding
	.macro	nibble what,where,counter
	mov	w7,\what
	strb	w7,[\where],#1
	add	\counter,\counter,#1
	.endm

	.macro	en4n4 reg,where,counter	// ABCD EFGH
	mov	w7,#0xaa		// 1010 1010
	and	w8,\reg,w7		// A0C0 E0G0
	lsr	w8,w8,#1		// 0A0C 0E0G
	orr	w8,w8,w7		// 1A1C 1E1G
	strb	w8,[\where],#1
	mov	w7,#0x55		// 0101 0101
	and	w8,\reg,w7		// 0B0D 0F0H
	mov	w7,#0xaa		// 1010 1010
	orr	w8,w8,w7		// 1B1D 1F1H
	strb	w8,[\where],#1
	add	\counter,\counter,#2
	.endm

	.macro	en6n2 what,where2,shift,where6,counter
	.if	\shift == 0
	mov	w7,#0
	.else
	ldrb	w7,[\where2]
	.endif
	and	w8,\what,#0x01
	lsl	w8,w8,#(\shift+1)
	orr	w7,w7,w8
	and	w8,\what,#0x02
	.if	\shift > 1
	lsl	w8,w8,#(\shift-1)
	.else
	lsr	w8,w8,#(1-\shift)
	.endif
	orr	w7,w7,w8
	strb	w7,[\where2],#1
	lsr	w8,\what,#2
	strb	w8,[\where6],#1
	add	\counter,\counter,#1
	.endm

// Configuration options
	.macro	strcmp begin,end,with,jump
	mov	x8,\begin
	mov	x9,\with
1:	ldrb	w10,[x8],#1
	ldrb	w11,[x9],#1
	cmp	w10,w11
	b.ne	2f
	cmp	x8,\end
	b.lt	1b
	ldrb	w11,[x9]
	tst	w11,#0xFF
	b.ne	2f
	b	\jump
2:
	.endm

	.macro	option flag
	ldr	x8,=conf_flags
	ldrb	w9,[x8]
	orr	w9,w9,#\flag
	strb	w9,[x8]
	.endm

// Text output
	.macro	char reg,where
	strb	\reg,[x3,#\where]
	.endm

	.macro	char_i imm,where
	mov	w6,#\imm
	strb	w6,[x3,#\where]
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

	.macro	write where,length
	mov	w0,#\where
	mov	x1,x3
	mov	w2,#\length
	mov	w8,#WRITE
	svc	0
	.endm
