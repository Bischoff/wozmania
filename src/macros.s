// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Macro instructions

// Get address (for write operations)
	.macro	a_zp reg
	fetch_b	\reg,PC_REG_64
	add	PC_REG,PC_REG,#1
	.endm

	.macro	a_zp_x reg
	fetch_b	w0,PC_REG_64
	add	PC_REG,PC_REG,#1
	add	\reg,w0,X_REG
	and	\reg,\reg,#0xFF
	.endm

	.macro	a_zp_y reg
	fetch_b	w0,PC_REG_64
	add	PC_REG,PC_REG,#1
	add	\reg,w0,Y_REG
	and	\reg,\reg,#0xFF
	.endm

	.macro	a_abs reg
	fetch_h	\reg,PC_REG_64
	add	PC_REG,PC_REG,#2
	.endm

	.macro	a_abs_x reg
	fetch_h	w0,PC_REG_64
	add	PC_REG,PC_REG,#2
	add	\reg,w0,X_REG
	.endm

	.macro	a_abs_y reg
	fetch_h	w0,PC_REG_64
	add	PC_REG,PC_REG,#2
	add	\reg,w0,Y_REG
	.endm

	.macro	a_ind_x reg
	fetch_b	w0,PC_REG_64
	add	PC_REG,PC_REG,#1
	add	w0,w0,X_REG
	and	w0,w0,#0xFF
	fetch_h	\reg,x0
	.endm

	.macro	a_ind_y reg
	fetch_b	w0,PC_REG_64
	add	PC_REG,PC_REG,#1
	fetch_h	w0,x0
	add	\reg,w0,Y_REG
	.endm

	.macro	a_rel reg
	fetch_b	w0,PC_REG_64
	add	PC_REG,PC_REG,#1
	add	\reg,PC_REG,w0,SXTB
	.endm

// Get value (for read operations)
	.macro	v_imm reg
	fetch_b	\reg,PC_REG_64
	add	PC_REG,PC_REG,#1
	.endm

	.macro	v_zp reg
	fetch_b	w0,PC_REG_64
	add	PC_REG,PC_REG,#1
	fe_zp_b	\reg,x0
	.endm

	.macro	v_zp_x reg
	fetch_b	w0,PC_REG_64
	add	PC_REG,PC_REG,#1
	add	w0,w0,X_REG
	and	w0,w0,#0xFF
	fe_zp_b	\reg,x0
	.endm

	.macro	v_zp_y reg
	fetch_b	w0,PC_REG_64
	add	PC_REG,PC_REG,#1
	add	w0,w0,Y_REG
	and	w0,w0,#0xFF
	fe_zp_b	\reg,x0
	.endm

	.macro	v_abs reg
	fetch_h	w0,PC_REG_64
	add	PC_REG,PC_REG,#2
	fetch_b	\reg,x0
	.endm

	.macro	v_abs_x reg
	fetch_h	w0,PC_REG_64
	add	PC_REG,PC_REG,#2
	add	w0,w0,X_REG
	fetch_b	\reg,x0
	.endm

	.macro	v_abs_y reg
	fetch_h	w0,PC_REG_64
	add	PC_REG,PC_REG,#2
	add	w0,w0,Y_REG
	fetch_b	\reg,x0
	.endm

	.macro	v_ind_x reg
	fetch_b	w0,PC_REG_64
	add	PC_REG,PC_REG,#1
	add	w0,w0,X_REG
	and	w0,w0,#0xFF
	fe_zp_h	w0,x0
	fetch_b	\reg,x0
	.endm

	.macro	v_ind_y reg
	fetch_b	w0,PC_REG_64
	add	PC_REG,PC_REG,#1
	fe_zp_h	w0,x0
	add	w0,w0,Y_REG
	fetch_b	\reg,x0
	.endm

// Stack usage
// For performance reasons, there is no check against overflow or underflow,
// nor any rotation like on a real 6502
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

	.macro	overflow result,op1,op2
	eor	w4,\op1,\result
	eor	w5,\op2,\result
	and	w6,w4,w5
	v_flag	w6,#0x80
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
	ldrb	\reg,[MEM,\where]
	.endm

	.macro	fetch_b reg,where
	mov	ADDR_64,\where
	bl	fetch_b_addr
	mov	\reg,VALUE
	.endm

	.macro	fe_zp_h reg,where
	ldrh	\reg,[MEM,\where]
	.endm

	.macro	fetch_h reg,where
	mov	ADDR_64,\where
	bl	fetch_h_addr
	mov	\reg,VALUE
	.endm

	.macro	st_zp_b reg,where
	strb	\reg,[MEM,\where]
	.endm

	.macro	store_b reg,where
	mov	ADDR_64,\where
	mov	VALUE,\reg
	bl	store_b_addr
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

	.macro	write where,length
	mov	w0,#\where
	mov	x1,x3
	mov	w2,#\length
	mov	w8,#WRITE
	svc	0
	.endm
