// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// 6502 processor instructions

.global instr_table

.include "src/defs.s"
.include "src/macros.s"

ins_brk:			// 00
	add	PC_REG,PC_REG,#1
	push_h	PC_REG
	orr	w0,S_REG,#(B_FLAG | X_FLAG)
	push_b	w0
	mov	x0,#0xFFFA
        fetch_h	PC_REG,x0
	b	emulate

ins_ora_zp:			// 05
	v_zp	w0
	or_a	w0
	b	emulate

ins_asl_zp:			// 06
	a_zp	w0
	fetch_b	w1,x0
	op_asl	w1
	store_b	w1,x0
	b	emulate

ins_slo_zp:			// 07 - undocumented
	a_zp	w0
	fetch_b	w1,x0
	op_asl	w1
	or_a	w1
	store_b	w1,x0
	b	emulate

ins_asl_abs:			// 0E
	a_abs	w0
	fetch_b	w1,x0
	op_asl	w1
	store_b	w1,x0
	b	emulate

ins_php:			// 08
	orr	w0,S_REG,#(B_FLAG | X_FLAG)
	push_b	w0
	b	emulate

ins_ora_imm:			// 09
	v_imm	w0
	or_a	w0
	b	emulate

ins_asl_a:			// 0A
	op_asl	A_REG
	b	emulate

ins_ora_abs:			// 0D
	v_abs	w0
	or_a	w0
	b	emulate

ins_bpl:			// 10
	a_rel	w0
	tst	S_REG,N_FLAG
	b.ne	emulate
	mov	PC_REG,w0
	b	emulate

ins_ora_ind_y:			// 11
	v_ind_y	w0
	or_a	w0
	b	emulate

ins_asl_zp_x:			// 16
	a_zp_x	w0
	fetch_b	w1,x0
	op_asl	w1
	store_b	w1,x0
	b	emulate

ins_clc:			// 18
	and	S_REG,S_REG,~C_FLAG
	b	emulate

ins_ora_abs_y:			// 19
	v_abs_y	w0
	or_a	w0
	b	emulate

ins_ora_abs_x:			// 1D
	v_abs_x	w0
	or_a	w0
	b	emulate

ins_jsr:			// 20
	a_abs	w0
	sub	PC_REG,PC_REG,#1
	push_h	PC_REG
	mov	PC_REG,w0
	b	emulate

ins_bit_zp:			// 24
	v_zp	w0
	bit_a	w0
	b	emulate

ins_and_zp:			// 25
	v_zp	w0
	and_a	w0
	b	emulate

ins_rol_zp:			// 26
	a_zp	w0
	fetch_b	w1,x0
	op_rol	w1
	store_b	w1,x0
	b	emulate

ins_plp:			// 28
	pop_b	S_REG
	and	S_REG,S_REG,#~(X_FLAG | B_FLAG)
	b	emulate

ins_and_imm:			// 29
	v_imm	w0
	and_a	w0
	b	emulate

ins_rol_a:			// 2A
	op_rol	A_REG
	b	emulate

ins_bit_abs:			// 2C
	v_abs	w0
	bit_a	w0
	b	emulate

ins_and_abs:			// 2D
	v_abs	w0
	and_a	w0
	b	emulate

ins_bmi:			// 30
	a_rel	w0
	tst	S_REG,N_FLAG
	b.eq	emulate
	mov	PC_REG,w0
	b	emulate

ins_and_ind_y:			// 31
	v_ind_y	w0
	and_a	w0
	b	emulate

ins_sec:			// 38
	orr	S_REG,S_REG,C_FLAG
	b	emulate

ins_and_abs_y:			// 39
	v_abs_y	w0
	and_a	w0
	b	emulate

ins_rol_abs_x:			// 3E
	a_abs_x	w0
	fetch_b	w1,x0
	op_rol	w1
	store_b	w1,x0
	b	emulate

ins_rti:			// 40
	pop_b	S_REG
	and	S_REG,S_REG,#~(B_FLAG | X_FLAG)
	pop_h	PC_REG
	b	emulate

