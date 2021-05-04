// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Floppy disks

.global load_drive1
.global load_drive2
.global floppy_disk_read
.global last_nibble
.global floppy_disk_write
.global flush_drive
.global drive1
.global drive2

.include "defs.s"
.include "macros.s"

// Load drive file
load_drive1:
	ldr	DRIVE,=drive1
	mov	w5,#'1'
	b	load_drive
load_drive2:
	ldr	DRIVE,=drive2
	mov	w5,#'2'
load_drive:
	ldr	x1,=drive_filename // open disk file
	strb	w5,[x1,#5]
	mov	w0,#-100
	mov	w2,#O_RDONLY
	mov	w8,#OPENAT
	svc	0
	cmp	x0,#0
	b.lt	no_disk
	ldr	x1,[DRIVE,#DRV_CONTENT] // read disk file
	mov	w2,#0x8e00
	movk	w2,#3,lsl #16
	mov	w8,#READ
	svc	0
	cmp	x0,x2
	b.ne	load_failure_drive
	mov	w0,#FLG_LOADED	// disk is loaded
	strb	w0,[DRIVE,#DRV_FLAGS]
no_disk:
	strb	w5,[DRIVE,#DRV_NUMBER]
	br	lr
load_failure_drive:
	ldr	x3,=msg_err_load_drive
	char	w5,31
	write	STDERR,37
	b	final_exit

// Optional: hide the disks by removing controller's signature
disable_drives:
	mov	w0,#DISK2ROM
	mov	w1,#JMP
	strb	w1,[MEM,x0]
	mov	w0,#(DISK2ROM + 1)
	mov	w1,#OLDRST
	strh	w1,[MEM,x0]
	br	lr

// Floppy disk (read access to memory)
floppy_disk_read:
	mov	w0,#IWM_PHASE0OFF
	sub	w1,ADDR,w0
	adr	x0,disk_table
	ldr	x2,[x0,x1,LSL 3]
	br	x2
change_track:
	lsr	w0,w1,#1	// w0 = new phase, w3 = old phase
	ldrb	w3,[DRIVE,#DRV_PHASE]
	strb	w0,[DRIVE,#DRV_PHASE]
	ldr	x2,=htrack_delta // w4 = half-track delta
	lsl	w3,w3,#2
	add	w3,w3,w0
	ldrsb	w4,[x2,x3]
	ldrb	w5,[DRIVE,#DRV_HTRACK] // compute new half-track
	adds	w5,w5,w4
	b.pl	1f
	mov	w5,#0
	b	2f
1:	cmp	w5,#80
	b.lt	2f
	mov	w5,#79
2:	strb	w5,[DRIVE,#DRV_HTRACK]
	br	lr
select_drive1:
	ldr	DRIVE,=drive1
	b	last_nibble
select_drive2:
	ldr	DRIVE,=drive2
	br	lr
transfer_nibble:
	ldr	x1,[DRIVE,#DRV_CONTENT]
	ldrb	w2,[DRIVE,#DRV_FLAGS]
	mov	w4,#6656
	ldrh	w5,[DRIVE,#DRV_HEAD]
	ldrb	w6,[DRIVE,#DRV_HTRACK]
	lsr	w7,w6,#1
	mul	w7,w7,w4
	add	w7,w7,w5
	mov	w9,#0
	tst	w2,#FLG_WRITE
	b.ne	write_nibble
read_nibble:
	and	w2,w2,#~FLG_DIRTY // only read when loaded + read mode
	and	w2,w2,#~FLG_READONLY
	cmp	w2,#FLG_LOADED
	b.ne	2f
	ldrb	w9,[x1,x7]	// read nibble at (track * 6656 + head position)
	add	w0,w5,#1	// move head forward
	cmp	w0,w4
	b.lt	1f
	mov	w0,#0
1:	strh	w0,[DRIVE,#DRV_HEAD]
2:	strb	w9,[DRIVE,#DRV_LASTNIB]
	strb	w9,[MEM,ADDR_64]
	//b	nibble_read	// uncomment this line to debug
	b	last_nibble
write_nibble:
	and	w2,w2,#~FLG_DIRTY // only write when loaded + write mode + not read-only
	cmp	w2,#(FLG_LOADED|FLG_WRITE)
	b.ne	2f
	ldrb	w9,[DRIVE,#DRV_NEXTNIB]	// write nibble to (track * 6656 + head position)
	strb	w9,[x1,x7]
	add	w0,w5,#1	// move head forward
	cmp	w0,w4
	b.lt	1f
	mov	w0,#0
1:	strh	w0,[DRIVE,#DRV_HEAD]
	orr	w2,w2,#FLG_DIRTY
	strb	w2,[DRIVE,#DRV_FLAGS]
2:
	//b	nibble_written	// uncomment this line to debug
	b	last_nibble
sense_protection:
	ldrb	w0,[DRIVE,#DRV_FLAGS]
	and	w9,w0,#FLG_READONLY
	strb	w9,[DRIVE,#DRV_LASTNIB]
	br	lr
read_mode:
	ldrb	w0,[DRIVE,#DRV_FLAGS]
	and	w0,w0,#~FLG_WRITE
	strb	w0,[DRIVE,#DRV_FLAGS]
	b	last_nibble
last_nibble:
	ldrb	w9,[DRIVE,#DRV_LASTNIB]
	strb	w9,[MEM,ADDR_64]
	br	lr

// Floppy disk (write access to memory)
floppy_disk_write:
	mov	w0,IWM_WRITEMODE
	cmp	ADDR,w0
	b.ne	load_next_nibble
write_mode:
	ldrb	w0,[DRIVE,#DRV_FLAGS]
	orr	w0,w0,#FLG_WRITE
	strb	w0,[DRIVE,#DRV_FLAGS]
load_next_nibble:
	ldrb	w9,[MEM,ADDR_64]
	strb	w9,[DRIVE,#DRV_NEXTNIB]
	br	lr

// Flush drive on exit
flush_drive:
	ldrb	w0,[DRIVE,#DRV_FLAGS]
	tst	w0,#FLG_DIRTY
	b.eq	1f
	and	w0,w0,#~FLG_DIRTY	// clean dirty flag
	strb	w0,[DRIVE,#DRV_FLAGS]
	ldrb	w5,[DRIVE,#DRV_NUMBER]	// open disk file
	ldr	x1,=drive_filename
	strb	w5,[x1,#5]
	mov	w0,#-100
	mov	w2,#O_WRONLY
	mov	w8,#OPENAT
	svc	0
	cmp	x0,#0
	b.lt	flush_failure_drive
	ldr	x1,[DRIVE,#DRV_CONTENT]	// read disk file
	mov	w2,#0x8e00
	movk	w2,#3,lsl #16
	mov	w8,#WRITE
	svc	0
	cmp	x0,x2
	b.ne	flush_failure_drive
1:	br	lr
flush_failure_drive:
	ldr	x3,=msg_err_flush_drive
	char	w5,31
	write	STDERR,37
	br	lr

// Fixed data
disk_table:
	.quad	last_nibble	// $C0E0
	.quad	change_track
	.quad	last_nibble
	.quad	change_track
	.quad	last_nibble
	.quad	change_track
	.quad	last_nibble
	.quad	change_track
	.quad	last_nibble	// $C0E8
	.quad	nothing_to_read
	.quad	select_drive1
	.quad	select_drive2
	.quad	transfer_nibble
	.quad	sense_protection
	.quad	read_mode
	.quad	nothing_to_read
htrack_delta:
	.byte	 0, +1, +2, -1
	.byte	-1,  0, +1, +2
	.byte	-2, -1,  0, +1
	.byte	+1, -2, -1,  0

// Variable data

.data

drive_filename:
	.asciz	"drive..nib"
msg_err_load_drive:
	.ascii	"Could not load drive file drive..nib\n"
msg_err_flush_drive:
	.ascii	"Could not save drive file drive..nib\n"
drive1:				// 35 tracks, 13 sectors of 512 nibbles
	.byte	0		// drive '1' or '2'
	.byte	0		// flags: loaded, write, dirty, read-only
	.byte	0		// last nibble read
	.byte	0		// next nibble written
	.byte	0		// phase 0-3
	.byte	0		// half-track 0-69
	.hword	0		// head 0-6655
	.quad	0		// pointer to content
drive2:
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.hword	0
	.quad	0
