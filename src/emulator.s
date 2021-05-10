// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Emulator main program

.global _start
.global emulate
.global exit
.global final_exit

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
	mov	MEM_FLAGS,#LC_Z
	adr	INSTR,instr_table
	ldr	KEYBOARD,=kbd
	ldr	DRIVE,=drive1
	ldr	BREAKPOINT,=breakpoint
	bl	allocate_memory
	bl	load_rom
	bl	load_drive1
	bl	load_drive2
	//bl	disable_drives		// uncomment this line to disconnect the drives
	bl	prepare_terminal
	bl	prepare_keyboard
coldstart:
	bl	intercept_ctl_c
	bl	reset
emulate:
	//bl	trace			// uncomment these lines according to your debugging needs
	//bl	break
	//bl	check
	ldrb	w0,[KEYBOARD,#KBD_RESET]
	tst	w0,#0xFF
	b.ne	coldstart
	v_imm	w0
next:					// trace each instruction with "b next"
	ldr	x1,[INSTR,x0,LSL 3]
	br	x1

// Exit
exit:
	ldr	DRIVE,=drive1		// flush dirty drives
	bl	flush_drive
	ldr	DRIVE,=drive2
	bl	flush_drive
	bl	restore_keyboard	// restore normal keyboard
final_exit:
	mov	x0,#0			// exit program
	mov	x8,#93
	svc	0