ins_eor_ind_x:			// 41
	v_ind_x	w0
	eor_a	w0
	b	emulate

ins_ign_zp:			// 44 - undocumented
	v_zp	w0
	b	emulate

ins_eor_zp:			// 45
	v_zp	w0
	eor_a	w0
	b	emulate

ins_lsr_zp:			// 46
	a_zp	w0
	fetch_b	w1,x0
	op_lsr	w1
	store_b	w1,x0
	b	emulate

ins_sre_zp:			// 47 - undocumented
	a_zp	w0
	fetch_b	w1,x0
	op_lsr	w1
	eor_a	w1
	store_b	w1,x0
	b	emulate

ins_pha:			// 48
	push_b	A_REG
	b	emulate

ins_eor_imm:			// 49
	v_imm	w0
	eor_a	w0
	b	emulate

ins_lsr_a:			// 4A
	op_lsr	A_REG
	b	emulate

ins_jmp_abs:			// 4C
	fetch_h	PC_REG,PC_REG_64
	b	emulate

ins_eor_abs:			// 4D
	v_abs	w0
	eor_a	w0
	b	emulate

ins_lsr_abs:			// 4E
	a_abs	w0
	fetch_b	w1,x0
	op_lsr	w1
	store_b	w1,x0
	b	emulate

ins_sre_abs:			// 4F - undocumented
	a_abs	w0
	fetch_b	w1,x0
	op_lsr	w1
	eor_a	w1
	store_b	w1,x0
	b	emulate

ins_bvc:			// 50
	a_rel	w0
	tst	S_REG,V_FLAG
	b.ne	emulate
	mov	PC_REG,w0
	b	emulate

ins_eor_ind_y:			// 51
	v_ind_y	w0
	eor_a	w0
	b	emulate

ins_lsr_zp_x:			// 56
	a_zp_x	w0
	fetch_b	w1,x0
	op_lsr	w1
	store_b	w1,x0
	b	emulate

ins_cli:			// 58
	and	S_REG,S_REG,#~I_FLAG
	b	emulate

ins_eor_abs_y:			// 59
	v_abs_y	w0
	eor_a	w0
	b	emulate

ins_eor_abs_x:			// 5D
	v_abs_x	w0
	eor_a	w0
	b	emulate

ins_lsr_abs_x:			// 5E
	a_abs_x	w0
	fetch_b	w1,x0
	op_lsr	w1
	store_b	w1,x0
	b	emulate

ins_rts:			// 60
	pop_h	PC_REG
	add	PC_REG,PC_REG,#1
	b	emulate

ins_adc_zp:			// 65
	v_zp	w0
	add_a	w0
	b	emulate

ins_ror_zp:			// 66
	a_zp	w0
	fetch_b	w1,x0
	op_ror	w1
	store_b	w1,x0
	b	emulate

ins_pla:			// 68
	pop_b	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	b	emulate

ins_adc_imm:			// 69
	v_imm	w0
	add_a	w0
	b	emulate

ins_ror_a:			// 6A
	op_ror	A_REG
	b	emulate

ins_jmp_ind:			// 6C
	fetch_h	w0,PC_REG_64
	fetch_h	PC_REG,x0
	b	emulate

ins_adc_abs:			// 6D
	v_abs	w0
	add_a	w0
	b	emulate

ins_bvs:			// 70
	a_rel	w0
	tst	S_REG,V_FLAG
	b.eq	emulate
	mov	PC_REG,w0
	b	emulate

ins_adc_ind_y:			// 71
	v_ind_y	w0
	add_a	w0
	b	emulate

ins_ror_zp_x:			// 76
	a_zp_x	w0
	fetch_b	w1,x0
	op_ror	w1
	store_b	w1,x0
	b	emulate

ins_sei:			// 78
	orr	S_REG,S_REG,#I_FLAG
	b	emulate

ins_adc_abs_y:			// 79
	v_abs_y	w0
	add_a	w0
	b	emulate

ins_rra_abs_y:			// 7B - undocumented
	a_abs_y	w0
	fetch_b	w1,x0
	op_ror	w1
	add_a	w1
	store_b	w1,x0
	b	emulate

