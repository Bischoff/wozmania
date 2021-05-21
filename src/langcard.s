// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Language card

.global disable_langcard
.global enable_langcard
.global language_card

.include "src/defs.s"

// Disable the language card
disable_langcard:
	and	MEM_FLAGS,MEM_FLAGS,#~(MEM_LC_R | MEM_LC_W | MEM_LC_2 | MEM_LC_E)
	br	lr

// Enable the language card
enable_langcard:
	orr	MEM_FLAGS,MEM_FLAGS,#MEM_LC_E
	br	lr

// Language card control
language_card:
	tst	MEM_FLAGS,#MEM_LC_E	// if language card is disabled
	b.eq	1f			//   then do not change the other memory flags
	mov	w0,#RAM_CTL_BEGIN	//   otherwise load them from table
	sub	w1,ADDR,w0
	adr	x0,language_table
	ldrb	w2,[x0,x1]
	and	MEM_FLAGS,MEM_FLAGS,#~(MEM_LC_R | MEM_LC_W | MEM_LC_2 | MEM_LC_E)
	orr	MEM_FLAGS,MEM_FLAGS,w2
1:	br	lr


// Fixed data

language_table:
	.byte	MEM_LC_R            | MEM_LC_2 | MEM_LC_E // $C080
	.byte	           MEM_LC_W | MEM_LC_2 | MEM_LC_E
	.byte	                      MEM_LC_2 | MEM_LC_E
	.byte	MEM_LC_R | MEM_LC_W | MEM_LC_2 | MEM_LC_E
	.byte	MEM_LC_R            | MEM_LC_2 | MEM_LC_E
	.byte	           MEM_LC_W | MEM_LC_2 | MEM_LC_E
	.byte	                      MEM_LC_2 | MEM_LC_E
	.byte	MEM_LC_R | MEM_LC_W | MEM_LC_2 | MEM_LC_E
	.byte	MEM_LC_R                       | MEM_LC_E // $C088
	.byte	           MEM_LC_W            | MEM_LC_E
	.byte	                                 MEM_LC_E
	.byte	MEM_LC_R | MEM_LC_W            | MEM_LC_E
	.byte	MEM_LC_R                       | MEM_LC_E
	.byte	           MEM_LC_W            | MEM_LC_E
	.byte	                                 MEM_LC_E
	.byte	MEM_LC_R | MEM_LC_W            | MEM_LC_E

