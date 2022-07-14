// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021-2022
// Released under GPLv2 license
//
// Emulator main program

.global _start
.global emulate
.global exit
.global final_exit
.global buffer

.include "defs.s"
.include "macros.s"

// Adjust optional hardware
adjust_hardware:
	mov	x8,lr
	ldr	x0,=conf_flags
	ldrb	w1,[x0]
	tst	w1,#CNF_LANGCARD_E
	b.eq	1f
	bl	enable_langcard
	b	2f
1:	bl	disable_langcard
2:	tst	w1,#CNF_FLOPPY_E
	b.eq	3f
	bl	enable_floppy
	b	4f
3:	bl	disable_floppy
4:	tst	w1,#CNF_80COL_E
	b.eq	5f
	bl	enable_80col
	b	6f
5:	bl	disable_80col
6:	br	x8

// Put 6502 processor in initial state
reset:
	mov	A_REG,#0
	mov	X_REG,#0
	mov	Y_REG,#0
	mov	S_REG,#0
	mov	SP_REG,#0x1FF
	mov	x0,#0xFFFC
	ldrh	PC_REG,[MEM,x0]
	br	lr

// Main loop
_start:
	mov	MEM_FLAGS,#0		// set main registers
	adr	INSTR,instr_table
	ldr	SCREEN,=screen
	ldr	KEYBOARD,=kbd
	ldr	DRIVE,=drive1
	.ifdef	BREAK
	ldr	BREAKPOINT,=breakpoint
	.endif
	bl	allocate_memory		// call initialization routines
	bl	load_conf
	bl	load_rom
	bl	load_drive1
	bl	load_drive2
	bl	adjust_hardware
	bl	prepare_terminal
	bl	prepare_keyboard
coldstart:
	bl	intercept_ctl_c
	bl	reset
emulate:
	.ifdef	TRACE			// optional debug routines
	bl	trace
	.endif
	.ifdef	BREAK
	bl	break
	.endif
	.ifdef	CHECK
	bl	check
	.endif
	ldrb	w0,[KEYBOARD,#KBD_RESET] // check for Ctrl-Reset
	tst	w0,#0xFF
	b.ne	coldstart
	v_imm	w0			// load next instruction
next:					//   (trace each instruction with "b next")
	ldr	x1,[INSTR,x0,LSL 3]
	br	x1			// emulate the instruction

// Exit
exit:
	ldr	DRIVE,=drive1		// flush dirty drives
	bl	flush_drive
	ldr	DRIVE,=drive2
	bl	flush_drive
	bl	clean_terminal		// cleanup terminal
	bl	restore_keyboard	// restore normal keyboard
final_exit:
	mov	x0,#0			// exit program
	mov	x8,#EXIT
	svc	0


// Variable data

.data

buffer:					// general purpose buffer
	.fill	SIZEOF_BUFFER,1,0