ins_adc_abs_x:			// 7D
	v_abs_x	w0
	add_a	w0
	b	emulate

ins_ror_abs_x:			// 7E
	a_abs_x	w0
	fetch_b	w1,x0
	op_ror	w1
	store_b	w1,x0
	b	emulate

ins_sta_ind_x:			// 81
	a_ind_x	w0
	store_b	A_REG,x0
	b	emulate

ins_sty_zp:			// 84
	a_zp	w0
	store_b	Y_REG,x0
	b	emulate

ins_sta_zp:			// 85
	a_zp	w0
	store_b	A_REG,x0
	b	emulate

ins_stx_zp:			// 86
	a_zp	w0
	store_b	X_REG,x0
	b	emulate

ins_dey:			// 88
	op_dec	Y_REG
	b	emulate

ins_txa:			// 8A
	mov	A_REG,X_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	b	emulate

ins_sty_abs:			// 8C
	a_abs	w0
	store_b	Y_REG,x0
	b	emulate

ins_sta_abs:			// 8D
	a_abs	w0
	store_b	A_REG,x0
	b	emulate

ins_stx_abs:			// 8E
	a_abs	w0
	store_b	X_REG,x0
	b	emulate

ins_bcc:			// 90
	a_rel	w0
	tst	S_REG,C_FLAG
	b.ne	emulate
	mov	PC_REG,w0
	b	emulate

ins_sta_ind_y:			// 91
	a_ind_y	w0
	store_b	A_REG,x0
	b	emulate

ins_sty_zp_x:			// 94
	a_zp_x	w0
	store_b	Y_REG,x0
	b	emulate

ins_sta_zp_x:			// 95
	a_zp_x	w0
	store_b	A_REG,x0
	b	emulate

ins_tya:			// 98
	mov	A_REG,Y_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	b	emulate

ins_sta_abs_y:			// 99
	a_abs_y	w0
	store_b	A_REG,x0
	b	emulate

ins_txs:			// 9A
	orr	SP_REG,X_REG,#0x100
	b	emulate

ins_sta_abs_x:			// 9D
	a_abs_x	w0
	store_b	A_REG,x0
	b	emulate

ins_ldy_imm:			// A0
	v_imm	Y_REG
	z_flag	Y_REG,#0xFF
	n_flag	Y_REG,#0x80
	b	emulate

ins_lda_ind_x:			// B1
	v_ind_x	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	b	emulate

ins_ldx_imm:			// A2
	v_imm	X_REG
	z_flag	X_REG,#0xFF
	n_flag	X_REG,#0x80
	b	emulate

ins_ldy_zp:			// A4
	v_zp	Y_REG
	z_flag	Y_REG,#0xFF
	n_flag	Y_REG,#0x80
	b	emulate

ins_lda_zp:			// A5
	v_zp	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	b	emulate

ins_ldx_zp:			// A6
	v_zp	X_REG
	z_flag	X_REG,#0xFF
	n_flag	X_REG,#0x80
	b	emulate

ins_tay:			// A8
	mov	Y_REG,A_REG
	z_flag	Y_REG,#0xFF
	n_flag	Y_REG,#0x80
	b	emulate

ins_lda_imm:			// A9
	v_imm	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	b	emulate

ins_tax:			// AA
	mov	X_REG,A_REG
	z_flag	X_REG,#0xFF
	n_flag	X_REG,#0x80
	b	emulate

ins_ldy_abs:			// AC
	v_abs	Y_REG
	z_flag	Y_REG,#0xFF
	n_flag	Y_REG,#0x80
	b	emulate

ins_lda_abs:			// AD
	v_abs	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	b	emulate

ins_ldx_abs:			// AE
	v_abs	X_REG
	z_flag	X_REG,#0xFF
	n_flag	X_REG,#0x80
	b	emulate

ins_bcs:			// B0
	a_rel	w0
	tst	S_REG,C_FLAG
	b.eq	emulate
	mov	PC_REG,w0
	b	emulate

