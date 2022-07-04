// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021-2022
// Released under GPLv2 license
//
// 6502 processor instructions

.global instr_table

.include "defs.s"
.include "macros.s"

ins_brk:			// 00
	add	PC_REG,PC_REG,#1
	push_h	PC_REG
	orr	w0,S_REG,#(B_FLAG | X_FLAG)
	push_b	w0
	mov	w9,#0xFFFA
	fetch_h	PC_REG,w9
	b	emulate

ins_ora_ind_x:			// 01
	v_ind_x	w0
	or_a	w0
	b	emulate

ins_kil:			// 02 - unofficial
	ldrb	w0,[KEYBOARD,#KBD_RESET]
	tst	w0,#0xFF
	b.eq	ins_kil
	b	emulate

ins_slo_ind_x:			// 03 - unofficial
	a_ind_x	w9
	fetch_b	w0,w9
	op_asl	w0
	or_a	w0
	store_b	w0,w9
	b	emulate

ins_ign_zp:			// 04 - unofficial
	v_zp	w0
	b	emulate

ins_ora_zp:			// 05
	v_zp	w0
	or_a	w0
	b	emulate

ins_asl_zp:			// 06
	a_zp	w9
	fe_zp_b	w0,w9
	op_asl	w0
	st_zp_b	w0,w9
	b	emulate

ins_slo_zp:			// 07 - unofficial
	a_zp	w9
	fe_zp_b	w0,w9
	op_asl	w0
	or_a	w0
	st_zp_b	w0,w9
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

ins_anc_imm:			// 0B - unofficial
	v_imm	w0
	and_a	w0
	c_flag	S_REG,#N_FLAG
	b	emulate

ins_ign_abs:			// 0C - unofficial
	v_abs	w0
	b	emulate

ins_ora_abs:			// 0D
	v_abs	w0
	or_a	w0
	b	emulate

ins_asl_abs:			// 0E
	a_abs	w9
	fetch_b	w0,w9
	op_asl	w0
	store_b	w0,w9
	b	emulate

ins_slo_abs:			// 0F - unofficial
	a_abs	w9
	fetch_b	w0,w9
	op_asl	w0
	or_a	w0
	store_b	w0,w9
	b	emulate

ins_bpl:			// 10
	a_rel	w9
	tst	S_REG,N_FLAG
	b.ne	emulate
	mov	PC_REG,w9
	b	emulate

ins_ora_ind_y:			// 11
	v_ind_y	w0
	or_a	w0
	b	emulate

ins_slo_ind_y:			// 13 - unofficial
	a_ind_y	w9
	fetch_b	w0,w9
	op_asl	w0
	or_a	w0
	store_b	w0,w9
	b	emulate

ins_ign_zp_x:			// 14 - unofficial
	v_zp_x	w0
	b	emulate

ins_ora_zp_x:			// 15
	v_zp_x	w0
	or_a	w0
	b	emulate

ins_asl_zp_x:			// 16
	a_zp_x	w9
	fe_zp_b	w0,w9
	op_asl	w0
	st_zp_b	w0,w9
	b	emulate

ins_slo_zp_x:			// 17 - unofficial
	a_zp_x	w9
	fe_zp_b	w0,w9
	op_asl	w0
	or_a	w0
	st_zp_b	w0,w9
	b	emulate

ins_clc:			// 18
	and	S_REG,S_REG,~C_FLAG
	b	emulate

ins_ora_abs_y:			// 19
	v_abs_y	w0
	or_a	w0
	b	emulate

ins_slo_abs_y:			// 1B - unofficial
	a_abs_y	w9
	fetch_b	w0,w9
	op_asl	w0
	or_a	w0
	store_b	w0,w9
	b	emulate

ins_ign_abs_x:			// 1C - unofficial
	v_abs_x	w0
	b	emulate

ins_ora_abs_x:			// 1D
	v_abs_x	w0
	or_a	w0
	b	emulate

ins_asl_abs_x:			// 1E
	a_abs_x	w9
	fetch_b	w0,w9
	op_asl	w0
	store_b	w0,w9
	b	emulate

ins_slo_abs_x:			// 1F - unofficial
	a_abs_x	w9
	fetch_b	w0,w9
	op_asl	w0
	or_a	w0
	store_b	w0,w9
	b	emulate

ins_jsr:			// 20
	a_abs	w9
	sub	PC_REG,PC_REG,#1
	push_h	PC_REG
	mov	PC_REG,w9
	b	emulate

ins_and_ind_x:			// 21
	v_ind_x	w0
	and_a	w0
	b	emulate

ins_rla_ind_x:			// 23 - unofficial
	a_ind_x	w9
	fetch_b	w0,w9
	op_rol	w0
	and_a	w0
	store_b	w0,w9
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
	a_zp	w9
	fe_zp_b	w0,w9
	op_rol	w0
	st_zp_b	w0,w9
	b	emulate

ins_rla_zp:			// 27 - unofficial
	a_zp	w9
	fe_zp_b	w0,w9
	op_rol	w0
	and_a	w0
	st_zp_b	w0,w9
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

ins_rol_abs:			// 2E
	a_abs	w9
	fetch_b	w0,w9
	op_rol	w0
	store_b	w0,w9
	b	emulate

ins_rla_abs:			// 2F - unofficial
	a_abs	w9
	fetch_b	w0,w9
	op_rol	w0
	and_a	w0
	store_b	w0,w9
	b	emulate

ins_bmi:			// 30
	a_rel	w9
	tst	S_REG,N_FLAG
	b.eq	emulate
	mov	PC_REG,w9
	b	emulate

ins_and_ind_y:			// 31
	v_ind_y	w0
	and_a	w0
	b	emulate

ins_rla_ind_y:			// 33 - unofficial
	a_ind_y	w9
	fetch_b	w0,w9
	op_rol	w0
	and_a	w0
	store_b	w0,w9
	b	emulate

ins_and_zp_x:			// 35
	v_zp_x	w0
	and_a	w0
	b	emulate

ins_rol_zp_x:			// 36
	a_zp_x	w9
	fe_zp_b	w0,w9
	op_rol	w0
	st_zp_b	w0,w9
	b	emulate

ins_rla_zp_x:			// 37 - unofficial
	a_zp_x	w9
	fe_zp_b	w0,w9
	op_rol	w0
	and_a	w0
	st_zp_b	w0,w9
	b	emulate

ins_sec:			// 38
	orr	S_REG,S_REG,C_FLAG
	b	emulate

ins_and_abs_y:			// 39
	v_abs_y	w0
	and_a	w0
	b	emulate

ins_rla_abs_y:			// 3B - unofficial
	a_abs_y	w9
	fetch_b	w0,w9
	op_rol	w0
	and_a	w0
	store_b	w0,w9
	b	emulate

ins_and_abs_x:			// 3D
	v_abs_x	w0
	and_a	w0
	b	emulate

ins_rol_abs_x:			// 3E
	a_abs_x	w9
	fetch_b	w0,w9
	op_rol	w0
	store_b	w0,w9
	b	emulate

ins_rla_abs_x:			// 3F - unofficial
	a_abs_x	w9
	fetch_b	w0,w9
	op_rol	w0
	and_a	w0
	store_b	w0,w9
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

ins_sre_ind_x:			// 43 - unofficial
	a_ind_x	w9
	fetch_b	w0,w9
	op_lsr	w0
	eor_a	w0
	store_b	w0,w9
	b	emulate

ins_eor_zp:			// 45
	v_zp	w0
	eor_a	w0
	b	emulate

ins_lsr_zp:			// 46
	a_zp	w9
	fe_zp_b	w0,w9
	op_lsr	w0
	st_zp_b	w0,w9
	b	emulate

ins_sre_zp:			// 47 - unofficial
	a_zp	w9
	fe_zp_b	w0,w9
	op_lsr	w0
	eor_a	w0
	st_zp_b	w0,w9
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

ins_alr_imm:			// 4B - unofficial
	v_imm	w0
	and_a	w0
	op_lsr	A_REG
	b	emulate

ins_jmp_abs:			// 4C
	fetch_h	PC_REG,PC_REG
	b	emulate

ins_eor_abs:			// 4D
	v_abs	w0
	eor_a	w0
	b	emulate

ins_lsr_abs:			// 4E
	a_abs	w9
	fetch_b	w0,w9
	op_lsr	w0
	store_b	w0,w9
	b	emulate

ins_sre_abs:			// 4F - unofficial
	a_abs	w9
	fetch_b	w0,w9
	op_lsr	w0
	eor_a	w0
	store_b	w0,w9
	b	emulate

ins_bvc:			// 50
	a_rel	w9
	tst	S_REG,V_FLAG
	b.ne	emulate
	mov	PC_REG,w9
	b	emulate

ins_eor_ind_y:			// 51
	v_ind_y	w0
	eor_a	w0
	b	emulate

ins_sre_ind_y:			// 53 - unofficial
	a_ind_y	w9
	fetch_b	w0,w9
	op_lsr	w0
	eor_a	w0
	store_b	w0,w9
	b	emulate

ins_eor_zp_x:			// 55
	v_zp_x	w0
	eor_a	w0
	b	emulate

ins_lsr_zp_x:			// 56
	a_zp_x	w9
	fe_zp_b	w0,w9
	op_lsr	w0
	st_zp_b	w0,w9
	b	emulate

ins_sre_zp_x:			// 57 - unofficial
	a_zp_x	w9
	fe_zp_b	w0,w9
	op_lsr	w0
	eor_a	w0
	st_zp_b	w0,w9
	b	emulate

ins_cli:			// 58
	and	S_REG,S_REG,#~I_FLAG
	b	emulate

ins_eor_abs_y:			// 59
	v_abs_y	w0
	eor_a	w0
	b	emulate

ins_sre_abs_y:			// 5B - unofficial
	a_abs_y	w9
	fetch_b	w0,w9
	op_lsr	w0
	eor_a	w0
	store_b	w0,w9
	b	emulate

ins_eor_abs_x:			// 5D
	v_abs_x	w0
	eor_a	w0
	b	emulate

ins_lsr_abs_x:			// 5E
	a_abs_x	w9
	fetch_b	w0,w9
	op_lsr	w0
	store_b	w0,w9
	b	emulate

ins_sre_abs_x:			// 5F - unofficial
	a_abs_x	w9
	fetch_b	w0,w9
	op_lsr	w0
	eor_a	w0
	store_b	w0,w9
	b	emulate

ins_rts:			// 60
	pop_h	PC_REG
	add	PC_REG,PC_REG,#1
	b	emulate

ins_adc_ind_x:			// 61
	v_ind_x	w0
	add_a	w0
	b	emulate

ins_rra_ind_x:			// 63 - unofficial
	a_ind_x	w9
	fetch_b	w0,w9
	op_ror	w0
	add_a	w0
	store_b	w0,w9
	b	emulate

ins_adc_zp:			// 65
	v_zp	w0
	add_a	w0
	b	emulate

ins_ror_zp:			// 66
	a_zp	w9
	fe_zp_b	w0,w9
	op_ror	w0
	st_zp_b	w0,w9
	b	emulate

ins_rra_zp:			// 67 - unofficial
	a_zp	w9
	fe_zp_b	w0,w9
	op_ror	w0
	add_a	w0
	st_zp_b	w0,w9
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

ins_arr_imm:			// 6B - unofficial
	v_imm	w0
	and_a	w0
	and	w4,A_REG,#0x80
	and	w5,A_REG,#0x40
	lsl	w5,w5,#1
	eor	w5,w5,w4
	op_ror	A_REG
	c_flag	w4,#0x80
	v_flag	w5,#0x80
	b	emulate

ins_jmp_ind:			// 6C
	fetch_h	w9,PC_REG
	fetch_h	PC_REG,w9
	b	emulate

ins_adc_abs:			// 6D
	v_abs	w0
	add_a	w0
	b	emulate

ins_ror_abs:			// 6E
	a_abs	w9
	fetch_b	w0,w9
	op_ror	w0
	store_b	w0,w9
	b	emulate

ins_rra_abs:			// 6F - unofficial
	a_abs	w9
	fetch_b	w0,w9
	op_ror	w0
	add_a	w0
	store_b	w0,w9
	b	emulate

ins_bvs:			// 70
	a_rel	w9
	tst	S_REG,V_FLAG
	b.eq	emulate
	mov	PC_REG,w9
	b	emulate

ins_adc_ind_y:			// 71
	v_ind_y	w0
	add_a	w0
	b	emulate

ins_rra_ind_y:			// 73 - unofficial
	a_ind_y	w9
	fetch_b	w0,w9
	op_ror	w0
	add_a	w0
	store_b	w0,w9
	b	emulate

ins_adc_zp_x:			// 75
	v_zp_x	w0
	add_a	w0
	b	emulate

ins_ror_zp_x:			// 76
	a_zp_x	w9
	fe_zp_b	w0,w9
	op_ror	w0
	st_zp_b	w0,w9
	b	emulate

ins_rra_zp_x:			// 77 - unofficial
	a_zp_x	w9
	fe_zp_b	w0,w9
	op_ror	w0
	add_a	w0
	st_zp_b	w0,w9
	b	emulate

ins_sei:			// 78
	orr	S_REG,S_REG,#I_FLAG
	b	emulate

ins_adc_abs_y:			// 79
	v_abs_y	w0
	add_a	w0
	b	emulate

ins_rra_abs_y:			// 7B - unofficial
	a_abs_y	w9
	fetch_b	w0,w9
	op_ror	w0
	add_a	w0
	store_b	w0,w9
	b	emulate

ins_adc_abs_x:			// 7D
	v_abs_x	w0
	add_a	w0
	b	emulate

ins_ror_abs_x:			// 7E
	a_abs_x	w9
	fetch_b	w0,w9
	op_ror	w0
	store_b	w0,w9
	b	emulate

ins_rra_abs_x:			// 7F - unofficial
	a_abs_x	w9
	fetch_b	w0,w9
	op_ror	w0
	add_a	w0
	store_b	w0,w9
	b	emulate

ins_skb_imm:			// 80 - unofficial
	v_imm	w0
	b	emulate

ins_sta_ind_x:			// 81
	a_ind_x	w9
	store_b	A_REG,w9
	b	emulate

ins_sax_ind_x:			// 83 - unofficial
	a_ind_x	w9
	and	w0,A_REG,X_REG
	store_b	w0,w9
	b	emulate

ins_sty_zp:			// 84
	a_zp	w9
	st_zp_b	Y_REG,w9
	b	emulate

ins_sta_zp:			// 85
	a_zp	w9
	st_zp_b	A_REG,w9
	b	emulate

ins_stx_zp:			// 86
	a_zp	w9
	st_zp_b	X_REG,w9
	b	emulate

ins_sax_zp:			// 87 - unofficial
	a_zp	w9
	and	w0,A_REG,X_REG
	st_zp_b	w0,w9
	b	emulate

ins_dey:			// 88
	op_dec	Y_REG
	b	emulate

ins_txa:			// 8A
	mov	A_REG,X_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	b	emulate

ins_xaa_imm:			// 8B - unofficial
	v_imm	w0
	and	A_REG,X_REG,w0
	b	emulate

ins_sty_abs:			// 8C
	a_abs	w9
	store_b	Y_REG,w9
	b	emulate

ins_sta_abs:			// 8D
	a_abs	w9
	store_b	A_REG,w9
	b	emulate

ins_stx_abs:			// 8E
	a_abs	w9
	store_b	X_REG,w9
	b	emulate

ins_sax_abs:			// 8F - unofficial
	a_abs	w9
	and	w0,A_REG,X_REG
	store_b	w0,w9
	b	emulate

ins_bcc:			// 90
	a_rel	w9
	tst	S_REG,C_FLAG
	b.ne	emulate
	mov	PC_REG,w9
	b	emulate

ins_sta_ind_y:			// 91
	a_ind_y	w9
	store_b	A_REG,w9
	b	emulate

ins_ahx_ind_y:			// 93 - unofficial
	a_ind_y	w9
	lsr	w0,w9,#8
	add	w0,w0,#1
	and	w0,w0,A_REG
	and	w0,w0,X_REG
	store_b	w0,w9
	b	emulate

ins_sty_zp_x:			// 94
	a_zp_x	w9
	st_zp_b	Y_REG,w9
	b	emulate

ins_sta_zp_x:			// 95
	a_zp_x	w9
	st_zp_b	A_REG,w9
	b	emulate

ins_stx_zp_y:			// 96
	a_zp_y	w9
	st_zp_b	X_REG,w9
	b	emulate

ins_sax_zp_y:			// 97 - unofficial
	a_zp_y	w9
	and	w0,A_REG,X_REG
	st_zp_b	w0,w9
	b	emulate

ins_tya:			// 98
	mov	A_REG,Y_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	b	emulate

ins_sta_abs_y:			// 99
	a_abs_y	w9
	store_b	A_REG,w9
	b	emulate

ins_txs:			// 9A
	orr	SP_REG,X_REG,#0x100
	b	emulate

ins_tas_abs_y:			// 9B - unofficial
	a_abs_y	w9
	lsr	w0,w9,#8
	add	w0,w0,#1
	and	w0,w0,A_REG
	and	w0,w0,X_REG
	store_b	w0,w9
	orr	SP_REG,w0,#0x100
	b	emulate

ins_shy_abs_x:			// 9C - unofficial
	a_abs_x	w9
	lsr	w0,w9,#8
	add	w0,w0,#1
	and	w0,w0,Y_REG
	store_b	w0,w9
	b	emulate

ins_sta_abs_x:			// 9D
	a_abs_x	w9
	store_b	A_REG,w9
	b	emulate

ins_shx_abs_y:			// 9E - unofficial
	a_abs_y	w9
	lsr	w0,w9,#8
	add	w0,w0,#1
	and	w0,w0,X_REG
	store_b	w0,w9
	b	emulate

ins_ahx_abs_y:			// 9F - unofficial
	a_abs_y	w9
	lsr	w0,w9,#8
	add	w0,w0,#1
	and	w0,w0,A_REG
	and	w0,w0,X_REG
	store_b	w0,w9
	b	emulate

ins_ldy_imm:			// A0
	v_imm	Y_REG
	z_flag	Y_REG,#0xFF
	n_flag	Y_REG,#0x80
	b	emulate

ins_lda_ind_x:			// A1
	v_ind_x	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	b	emulate

ins_lax_ind_x:			// A3 - unofficial
	v_ind_x	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	mov	X_REG,A_REG
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

ins_lax_zp:			// A7 - unofficial
	v_zp	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	mov	X_REG,A_REG
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

ins_lax_imm:			// AB - unofficial
	v_imm	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	mov	X_REG,A_REG
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

ins_lax_abs:			// AF - unofficial
	v_abs	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	mov	X_REG,A_REG
	b	emulate

ins_bcs:			// B0
	a_rel	w9
	tst	S_REG,C_FLAG
	b.eq	emulate
	mov	PC_REG,w9
	b	emulate

ins_lda_ind_y:			// B1
	v_ind_y	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	b	emulate

ins_lax_ind_y:			// B3 - unofficial
	v_ind_y	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	mov	X_REG,A_REG
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

ins_ldx_zp_y:			// B6
	v_zp_y	X_REG
	z_flag	X_REG,#0xFF
	n_flag	X_REG,#0x80
	b	emulate

ins_lax_zp_y:			// B7 - unofficial
	v_zp_y	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	mov	X_REG,A_REG
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

ins_las_abs_y:			// BB - unofficial
	v_abs_y	w0
	and	SP_REG,SP_REG,w0
	mov	X_REG,SP_REG
	mov	A_REG,SP_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
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

ins_lax_abs_y:			// BF - unofficial
	v_abs_y	A_REG
	z_flag	A_REG,#0xFF
	n_flag	A_REG,#0x80
	mov	X_REG,A_REG
	b	emulate

ins_cpy_imm:			// C0
	v_imm	w0
	compare	Y_REG,w0
	b	emulate

ins_cmp_ind_x:			// C1
	v_ind_x	w0
	compare	A_REG,w0
	b	emulate

ins_dcp_ind_x:			// C3 - unofficial
	a_ind_x	w9
	fetch_b	w0,w9
	op_dec	w0
	compare	A_REG,w0
	store_b	w0,w9
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
	a_zp	w9
	fe_zp_b	w0,w9
	op_dec	w0
	st_zp_b	w0,w9
	b	emulate

ins_dcp_zp:			// C7 - unofficial
	a_zp	w9
	fe_zp_b	w0,w9
	op_dec	w0
	compare	A_REG,w0
	st_zp_b	w0,w9
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

ins_axs_imm:			// CB - unofficial
	v_imm	w0
	and	X_REG,A_REG,X_REG
	sub	X_REG,X_REG,w0
	c_flag	X_REG,#0x100
	c_inv
	and	X_REG,X_REG,#0xFF
	z_flag	X_REG,#0xFF
	n_flag	X_REG,#0x80
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
	a_abs	w9
	fetch_b	w0,w9
	op_dec	w0
	store_b	w0,w9
	b	emulate

ins_dcp_abs:			// CF - unofficial
	a_abs	w9
	fetch_b	w0,w9
	op_dec	w0
	compare	A_REG,w0
	store_b	w0,w9
	b	emulate

ins_bne:			// D0
	a_rel	w9
	tst	S_REG,Z_FLAG
	b.ne	emulate
	mov	PC_REG,w9
	b	emulate

ins_cmp_ind_y:			// D1
	v_ind_y	w0
	compare	A_REG,w0
	b	emulate

ins_dcp_ind_y:			// D3 - unofficial
	a_ind_y	w9
	fetch_b	w0,w9
	op_dec	w0
	compare	A_REG,w0
	store_b	w0,w9
	b	emulate

ins_cmp_zp_x:			// D5
	v_zp_x	w0
	compare	A_REG,w0
	b	emulate

ins_dec_zp_x:			// D6
	a_zp_x	w9
	fe_zp_b	w0,w9
	op_dec	w0
	st_zp_b	w0,w9
	b	emulate

ins_dcp_zp_x:			// D7 - unofficial
	a_zp_x	w9
	fe_zp_b	w0,w9
	op_dec	w0
	compare	A_REG,w0
	st_zp_b	w0,w9
	b	emulate

ins_cld:			// D8
	and	S_REG,S_REG,~D_FLAG
	b	emulate

ins_cmp_abs_y:			// D9
	v_abs_y	w0
	compare	A_REG,w0
	b	emulate

ins_dcp_abs_y:			// DB - unofficial
	a_abs_y	w9
	fetch_b	w0,w9
	op_dec	w0
	compare	A_REG,w0
	store_b	w0,w9
	b	emulate

ins_cmp_abs_x:			// DD
	v_abs_x	w0
	compare	A_REG,w0
	b	emulate

ins_dec_abs_x:			// DE
	a_abs_x	w9
	fetch_b	w0,w9
	op_dec	w0
	store_b	w0,w9
	b	emulate

ins_dcp_abs_x:			// DF - unofficial
	a_abs_x	w9
	fetch_b	w0,w9
	op_dec	w0
	compare	A_REG,w0
	store_b	w0,w9
	b	emulate

ins_cpx_imm:			// E0
	v_imm	w0
	compare	X_REG,w0
	b	emulate

ins_sbc_ind_x:			// E1
	v_ind_x	w0
	sub_a	w0
	b	emulate

ins_isc_ind_x:			// E3 - unofficial
	a_ind_x	w9
	fetch_b	w0,w9
	op_inc	w0
	sub_a	w0
	store_b	w0,w9
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
	a_zp	w9
	fe_zp_b	w0,w9
	op_inc	w0
	st_zp_b	w0,w9
	b	emulate

ins_isc_zp:			// E7 - unofficial
	a_zp	w9
	fe_zp_b	w0,w9
	op_inc	w0
	sub_a	w0
	st_zp_b	w0,w9
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
	a_abs	w9
	fetch_b	w0,w9
	op_inc	w0
	store_b	w0,w9
	b	emulate

ins_isc_abs:			// EF - unofficial
	a_abs	w9
	fetch_b	w0,w9
	op_inc	w0
	sub_a	w0
	store_b	w0,w9
	b	emulate

ins_beq:			// F0
	a_rel	w9
	tst	S_REG,Z_FLAG
	b.eq	emulate
	mov	PC_REG,w9
	b	emulate

ins_sbc_ind_y:			// F1
	v_ind_y	w0
	sub_a	w0
	b	emulate

ins_isc_ind_y:			// F3 - unofficial
	a_ind_y	w9
	fetch_b	w0,w9
	op_inc	w0
	sub_a	w0
	store_b	w0,w9
	b	emulate

ins_sbc_zp_x:			// F5
	v_zp_x	w0
	sub_a	w0
	b	emulate

ins_inc_zp_x:			// F6
	a_zp_x	w9
	fe_zp_b	w0,w9
	op_inc	w0
	st_zp_b	w0,w9
	b	emulate

ins_isc_zp_x:			// F7 - unofficial
	a_zp_x	w9
	fe_zp_b	w0,w9
	op_inc	w0
	sub_a	w0
	st_zp_b	w0,w9
	b	emulate

ins_sed:			// F8
	orr	S_REG,S_REG,D_FLAG
	b	emulate

ins_sbc_abs_y:			// F9
	v_abs_y	w0
	sub_a	w0
	b	emulate

ins_isc_abs_y:			// FB - unofficial
	a_abs_y	w9
	fetch_b	w0,w9
	op_inc	w0
	sub_a	w0
	store_b	w0,w9
	b	emulate

ins_sbc_abs_x:			// FD
	v_abs_x	w0
	sub_a	w0
	b	emulate

ins_inc_abs_x:			// FE
	a_abs_x	w9
	fetch_b	w0,w9
	op_inc	w0
	store_b	w0,w9
	b	emulate

ins_isc_abs_x:			// FF - unofficial
	a_abs_x	w9
	fetch_b	w0,w9
	op_inc	w0
	sub_a	w0
	store_b	w0,w9
	b	emulate

instr_table:
	.quad	ins_brk		// 00
	.quad	ins_ora_ind_x	// 01
	.quad	ins_kil		// 02 - unofficial
	.quad	ins_slo_ind_x	// 03 - unofficial
	.quad	ins_ign_zp	// 04 - unofficial
	.quad	ins_ora_zp	// 05
	.quad	ins_asl_zp	// 06
	.quad	ins_slo_zp	// 07 - unofficial
	.quad	ins_php		// 08
	.quad	ins_ora_imm	// 09
	.quad	ins_asl_a	// 0A
	.quad	ins_anc_imm	// 0B - unofficial
	.quad	ins_ign_abs	// 0C - unofficial
	.quad	ins_ora_abs	// 0D
	.quad	ins_asl_abs	// 0E
	.quad	ins_slo_abs	// 0F - unofficial
	.quad	ins_bpl		// 10
	.quad	ins_ora_ind_y	// 11
	.quad	ins_kil		// 12 - unofficial
	.quad	ins_slo_ind_y	// 13 - unofficial
	.quad	ins_ign_zp_x	// 14 - unofficial
	.quad	ins_ora_zp_x	// 15
	.quad	ins_asl_zp_x	// 16
	.quad	ins_slo_zp_x	// 17 - unofficial
	.quad	ins_clc		// 18
	.quad	ins_ora_abs_y	// 19
	.quad	ins_nop		// 1A - unofficial
	.quad	ins_slo_abs_y	// 1B - unofficial
	.quad	ins_ign_abs_x	// 1C - unofficial
	.quad	ins_ora_abs_x	// 1D
	.quad	ins_asl_abs_x	// 1E
	.quad	ins_slo_abs_x	// 1F - unofficial
	.quad	ins_jsr		// 20
	.quad	ins_and_ind_x	// 21
	.quad	ins_kil		// 22 - unofficial
	.quad	ins_rla_ind_x	// 23 - unofficial
	.quad	ins_bit_zp	// 24
	.quad	ins_and_zp	// 25
	.quad	ins_rol_zp	// 26
	.quad	ins_rla_zp	// 27 - unofficial
	.quad	ins_plp		// 28
	.quad	ins_and_imm	// 29
	.quad	ins_rol_a	// 2A
	.quad	ins_anc_imm	// 2B - unofficial
	.quad	ins_bit_abs	// 2C
	.quad	ins_and_abs	// 2D
	.quad	ins_rol_abs	// 2E
	.quad	ins_rla_abs	// 2F - unofficial
	.quad	ins_bmi		// 30
	.quad	ins_and_ind_y	// 31
	.quad	ins_kil		// 32 - unofficial
	.quad	ins_rla_ind_y	// 33 - unofficial
	.quad	ins_ign_zp_x	// 34 - unofficial
	.quad	ins_and_zp_x	// 35
	.quad	ins_rol_zp_x	// 36
	.quad	ins_rla_zp_x	// 37 - unofficial
	.quad	ins_sec		// 38
	.quad	ins_and_abs_y	// 39
	.quad	ins_nop		// 3A - unofficial
	.quad	ins_rla_abs_y	// 3B - unofficial
	.quad	ins_ign_abs_x	// 3C - unofficial
	.quad	ins_and_abs_x	// 3D
	.quad	ins_rol_abs_x	// 3E
	.quad	ins_rla_abs_x	// 3F - unofficial
	.quad	ins_rti		// 40
	.quad	ins_eor_ind_x	// 41
	.quad	ins_kil		// 42 - unofficial
	.quad	ins_sre_ind_x	// 43 - unofficial
	.quad	ins_ign_zp	// 44 - unofficial
	.quad	ins_eor_zp	// 45
	.quad	ins_lsr_zp	// 46
	.quad	ins_sre_zp	// 47 - unofficial
	.quad	ins_pha		// 48
	.quad	ins_eor_imm	// 49
	.quad	ins_lsr_a	// 4A
	.quad	ins_alr_imm	// 4B - unofficial
	.quad	ins_jmp_abs	// 4C
	.quad	ins_eor_abs	// 4D
	.quad	ins_lsr_abs	// 4E
	.quad	ins_sre_abs	// 4F - unofficial
	.quad	ins_bvc		// 50
	.quad	ins_eor_ind_y	// 51
	.quad	ins_kil		// 52 - unofficial
	.quad	ins_sre_ind_y	// 53 - unofficial
	.quad	ins_ign_zp_x	// 54 - unofficial
	.quad	ins_eor_zp_x	// 55
	.quad	ins_lsr_zp_x	// 56
	.quad	ins_sre_zp_x	// 57 - unofficial
	.quad	ins_cli		// 58
	.quad	ins_eor_abs_y	// 59
	.quad	ins_nop		// 5A - unofficial
	.quad	ins_sre_abs_y	// 5B - unofficial
	.quad	ins_ign_abs_x	// 5C - unofficial
	.quad	ins_eor_abs_x	// 5D
	.quad	ins_lsr_abs_x	// 5E
	.quad	ins_sre_abs_x	// 5F - unofficial
	.quad	ins_rts		// 60
	.quad	ins_adc_ind_x	// 61
	.quad	ins_kil		// 62 - unofficial
	.quad	ins_rra_ind_x	// 63 - unofficial
	.quad	ins_ign_zp	// 64 - unofficial
	.quad	ins_adc_zp	// 65
	.quad	ins_ror_zp	// 66
	.quad	ins_rra_zp	// 67 - unofficial
	.quad	ins_pla		// 68
	.quad	ins_adc_imm	// 69
	.quad	ins_ror_a	// 6A
	.quad	ins_arr_imm	// 6B - unofficial
	.quad	ins_jmp_ind	// 6C
	.quad	ins_adc_abs	// 6D
	.quad	ins_ror_abs	// 6E
	.quad	ins_rra_abs	// 6F - unofficial
	.quad	ins_bvs		// 70
	.quad	ins_adc_ind_y	// 71
	.quad	ins_kil		// 72 - unofficial
	.quad	ins_rra_ind_y	// 73 - unofficial
	.quad	ins_ign_zp_x	// 74 - unofficial
	.quad	ins_adc_zp_x	// 75
	.quad	ins_ror_zp_x	// 76
	.quad	ins_rra_zp_x	// 77 - unofficial
	.quad	ins_sei		// 78
	.quad	ins_adc_abs_y	// 79
	.quad	ins_nop		// 7A - unofficial
	.quad	ins_rra_abs_y	// 7B - unofficial
	.quad	ins_ign_abs_x	// 7C - unofficial
	.quad	ins_adc_abs_x	// 7D
	.quad	ins_ror_abs_x	// 7E
	.quad	ins_rra_abs_x	// 7F - unofficial
	.quad	ins_skb_imm	// 80 - unofficial
	.quad	ins_sta_ind_x	// 81
	.quad	ins_skb_imm	// 82 - unofficial
	.quad	ins_sax_ind_x	// 83 - unofficial
	.quad	ins_sty_zp	// 84
	.quad	ins_sta_zp	// 85
	.quad	ins_stx_zp	// 86
	.quad	ins_sax_zp	// 87 - unofficial
	.quad	ins_dey		// 88
	.quad	ins_skb_imm	// 89 - unofficial
	.quad	ins_txa		// 8A
	.quad	ins_xaa_imm	// 8B - unofficial
	.quad	ins_sty_abs	// 8C
	.quad	ins_sta_abs	// 8D
	.quad	ins_stx_abs	// 8E
	.quad	ins_sax_abs	// 8F - unofficial
	.quad	ins_bcc		// 90
	.quad	ins_sta_ind_y	// 91
	.quad	ins_kil		// 92 - unofficial
	.quad	ins_ahx_ind_y	// 93 - unofficial
	.quad	ins_sty_zp_x	// 94
	.quad	ins_sta_zp_x	// 95
	.quad	ins_stx_zp_y	// 96
	.quad	ins_sax_zp_y	// 97 - unofficial
	.quad	ins_tya		// 98
	.quad	ins_sta_abs_y	// 99
	.quad	ins_txs		// 9A
	.quad	ins_tas_abs_y	// 9B - unofficial
	.quad	ins_shy_abs_x	// 9C - unofficial
	.quad	ins_sta_abs_x	// 9D
	.quad	ins_shx_abs_y	// 9E - unofficial
	.quad	ins_ahx_abs_y	// 9F - unofficial
	.quad	ins_ldy_imm	// A0
	.quad	ins_lda_ind_x	// A1
	.quad	ins_ldx_imm	// A2
	.quad	ins_lax_ind_x	// A3 - unofficial
	.quad	ins_ldy_zp	// A4
	.quad	ins_lda_zp	// A5
	.quad	ins_ldx_zp	// A6
	.quad	ins_lax_zp	// A7 - unofficial
	.quad	ins_tay		// A8
	.quad	ins_lda_imm	// A9
	.quad	ins_tax		// AA
	.quad	ins_lax_imm	// AB - unofficial
	.quad	ins_ldy_abs	// AC
	.quad	ins_lda_abs	// AD
	.quad	ins_ldx_abs	// AE
	.quad	ins_lax_abs	// AF - unofficial
	.quad	ins_bcs		// B0
	.quad	ins_lda_ind_y	// B1
	.quad	ins_kil		// B2 - unofficial
	.quad	ins_lax_ind_y	// B3 - unofficial
	.quad	ins_ldy_zp_x	// B4
	.quad	ins_lda_zp_x	// B5
	.quad	ins_ldx_zp_y	// B6
	.quad	ins_lax_zp_y	// B7 - unofficial
	.quad	ins_clv		// B8
	.quad	ins_lda_abs_y	// B9
	.quad	ins_tsx		// BA
	.quad	ins_las_abs_y	// BB - unofficial
	.quad	ins_ldy_abs_x	// BC
	.quad	ins_lda_abs_x	// BD
	.quad	ins_ldx_abs_y	// BE
	.quad	ins_lax_abs_y	// BF - unofficial
	.quad	ins_cpy_imm	// C0
	.quad	ins_cmp_ind_x	// C1
	.quad	ins_skb_imm	// C2 - unofficial
	.quad	ins_dcp_ind_x	// C3 - unofficial
	.quad	ins_cpy_zp	// C4
	.quad	ins_cmp_zp	// C5
	.quad	ins_dec_zp	// C6
	.quad	ins_dcp_zp	// C7 - unofficial
	.quad	ins_iny		// C8
	.quad	ins_cmp_imm	// C9
	.quad	ins_dex		// CA
	.quad	ins_axs_imm	// CB - unofficial
	.quad	ins_cpy_abs	// CC
	.quad	ins_cmp_abs	// CD
	.quad	ins_dec_abs	// CE
	.quad	ins_dcp_abs	// CF - unofficial
	.quad	ins_bne		// D0
	.quad	ins_cmp_ind_y	// D1
	.quad	ins_kil		// D2 - unofficial
	.quad	ins_dcp_ind_y	// D3 - unofficial
	.quad	ins_ign_zp_x	// D4 - unofficial
	.quad	ins_cmp_zp_x	// D5
	.quad	ins_dec_zp_x	// D6
	.quad	ins_dcp_zp_x	// D7 - unofficial
	.quad	ins_cld		// D8
	.quad	ins_cmp_abs_y	// D9
	.quad	ins_nop		// DA - unofficial
	.quad	ins_dcp_abs_y	// DB - unofficial
	.quad	ins_ign_abs_x	// DC - unofficial
	.quad	ins_cmp_abs_x	// DD
	.quad	ins_dec_abs_x	// DE
	.quad	ins_dcp_abs_x	// DF - unofficial
	.quad	ins_cpx_imm	// E0
	.quad	ins_sbc_ind_x	// E1
	.quad	ins_skb_imm	// E2 - unofficial
	.quad	ins_isc_ind_x	// E3 - unofficial
	.quad	ins_cpx_zp	// E4
	.quad	ins_sbc_zp	// E5
	.quad	ins_inc_zp	// E6
	.quad	ins_isc_zp	// E7 - unofficial
	.quad	ins_inx		// E8
	.quad	ins_sbc_imm	// E9
	.quad	ins_nop		// EA
	.quad	ins_sbc_imm	// EB - unofficial
	.quad	ins_cpx_abs	// EC
	.quad	ins_sbc_abs	// ED
	.quad	ins_inc_abs	// EE
	.quad	ins_isc_abs	// EF - unofficial
	.quad	ins_beq		// F0
	.quad	ins_sbc_ind_y	// F1
	.quad	ins_kil		// F2 - unofficial
	.quad	ins_isc_ind_y	// F3 - unofficial
	.quad	ins_ign_zp_x	// F4 - unofficial
	.quad	ins_sbc_zp_x	// F5
	.quad	ins_inc_zp_x	// F6
	.quad	ins_isc_zp_x	// F7 - unofficial
	.quad	ins_sed		// F8
	.quad	ins_sbc_abs_y	// F9
	.quad	ins_nop		// FA - unofficial
	.quad	ins_isc_abs_y	// FB - unofficial
	.quad	ins_ign_abs_x	// FC - unofficial
	.quad	ins_sbc_abs_x	// FD
	.quad	ins_inc_abs_x	// FE
	.quad	ins_isc_abs_x	// FF - unofficial
