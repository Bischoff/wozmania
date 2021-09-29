// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021
// Released under GPLv2 license
//
// Floppy disks

.global load_drive1
.global load_drive2
.global disable_floppy
.global enable_floppy
.global floppy_disk_read
.global last_nibble
.global floppy_disk_write
.global flush_drive
.global rom_c600
.global drive1_filename
.global drive2_filename
.global drive1
.global drive2

.include "src/defs.s"
.include "src/macros.s"

// Try to load drive 1
load_drive1:
	ldr	DRIVE,=drive1
	mov	w5,#'1'
	strb	w5,[DRIVE,#DRV_NUMBER]
	ldr	x1,=drive1_filename
	str	x1,[DRIVE,#DRV_FNAME]
	b	load_drive

// Try to load drive 2
load_drive2:
	ldr	DRIVE,=drive2
	mov	w5,#'2'
	strb	w5,[DRIVE,#DRV_NUMBER]
	ldr	x1,=drive2_filename
	str	x1,[DRIVE,#DRV_FNAME]
	b	load_drive

// Try to load a drive
// File name is pointed at by x1
load_drive:
	ldrb	w0,[x1]			// no disk?
	tst	w0,#0xFF
	b.ne	1f
	br	lr
1:	filext	x1,x6,x7		// nib or dsk?
	adr	x4,ext_nib
	strcmp	x6,x7,x4,load_nib_drive
	adr	x4,ext_dsk
	strcmp	x6,x7,x4,load_dsk_drive
	b	load_failure_drive

// Load nib drive file
load_nib_drive:
	mov	w4,#0			// initialize flags
	strb	w4,[DRIVE,#DRV_FLAGS]
	mov	w0,#-100		// open disk file
	mov	w2,#O_RDONLY
	mov	w8,#OPENAT
	svc	0
	cmp	x0,#0
	b.lt	load_failure_drive
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
	mov	w4,#6656
	strh	w4,[DRIVE,#DRV_TSIZE]
	br	lr

// Load dsk drive file
load_dsk_drive:
	mov	w4,#FLG_DSK		// initialize flags
	strb	w4,[DRIVE,#DRV_FLAGS]
	mov	w0,#-100		// open disk file
	mov	w2,#O_RDONLY
	mov	w8,#OPENAT
	svc	0
	cmp	x0,#0
	b.lt	load_failure_drive
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
	mov	x9,x1
	mov	w2,#0x3000
	movk	w2,#2,lsl #16
	add	x1,x1,x2
	mov	x10,x1
	mov	w8,#READ
	svc	0
	cmp	x0,x2
	b.ne	load_failure_drive
	orr	w4,w4,#FLG_LOADED	// disk is loaded
	strb	w4,[DRIVE,#DRV_FLAGS]
	mov	w4,#8192
	strh	w4,[DRIVE,#DRV_TSIZE]
	mov	x0,x9			// convert its format
	mov	x1,x10
	mov	w2,#254
	b	explode_disk

// Failure loading drive file
load_failure_drive:
	ldr	x3,=msg_err_load_drive
	write	STDERR,26
	ldr	x3,[DRIVE,#DRV_FNAME]
	writez	STDERR
	ldr	x3,=msg_err_drive_2
	write	STDERR,1
	b	final_exit

// Convert dsk format to nib format
// input: x0 = destination (at start of content)
//        x1 = source      (0x23000 bytes ahead)
//        w2 = volume number
explode_disk:
	mov	w3,#0			// w3 = track number
explode_track:
	ldr	x6,=buffer		// copy source track to buffer (to avoid
					//   overlapping between source and destination)
	add	x7,x6,#(16*256)
1:	ldr	x8,[x1],#8
	str	x8,[x6],#8
	cmp	x6,x7
	b.lt	1b
	mov	w4,#0			// w4 = sector number
explode_sector:
	ldr	x6,=buffer
	adr	x9,sectors_order
	ldrb	w8,[x9,x4]
	lsl	w8,w8,#8
	add	x11,x6,x8
	mov	w5,#0			// w5 = destination byte count
load_gap_1:
	cmp	w4,#0			// $FF x 128, 40, or 38
	b.ne	1f
	mov	w6,#128
	b	3f
1:	cmp	w3,#0
	b.ne	2f
	mov	w6,#40
	b	3f
2:	mov	w6,#38
3:	ennib	#0xff,x0,w5
	cmp	w5,w6
	b.lt	3b
load_address_field:
	ennib	#0xd5,x0,w5		// $D5
	ennib	#0xaa,x0,w5		// $AA
	ennib	#0x96,x0,w5		// $96
	en4n4	w2,x0,w5		// volume
	mov	w6,w2
	en4n4	w3,x0,w5		// track
	eor	w6,w6,w3
	en4n4	w4,x0,w5		// sector
	eor	w6,w6,w4
	en4n4	w6,x0,w5		// checksum
	ennib	#0xde,x0,w5		// $DE
	ennib	#0xaa,x0,w5		// $AA
					// according to Beneath Apple DOS, there is $EB here...
load_gap_2:
	add	w6,w5,#5		// $FF x 5
1:	ennib	#0xff,x0,w5
	cmp	w5,w6
	b.lt	1b
load_data_field:
	ennib	#0xd5,x0,w5		// $D5
	ennib	#0xaa,x0,w5		// $AA
	ennib	#0xad,x0,w5		// $AD
	mov	x10,x0			// 86 extra bytes in 2-buffer
load_data_bytes:
	add	x0,x0,#86
	add	w5,w5,#86
	add	w6,w5,#86		// 86 source bytes
1:	ldrb	w9,[x11],#1
	en6n2	w9,x10,0,x0,w5
	cmp	w5,w6
	b.lt	1b
	sub	x10,x10,#86		// 86 source bytes
	add	w6,w5,#86
2:	ldrb	w9,[x11],#1
	en6n2	w9,x10,2,x0,w5
	cmp	w5,w6
	b.lt	2b
	sub	x10,x10,#86		// 84 source bytes
	add	w6,w5,#84
3:	ldrb	w9,[x11],#1
	en6n2	w9,x10,4,x0,w5
	cmp	w5,w6
	b.lt	3b
convert_to_nibbles:
	sub	x10,x0,#342
	adr	x9,map_6n2
	mov	w6,#0
1:	ldrb	w8,[x10]
	eor	w7,w8,w6
	mov	w6,w8
	ldrb	w8,[x9,x7]
	strb	w8,[x10],#1
	cmp	x10,x0
	b.lt	1b
	ldrb	w8,[x9,x6]		// checksum
	strb	w8,[x0],#1
	add	w5,w5,#1
	ennib	#0xde,x0,w5		// $DE
	ennib	#0xaa,x0,w5		// $AA
	ennib	#0xeb,x0,w5		// $EB
load_gap_3:
	ennib	#0xff,x0,w5		// $FF -> end
	cmp	w5,#512
	b.lt	load_gap_3
explode_next_sector:
	add	w4,w4,#1
	cmp	w4,#16
	b.lt	explode_sector
explode_next_track:
	add	w3,w3,#1
	cmp	w3,#35
	b.lt	explode_track
	br	lr

// Disable the floppy disk controller
disable_floppy:
					// deactivate $C600 ROM
	and	MEM_FLAGS,MEM_FLAGS,#~MEM_FL_E
	mov	w0,#DISK2ROM		// remove controller's signature that could be in memory from ROM file
	mov	w1,#JMP
	strb	w1,[MEM,x0]
	mov	w0,#(DISK2ROM + 1)
	mov	w1,#OLDRST
	strh	w1,[MEM,x0]
	br	lr

// Enable the floppy disk controller
enable_floppy:
					// activate $C600 ROM
	orr	MEM_FLAGS,MEM_FLAGS,#MEM_FL_E
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
1:	cmp	w5,#70
	b.lt	2f
	mov	w5,#69
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
	ldrh	w4,[DRIVE,#DRV_TSIZE]
	ldrh	w5,[DRIVE,#DRV_HEAD]
	ldrb	w6,[DRIVE,#DRV_HTRACK]
	lsr	w7,w6,#1
	mul	w7,w7,w4
	add	w7,w7,w5
	mov	VALUE,#0x00
	tst	w2,#FLG_WRITE
	b.ne	write_nibble
read_nibble:
	mov	w0,#(FLG_LOADED|FLG_WRITE) // only read when loaded + read mode
	and	w0,w0,w2
	cmp	w0,#FLG_LOADED
	b.ne	2f
	ldrb	VALUE,[x1,x7]		// read nibble at (track * tsize + head position)
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
	mov	w0,#(FLG_LOADED|FLG_WRITE|FLG_READONLY) // only write when loaded + write mode + not read-only
	and	w0,w0,w2
	cmp	w0,#(FLG_LOADED|FLG_WRITE)
	b.ne	2f
	ldrb	VALUE,[DRIVE,#DRV_NEXTNIB] // write nibble to (track * tsize + head position)
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
	ldrb	w4,[DRIVE,#DRV_FLAGS]	// something to save?
	tst	w4,#FLG_DIRTY
	b.ne	1f
	br	lr
1:	tst	w4,#FLG_DSK		// nib or dsk?
	b.ne	implode_disk

// Save nib drive file
save_nib_drive:
	ldr	x1,[DRIVE,#DRV_FNAME]	// open disk file
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
	ldrb	w4,[DRIVE,#DRV_FLAGS]	// clean dirty flag
	and	w4,w4,#~FLG_DIRTY
	strb	w4,[DRIVE,#DRV_FLAGS]
	br	lr

// Convert nib format to dsk format
implode_disk:
	ldr	x1,[DRIVE,#DRV_CONTENT]	// x1 = source (35 tracks of 16 x 512 nibbles)
	mov	w2,#254			// w2 = volume number
	mov	w3,#0			// w3 = track number
implode_track:
	ldr	x6,=buffer		// copy source track to buffer (to avoid
					//   overlapping between source and destination)
	add	x7,x6,#(16*512)
1:	ldr	x8,[x1],#8
	str	x8,[x6],#8
	cmp	x6,x7
	b.lt	1b
	mov	w4,#0			// w4 = sector number
implode_sector:
	ldr	x6,=buffer
	lsl	x8,x4,#9
	add	x0,x6,x8
	mov	w5,#0			// w5 = destination byte count
skip_gap_1:
	cmp	w4,#0			// $FF x 128, 40, or 38
	b.ne	1f
	mov	w6,#128
	b	3f
1:	cmp	w3,#0
	b.ne	2f
	mov	w6,#40
	b	3f
2:	mov	w6,#38
3:	denib	#0xff,x0,w5,save_failure_drive
	cmp	w5,w6
	b.lt	3b
skip_address_field:
	denib	#0xd5,x0,w5,save_failure_drive // $D5
	denib	#0xaa,x0,w5,save_failure_drive // $AA
	denib	#0x96,x0,w5,save_failure_drive // $96
	de4n4	w2,x0,w5,save_failure_drive // volume
	mov	w6,w2
	de4n4	w3,x0,w5,save_failure_drive // track
	eor	w6,w6,w3
	de4n4	w4,x0,w5,save_failure_drive // sector
	eor	w6,w6,w4
	de4n4	w6,x0,w5,save_failure_drive // checksum
	denib	#0xde,x0,w5,save_failure_drive // $DE
	denib	#0xaa,x0,w5,save_failure_drive // $AA
					// according to Beneath Apple DOS, there is $EB here...
skip_gap_2:
	add	w6,w5,#5		// $FF x 5
1:	denib	#0xff,x0,w5,save_failure_drive
	cmp	w5,w6
	b.lt	1b
store_data_field:
	denib	#0xd5,x0,w5,save_failure_drive // $D5
	denib	#0xaa,x0,w5,save_failure_drive // $AA
	denib	#0xad,x0,w5,save_failure_drive // $AD
	mov	x10,x0
convert_from_nibbles:
	add	x0,x0,#343
	adr	x9,map_6n2_inv
	mov	w6,#0
1:	ldrb	w7,[x10]
	ldrb	w8,[x9,x7]
	eor	w7,w8,w6
	mov	w6,w7
	tst	w7,#0xC0
	b.ne	save_failure_drive
	strb	w7,[x10],#1
	cmp	x10,x0
	b.lt	1b
store_data_bytes:
	sub	x10,x0,#343		// x10 = source
	mov	w7,w3			// x11 = destination (35 tracks of 16 * 256 bytes)
	lsl	w7,w3,#4
	adr	x9,sectors_order
	ldrb	w8,[x9,x4]
	orr	w8,w8,w7
	lsl	w8,w8,#8
	ldr	x11,[DRIVE,#DRV_CONTENT]
	add	x11,x11,x8
	add	x0,x10,#86		// 86 extra bytes in 2-buffer
	add	w5,w5,#86
	add	w6,w5,#86		// 86 source bytes
1:	de6n2	w9,x10,0,x0,w5
	strb	w9,[x11],#1
	cmp	w5,w6
	b.lt	1b
	sub	x10,x10,#86		// 86 source bytes
	add	w6,w5,#86
2:	de6n2	w9,x10,2,x0,w5
	strb	w9,[x11],#1
	cmp	w5,w6
	b.lt	2b
	sub	x10,x10,#86		// 84 source bytes
	add	w6,w5,#84
3:	de6n2	w9,x10,4,x0,w5
	strb	w9,[x11],#1
	cmp	w5,w6
	b.lt	3b
	denib	#0x00,x0,w5,save_failure_drive // checksum
	denib	#0xde,x0,w5,save_failure_drive // $DE
	denib	#0xaa,x0,w5,save_failure_drive // $AA
	denib	#0xeb,x0,w5,save_failure_drive // $EB
skip_gap_3:
	denib	#0xff,x0,w5,save_failure_drive // $FF -> end
	cmp	w5,#512
	b.lt	skip_gap_3
implode_next_sector:
	add	w4,w4,#1
	cmp	w4,#16
	b.lt	implode_sector
implode_next_track:
	add	w3,w3,#1
	cmp	w3,#35
	b.lt	implode_track

// Save dsk drive file
save_dsk_drive:
	ldr	x1,[DRIVE,#DRV_FNAME]	// open disk file
	mov	w0,#-100
	mov	w2,#O_WRONLY
	mov	w8,#OPENAT
	svc	0
	cmp	x0,#0
	b.lt	save_failure_drive
	ldr	x1,[DRIVE,#DRV_CONTENT] // write disk file
	mov	w2,#0x3000
	movk	w2,#2,lsl #16
	mov	w8,#WRITE
	svc	0
	cmp	x0,x2
	b.ne	save_failure_drive
	ldrb	w4,[DRIVE,#DRV_FLAGS]	// clean dirty flag
	and	w4,w4,#~FLG_DIRTY
	strb	w4,[DRIVE,#DRV_FLAGS]
	br	lr

// Failure saving drive file
save_failure_drive:
	ldr	x3,=msg_err_save_drive
	write	STDERR,26
	ldr	x3,[DRIVE,#DRV_FNAME]
	writez	STDERR
	ldr	x3,=msg_err_drive_2
	write	STDERR,1
	br	lr


// Fixed data

ext_nib:
	.asciz	".nib"
ext_dsk:
	.asciz	".dsk"
msg_err_load_drive:
	.ascii	"Could not load drive file "
msg_err_save_drive:
	.ascii	"Could not save drive file "
msg_err_drive_2:
	.ascii	"\n"
sectors_order:
	.byte	0x0,0x7,0xe,0x6,0xd,0x5,0xc,0x4
	.byte	0xb,0x3,0xa,0x2,0x9,0x1,0x8,0xf
map_6n2:
	.byte	0x96,0x97,0x9a,0x9b,0x9d,0x9e,0x9f,0xa6
	.byte	0xa7,0xab,0xac,0xad,0xae,0xaf,0xb2,0xb3
	.byte	0xb4,0xb5,0xb6,0xb7,0xb9,0xba,0xbb,0xbc
	.byte	0xbd,0xbe,0xbf,0xcb,0xcd,0xce,0xcf,0xd3
	.byte	0xd6,0xd7,0xd9,0xda,0xdb,0xdc,0xdd,0xde
	.byte	0xdf,0xe5,0xe6,0xe7,0xe9,0xea,0xeb,0xec
	.byte	0xed,0xee,0xef,0xf2,0xf3,0xf4,0xf5,0xf6
	.byte	0xf7,0xf9,0xfa,0xfb,0xfc,0xfd,0xfe,0xff
map_6n2_inv:   // 00   01   02   03   04   05   06   07   08   09   0a   0b   0c   0d   0e   0f
	.byte	 -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1  // 00
	.byte	 -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1  // 10
	.byte	 -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1  // 20
	.byte	 -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1  // 30
	.byte	 -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1  // 40
	.byte	 -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1  // 50
	.byte	 -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1  // 60
	.byte	 -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1  // 70
	.byte	 -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1  // 80
	.byte	 -1 , -1 , -1 , -1 , -1 , -1 ,0x00,0x01, -1 , -1 ,0x02,0x03, -1 ,0x04,0x05,0x06 // 90
	.byte	 -1 , -1 , -1 , -1 , -1 , -1 ,0x07,0x08, -1 , -1 , -1 ,0x09,0x0a,0x0b,0x0c,0x0d // a0
	.byte	 -1 , -1 ,0x0e,0x0f,0x10,0x11,0x12,0x13, -1 ,0x14,0x15,0x16,0x17,0x18,0x19,0x1a // b0
	.byte	 -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 ,0x1b, -1 ,0x1c,0x1d,0x1e // c0
	.byte	 -1 , -1 , -1 ,0x1f, -1 , -1 ,0x20,0x21, -1 ,0x22,0x23,0x24,0x25,0x26,0x27,0x28 // d0
	.byte	 -1 , -1 , -1 , -1 , -1 ,0x29,0x2a,0x2b, -1 ,0x2c,0x2d,0x2e,0x2f,0x30,0x31,0x32 // e0
	.byte	 -1 , -1 ,0x33,0x34,0x35,0x36,0x37,0x38, -1 ,0x39,0x3a,0x3b,0x3c,0x3d,0x3e,0x3f // f0
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

drive1_filename:
	.fill	128,1,0
drive2_filename:
	.fill	128,1,0
drive1:					// 35 tracks, 13 or 16 sectors, 512 nibbles each (for 256 bytes)
	.byte	0			// drive '1' or '2'
	.byte	0			// flags: loaded, write, dirty, read-only
	.byte	0			// last nibble read
	.byte	0			// next nibble written
	.byte	0			// phase 0-3
	.byte	0			// half-track 0-69
	.hword	0			// head 0-6655 or 0-8191
	.hword	0			// track size 6656 or 8192
	.quad	0			// pointer to filename
	.quad	0			// pointer to content
drive2:
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.hword	0
	.hword	0
	.quad	0
	.quad	0