ins_lda_ind_y:			// B1
	v_ind_y	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	b	emulate

ins_ldy_zp_x:			// B4
	v_zp_x	Y_REG
	z_flag	Y_REG,#0xFF
	n_flag	Y_REG,#0x80
	b	emulate

ins_lda_zp_x:			// B5
	v_zp_x	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	b	emulate

ins_clv:			// B8
	and	S_REG,S_REG,~V_FLAG
	b	emulate

ins_lda_abs_y:			// B9
	v_abs_y	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	b	emulate

ins_tsx:			// BA
	mov	X_REG,SP_REG
	and	X_REG,X_REG,#0xFF
	z_flag	X_REG,#0xFF
	n_flag	X_REG,#0x80
	b	emulate

ins_ldy_abs_x:			// BC
	v_abs_x	Y_REG
	z_flag	Y_REG,#0xFF
	n_flag	Y_REG,#0x80
	b	emulate

ins_lda_abs_x:			// BD
	v_abs_x	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	b	emulate

ins_ldx_abs_y:			// BE
	v_abs_y	X_REG
	z_flag	X_REG,#0xFF
	n_flag	X_REG,#0x80
	b	emulate

ins_cpy_imm:			// C0
	v_imm	w0
	compare	Y_REG,w0
	b	emulate

ins_cmp_ind_x:			// C1
	v_ind_x	w0
	compare	A_REG,w0
	b	emulate

ins_cpy_zp:			// C4
	v_zp	w0
	compare	Y_REG,w0
	b	emulate

ins_cmp_zp:			// C5
	v_zp	w0
	compare	A_REG,w0
	b	emulate

ins_dec_zp:			// C6
	a_zp	w0
	fetch_b	w1,x0
	op_dec	w1
	store_b	w1,x0
	b	emulate

ins_iny:			// C8
	op_inc	Y_REG
	b	emulate

ins_cmp_imm:			// C9
	v_imm	w0
	compare	A_REG,w0
	b	emulate

ins_dex:			// CA
	op_dec	X_REG
	b	emulate

ins_cpy_abs:			// CC
	v_abs	w0
	compare	Y_REG,w0
	b	emulate

ins_cmp_abs:			// CD
	v_abs	w0
	compare	A_REG,w0
	b	emulate

ins_dec_abs:			// CE
	a_abs	w0
	fetch_b	w1,x0
	op_dec	w1
	store_b	w1,x0
	b	emulate

ins_bne:			// D0
	a_rel	w0
	tst	S_REG,Z_FLAG
	b.ne	emulate
	mov	PC_REG,w0
	b	emulate

ins_cmp_ind_y:			// D1
	v_ind_y	w0
	compare	A_REG,w0
	b	emulate

ins_ign_zp_x:			// D4 - undocumented
	v_zp_x	w0
	b	emulate

ins_cmp_zp_x:			// D5
	v_zp_x	w0
	compare	A_REG,w0
	b	emulate

ins_dec_zp_x:			// D6
	a_zp_x	w0
	fetch_b	w1,x0
	op_dec	w1
	store_b	w1,x0
	b	emulate

ins_cld:			// D8
	and	S_REG,S_REG,~D_FLAG
	b	emulate

ins_cmp_abs_y:			// D9
	v_abs_y	w0
	compare	A_REG,w0
	b	emulate

ins_cmp_abs_x:			// DD
	v_abs_x	w0
	compare	A_REG,w0
	b	emulate

ins_dec_abs_x:			// DE
	a_abs_x	w0
	fetch_b	w1,x0
	op_dec	w1
	store_b	w1,x0
	b	emulate

ins_dcp_abs_x:			// DF - undocumented
	a_abs_x	w0
	fetch_b	w1,x0
	op_dec	w1
	compare	A_REG,w1
	store_b	w1,x0
	b	emulate

ins_cpx_imm:			// E0
	v_imm	w0
	compare	X_REG,w0
	b	emulate

ins_cpx_zp:			// E4
	v_zp	w0
	compare	X_REG,w0
	b	emulate

ins_sbc_zp:			// E5
	v_zp	w0
	sub_a	w0
	b	emulate

