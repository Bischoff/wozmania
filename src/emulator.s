// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Emulator main program

.global _start
.global emulate
.global exit
.global final_exit
.global buffer

.include "src/defs.s"
.include "src/macros.s"

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
	mov	MEM_FLAGS,#LC_Z		// set main registers
	adr	INSTR,instr_table
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
	ldr	x0,=conf_flags		// apply options
	ldrb	w1,[x0]
	tst	w1,#CNF_FLOPPY_D
	b.eq	1f
	bl	disable_floppy
	b	2f
1:	tst	w1,#CNF_FLOPPY_I
	b.eq	2f
	bl	install_floppy
2:	bl	prepare_terminal	// prepare terminal
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
	bl	restore_keyboard	// restore normal keyboard
final_exit:
	mov	x0,#0			// exit program
	mov	x8,#EXIT
	svc	0


// Variable data

.data

buffer:					// general use buffer
	.fill	SIZEOF_BUFFER,1,0
