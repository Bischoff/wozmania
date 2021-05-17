// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Floppy disks

.global load_drive1
.global load_drive2
.global disable_drives
.global enable_drives
.global floppy_disk_read
.global last_nibble
.global floppy_disk_write
.global flush_drive
.global drive1
.global drive2

.include "src/defs.s"
.include "src/macros.s"

// Try to load drive 1
load_drive1:
	ldr	DRIVE,=drive1
	mov	w5,#'1'
	strb	w5,[DRIVE,#DRV_NUMBER]
	b	load_drive

// Try to load drive 2
load_drive2:
	ldr	DRIVE,=drive2
	mov	w5,#'2'
	strb	w5,[DRIVE,#DRV_NUMBER]
	b	load_drive

// Try to load nib drive file
load_drive:
	mov	w4,#0			// initialize flags
	strb	w4,[DRIVE,#DRV_FLAGS]
	ldr	x1,=drive_filename	// open disk file
	strb	w5,[x1,#5]
	mov	w0,#-100
	mov	w2,#O_RDONLY
	mov	w8,#OPENAT
	svc	0
	cmp	x0,#0
	b.lt	no_disk
	mov	w9,w0			// test file protection
	ldr	x1,=stat
	mov	w8,#FSTAT
	svc	0
	cmp	x0,#0
	b.lt	load_failure_drive
	ldr	x1,=stat
	ldr	x0,[x1,#ST_MODE]
	tst	w0,#S_IWUSR
	b.ne	1f
	orr	w4,w4,#FLG_READONLY
1:	mov	w0,w9			// read disk file
	ldr	x1,[DRIVE,#DRV_CONTENT]
	mov	w2,#0x8e00
	movk	w2,#3,lsl #16
	mov	w8,#READ
	svc	0
	cmp	x0,x2
	b.ne	load_failure_drive
	orr	w4,w4,#FLG_LOADED	// disk is loaded
	strb	w4,[DRIVE,#DRV_FLAGS]
	br	lr
load_failure_drive:
	ldr	x3,=msg_err_load_drive
	char	w5,31
	write	STDERR,37
	b	final_exit

// No disk found at all
no_disk:
	br	lr


// Optional: hide the disks by removing controller's signature
disable_drives:
	mov	w0,#DISK2ROM
	mov	w1,#JMP
	strb	w1,[MEM,x0]
	mov	w0,#(DISK2ROM + 1)
	mov	w1,#OLDRST
	strh	w1,[MEM,x0]
	br	lr

// Optional: enable the disks by loading controller's ROM
enable_drives:
	adr	x0,rom_c600
	mov	x1,#DISK2ROM
	add	x1,x1,MEM
	add	x2,x0,#256
1:	ldr	x3,[x0],#8
	str	x3,[x1],#8
	cmp	x0,x2
	b.lt	1b
	br	lr

// Floppy disk (read access to memory)
floppy_disk_read:
	mov	w0,#IWM_PHASE0OFF
	sub	w1,ADDR,w0
	adr	x0,disk_table
	ldr	x2,[x0,x1,LSL 3]
	br	x2
change_track:
	lsr	w0,w1,#1		// w0 = new phase, w3 = old phase
	ldrb	w3,[DRIVE,#DRV_PHASE]
	strb	w0,[DRIVE,#DRV_PHASE]
	ldr	x2,=htrack_delta	// w4 = half-track delta
	lsl	w3,w3,#2
	add	w3,w3,w0
	ldrsb	w4,[x2,x3]
	ldrb	w5,[DRIVE,#DRV_HTRACK]	// compute new half-track
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
	mov	VALUE,#0x00
	tst	w2,#FLG_WRITE
	b.ne	write_nibble
read_nibble:
	and	w2,w2,#~FLG_DIRTY	// only read when loaded + read mode
	and	w2,w2,#~FLG_READONLY
	cmp	w2,#FLG_LOADED
	b.ne	2f
	ldrb	VALUE,[x1,x7]		// read nibble at (track * 6656 + head position)
	add	w0,w5,#1		// move head forward
	cmp	w0,w4
	b.lt	1f
	mov	w0,#0
1:	strh	w0,[DRIVE,#DRV_HEAD]
2:	strb	VALUE,[DRIVE,#DRV_LASTNIB]
	.ifdef	F_READ
	b	f_read
	.else
	b	last_nibble
	.endif
write_nibble:
	and	w2,w2,#~FLG_DIRTY	// only write when loaded + write mode + not read-only
	cmp	w2,#(FLG_LOADED|FLG_WRITE)
	b.ne	2f
	ldrb	VALUE,[DRIVE,#DRV_NEXTNIB] // write nibble to (track * 6656 + head position)
	strb	VALUE,[x1,x7]
	add	w0,w5,#1		// move head forward
	cmp	w0,w4
	b.lt	1f
	mov	w0,#0
1:	strh	w0,[DRIVE,#DRV_HEAD]
	orr	w2,w2,#FLG_DIRTY
	strb	w2,[DRIVE,#DRV_FLAGS]
2:
	.ifdef	F_WRITE
	b	f_write
	.else
	b	last_nibble
	.endif
sense_protection:
	ldrb	w0,[DRIVE,#DRV_FLAGS]
	and	VALUE,w0,#FLG_READONLY
	strb	VALUE,[DRIVE,#DRV_LASTNIB]
	br	lr
read_mode:
	ldrb	w0,[DRIVE,#DRV_FLAGS]
	and	w0,w0,#~FLG_WRITE
	strb	w0,[DRIVE,#DRV_FLAGS]
	b	last_nibble
last_nibble:
	ldrb	VALUE,[DRIVE,#DRV_LASTNIB]
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
	strb	VALUE,[DRIVE,#DRV_NEXTNIB]
	br	lr

// Flush drive on exit
flush_drive:
	ldrb	w4,[DRIVE,#DRV_FLAGS]
	tst	w4,#FLG_DIRTY
	b.ne	save_drive
	br	lr

// Attempt to save nib drive
save_drive:
	ldrb	w5,[DRIVE,#DRV_NUMBER]	// open disk file
	ldr	x1,=drive_filename
	strb	w5,[x1,#5]
	mov	w0,#-100
	mov	w2,#O_WRONLY
	mov	w8,#OPENAT
	svc	0
	cmp	x0,#0
	b.lt	save_failure_drive
	ldr	x1,[DRIVE,#DRV_CONTENT] // write disk file
	mov	w2,#0x8e00
	movk	w2,#3,lsl #16
	mov	w8,#WRITE
	svc	0
	cmp	x0,x2
	b.ne	save_failure_drive
	and	w4,w4,#~FLG_DIRTY	// clean dirty flag
	strb	w4,[DRIVE,#DRV_FLAGS]
	br	lr
save_failure_drive:
	ldr	x3,=msg_err_save_drive
	char	w5,31
	write	STDERR,37
	br	lr


// Fixed data

rom_c600:
	.byte	0xa2,0x20,0xa0,0x00,0xa2,0x03,0x86,0x3c
	.byte	0x8a,0x0a,0x24,0x3c,0xf0,0x10,0x05,0x3c
	.byte	0x49,0xff,0x29,0x7e,0xb0,0x08,0x4a,0xd0
	.byte	0xfb,0x98,0x9d,0x56,0x03,0xc8,0xe8,0x10
	.byte	0xe5,0x20,0x58,0xff,0xba,0xbd,0x00,0x01
	.byte	0x0a,0x0a,0x0a,0x0a,0x85,0x2b,0xaa,0xbd
	.byte	0x8e,0xc0,0xbd,0x8c,0xc0,0xbd,0x8a,0xc0
	.byte	0xbd,0x89,0xc0,0xa0,0x50,0xbd,0x80,0xc0
	.byte	0x98,0x29,0x03,0x0a,0x05,0x2b,0xaa,0xbd
	.byte	0x81,0xc0,0xa9,0x56,0x20,0xa8,0xfc,0x88
	.byte	0x10,0xeb,0x85,0x26,0x85,0x3d,0x85,0x41
	.byte	0xa9,0x08,0x85,0x27,0x18,0x08,0xbd,0x8c
	.byte	0xc0,0x10,0xfb,0x49,0xd5,0xd0,0xf7,0xbd
	.byte	0x8c,0xc0,0x10,0xfb,0xc9,0xaa,0xd0,0xf3
	.byte	0xea,0xbd,0x8c,0xc0,0x10,0xfb,0xc9,0x96
	.byte	0xf0,0x09,0x28,0x90,0xdf,0x49,0xad,0xf0
	.byte	0x25,0xd0,0xd9,0xa0,0x03,0x85,0x40,0xbd
	.byte	0x8c,0xc0,0x10,0xfb,0x2a,0x85,0x3c,0xbd
	.byte	0x8c,0xc0,0x10,0xfb,0x25,0x3c,0x88,0xd0
	.byte	0xec,0x28,0xc5,0x3d,0xd0,0xbe,0xa5,0x40
	.byte	0xc5,0x41,0xd0,0xb8,0xb0,0xb7,0xa0,0x56
	.byte	0x84,0x3c,0xbc,0x8c,0xc0,0x10,0xfb,0x59
	.byte	0xd6,0x02,0xa4,0x3c,0x88,0x99,0x00,0x03
	.byte	0xd0,0xee,0x84,0x3c,0xbc,0x8c,0xc0,0x10
	.byte	0xfb,0x59,0xd6,0x02,0xa4,0x3c,0x91,0x26
	.byte	0xc8,0xd0,0xef,0xbc,0x8c,0xc0,0x10,0xfb
	.byte	0x59,0xd6,0x02,0xd0,0x87,0xa0,0x00,0xa2
	.byte	0x56,0xca,0x30,0xfb,0xb1,0x26,0x5e,0x00
	.byte	0x03,0x2a,0x5e,0x00,0x03,0x2a,0x91,0x26
	.byte	0xc8,0xd0,0xee,0xe6,0x27,0xe6,0x3d,0xa5
	.byte	0x3d,0xcd,0x00,0x08,0xa6,0x2b,0x90,0xdb
	.byte	0x4c,0x01,0x08,0x00,0x00,0x00,0x00,0x00
disk_table:
	.quad	last_nibble		// $C0E0
	.quad	change_track
	.quad	last_nibble
	.quad	change_track
	.quad	last_nibble
	.quad	change_track
	.quad	last_nibble
	.quad	change_track
	.quad	last_nibble		// $C0E8
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
msg_err_save_drive:
	.ascii	"Could not save drive file drive..nib\n"
drive1:					// 35 tracks, 13 sectors of 512 nibbles
	.byte	0			// drive '1' or '2'
	.byte	0			// flags: loaded, write, dirty, read-only
	.byte	0			// last nibble read
	.byte	0			// next nibble written
	.byte	0			// phase 0-3
	.byte	0			// half-track 0-69
	.hword	0			// head 0-6655
	.quad	0			// pointer to content
drive2:
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.hword	0
	.quad	0