ins_inc_zp:			// E6
	a_zp	w0
	fetch_b	w1,x0
	op_inc	w1
	store_b	w1,x0
	b	emulate

ins_inx:			// E8
	op_inc	X_REG
	b	emulate

ins_sbc_imm:			// E9
	v_imm	w0
	sub_a	w0
	b	emulate

ins_nop:			// EA
	b	emulate

ins_cpx_abs:			// EC
	v_abs	w0
	compare	X_REG,w0
	b	emulate

ins_sbc_abs:			// ED
	v_abs	w0
	sub_a	w0
	b	emulate

ins_inc_abs:			// EE
	a_abs	w0
	fetch_b	w1,x0
	op_inc	w1
	store_b	w1,x0
	b	emulate

ins_beq:			// F0
	a_rel	w0
	tst	S_REG,Z_FLAG
	b.eq	emulate
	mov	PC_REG,w0
	b	emulate

ins_sbc_ind_y:			// F1
	v_ind_y	w0
	sub_a	w0
	b	emulate

ins_sbc_zp_x:			// F5
	v_zp_x	w0
	sub_a	w0
	b	emulate

ins_inc_zp_x:			// F6
	a_zp_x	w0
	fetch_b	w1,x0
	op_inc	w1
	store_b	w1,x0
	b	emulate

ins_sbc_abs_y:			// F9
	v_abs_y	w0
	sub_a	w0
	b	emulate

ins_sbc_abs_x:			// FD
	v_abs_x	w0
	sub_a	w0
	b	emulate

ins_inc_abs_x:			// FE
	a_abs_x	w0
	fetch_b	w1,x0
	op_inc	w1
	store_b	w1,x0
	b	emulate

instr_table:
	.quad	ins_brk		// 00
	.quad	undefined	// 01
	.quad	undefined	// 02
	.quad	undefined	// 03
	.quad	undefined	// 04
	.quad	ins_ora_zp	// 05
	.quad	ins_asl_zp	// 06
	.quad	ins_slo_zp	// 07*
	.quad	ins_php		// 08
	.quad	ins_ora_imm	// 09
	.quad	ins_asl_a	// 0A
	.quad	undefined	// 0B
	.quad	undefined	// 0C
	.quad	ins_ora_abs	// 0D
	.quad	ins_asl_abs	// 0E
	.quad	undefined	// 0F
	.quad	ins_bpl		// 10
	.quad	ins_ora_ind_y	// 11
	.quad	undefined	// 12
	.quad	undefined	// 13
	.quad	undefined	// 14
	.quad	undefined	// 15
	.quad	ins_asl_zp_x	// 16
	.quad	undefined	// 17
	.quad	ins_clc		// 18
	.quad	ins_ora_abs_y	// 19
	.quad	undefined	// 1A
	.quad	undefined	// 1B
	.quad	undefined	// 1C
	.quad	ins_ora_abs_x	// 1D
	.quad	undefined	// 1E
	.quad	undefined	// 1F
	.quad	ins_jsr		// 20
	.quad	undefined	// 21
	.quad	undefined	// 22
	.quad	undefined	// 23
	.quad	ins_bit_zp	// 24
	.quad	ins_and_zp	// 25
	.quad	ins_rol_zp	// 26
	.quad	undefined	// 27
	.quad	ins_plp		// 28
	.quad	ins_and_imm	// 29
	.quad	ins_rol_a	// 2A
	.quad	undefined	// 2B
	.quad	ins_bit_abs	// 2C
	.quad	ins_and_abs	// 2D
	.quad	undefined	// 2E
	.quad	undefined	// 2F
	.quad	ins_bmi		// 30
	.quad	ins_and_ind_y	// 31
	.quad	undefined	// 32
	.quad	undefined	// 33
	.quad	undefined	// 34
	.quad	undefined	// 35
	.quad	undefined	// 36
	.quad	undefined	// 37
	.quad	ins_sec		// 38
	.quad	ins_and_abs_y	// 39
	.quad	undefined	// 3A
	.quad	undefined	// 3B
	.quad	undefined	// 3C
	.quad	undefined	// 3D
	.quad	ins_rol_abs_x	// 3E
	.quad	undefined	// 3F
	.quad	ins_rti		// 40
	.quad	ins_eor_ind_x	// 41
	.quad	undefined	// 42
	.quad	undefined	// 43
	.quad	ins_ign_zp	// 44*
	.quad	ins_eor_zp	// 45
	.quad	ins_lsr_zp	// 46
	.quad	ins_sre_zp	// 47*
	.quad	ins_pha		// 48
	.quad	ins_eor_imm	// 49
	.quad	ins_lsr_a	// 4A
	.quad	undefined	// 4B
	.quad	ins_jmp_abs	// 4C
	.quad	ins_eor_abs	// 4D
	.quad	ins_lsr_abs	// 4E
	.quad	ins_sre_abs	// 4F*
	.quad	ins_bvc		// 50
	.quad	ins_eor_ind_y	// 51
	.quad	undefined	// 52
	.quad	undefined	// 53
	.quad	undefined	// 54
	.quad	undefined	// 55
	.quad	ins_lsr_zp_x	// 56
	.quad	undefined	// 57
	.quad	ins_cli		// 58
	.quad	ins_eor_abs_y	// 59
	.quad	ins_nop		// 5A*
	.quad	undefined	// 5B
	.quad	undefined	// 5C
	.quad	ins_eor_abs_x	// 5D
	.quad	ins_lsr_abs_x	// 5E
	.quad	undefined	// 5F
	.quad	ins_rts		// 60
	.quad	undefined	// 61
	.quad	undefined	// 62
	.quad	undefined	// 63
	.quad	undefined	// 64
	.quad	ins_adc_zp	// 65
	.quad	ins_ror_zp	// 66
	.quad	undefined	// 67
	.quad	ins_pla		// 68
	.quad	ins_adc_imm	// 69
	.quad	ins_ror_a	// 6A
	.quad	undefined	// 6B
	.quad	ins_jmp_ind	// 6C
	.quad	ins_adc_abs	// 6D
	.quad	undefined	// 6E
	.quad	undefined	// 6F
	.quad	ins_bvs		// 70
	.quad	ins_adc_ind_y	// 71
	.quad	undefined	// 72
	.quad	undefined	// 73
	.quad	undefined	// 74
	.quad	undefined	// 75
	.quad	ins_ror_zp_x	// 76
	.quad	undefined	// 77
	.quad	ins_sei		// 78
	.quad	ins_adc_abs_y	// 79
	.quad	undefined	// 7A
	.quad	ins_rra_abs_y	// 7B*
	.quad	undefined	// 7C
	.quad	ins_adc_abs_x	// 7D
	.quad	ins_ror_abs_x	// 7E
	.quad	undefined	// 7F
	.quad	undefined	// 80
	.quad	ins_sta_ind_x	// 81
	.quad	undefined	// 82
	.quad	undefined	// 83
	.quad	ins_sty_zp	// 84
	.quad	ins_sta_zp	// 85
	.quad	ins_stx_zp	// 86
	.quad	undefined	// 87
	.quad	ins_dey		// 88
	.quad	undefined	// 89
	.quad	ins_txa		// 8A
	.quad	undefined	// 8B
	.quad	ins_sty_abs	// 8C
	.quad	ins_sta_abs	// 8D
	.quad	ins_stx_abs	// 8E
	.quad	undefined	// 8F
	.quad	ins_bcc		// 90
	.quad	ins_sta_ind_y	// 91
	.quad	undefined	// 92
	.quad	undefined	// 93
	.quad	ins_sty_zp_x	// 94
	.quad	ins_sta_zp_x	// 95
	.quad	undefined	// 96
	.quad	undefined	// 97
	.quad	ins_tya		// 98
	.quad	ins_sta_abs_y	// 99
	.quad	ins_txs		// 9A
	.quad	undefined	// 9B
	.quad	undefined	// 9C
	.quad	ins_sta_abs_x	// 9D
	.quad	undefined	// 9E
	.quad	undefined	// 9F
	.quad	ins_ldy_imm	// A0
	.quad	ins_lda_ind_x	// A1
	.quad	ins_ldx_imm	// A2
	.quad	undefined	// A3
	.quad	ins_ldy_zp	// A4
	.quad	ins_lda_zp	// A5
	.quad	ins_ldx_zp	// A6
	.quad	undefined	// A7
	.quad	ins_tay		// A8
	.quad	ins_lda_imm	// A9
	.quad	ins_tax		// AA
	.quad	undefined	// AB
	.quad	ins_ldy_abs	// AC
	.quad	ins_lda_abs	// AD
	.quad	ins_ldx_abs	// AE
	.quad	undefined	// AF
	.quad	ins_bcs		// B0
	.quad	ins_lda_ind_y	// B1
	.quad	undefined	// B2
	.quad	undefined	// B3
	.quad	ins_ldy_zp_x	// B4
	.quad	ins_lda_zp_x	// B5
	.quad	undefined	// B6
	.quad	undefined	// B7
	.quad	ins_clv		// B8
	.quad	ins_lda_abs_y	// B9
	.quad	ins_tsx		// BA
	.quad	undefined	// BB
	.quad	ins_ldy_abs_x	// BC
	.quad	ins_lda_abs_x	// BD
	.quad	ins_ldx_abs_y	// BE
	.quad	undefined	// BF
	.quad	ins_cpy_imm	// C0
	.quad	ins_cmp_ind_x	// C1
	.quad	undefined	// C2
	.quad	undefined	// C3
	.quad	ins_cpy_zp	// C4
	.quad	ins_cmp_zp	// C5
	.quad	ins_dec_zp	// C6
	.quad	undefined	// C7
	.quad	ins_iny		// C8
	.quad	ins_cmp_imm	// C9
	.quad	ins_dex		// CA
	.quad	undefined	// CB
	.quad	ins_cpy_abs	// CC
	.quad	ins_cmp_abs	// CD
	.quad	ins_dec_abs	// CE
	.quad	undefined	// CF
	.quad	ins_bne		// D0
	.quad	ins_cmp_ind_y	// D1
	.quad	undefined	// D2
	.quad	undefined	// D3
	.quad	ins_ign_zp_x	// D4*
	.quad	ins_cmp_zp_x	// D5
	.quad	ins_dec_zp_x	// D6
	.quad	undefined	// D7
	.quad	ins_cld		// D8
	.quad	ins_cmp_abs_y	// D9
	.quad	undefined	// DA
	.quad	undefined	// DB
	.quad	undefined	// DC
	.quad	ins_cmp_abs_x	// DD
	.quad	ins_dec_abs_x	// DE
	.quad	ins_dcp_abs_x	// DF*
	.quad	ins_cpx_imm	// E0
	.quad	undefined	// E1
	.quad	undefined	// E2
	.quad	undefined	// E3
	.quad	ins_cpx_zp	// E4
	.quad	ins_sbc_zp	// E5
	.quad	ins_inc_zp	// E6
	.quad	undefined	// E7
	.quad	ins_inx		// E8
	.quad	ins_sbc_imm	// E9
	.quad	ins_nop		// EA
	.quad	undefined	// EB
	.quad	ins_cpx_abs	// EC
	.quad	ins_sbc_abs	// ED
	.quad	ins_inc_abs	// EE
	.quad	undefined	// EF
	.quad	ins_beq		// F0
	.quad	ins_sbc_ind_y	// F1
	.quad	undefined	// F2
	.quad	undefined	// F3
	.quad	undefined	// F4
	.quad	ins_sbc_zp_x	// F5
	.quad	ins_inc_zp_x	// F6
	.quad	undefined	// F7
	.quad	undefined	// F8
	.quad	ins_sbc_abs_y	// F9
	.quad	undefined	// FA
	.quad	undefined	// FB
	.quad	undefined	// FC
	.quad	ins_sbc_abs_x	// FD
	.quad	ins_inc_abs_x	// FE
	.quad	undefined	// FF
