;For your viewing and coding pleasure, here's a FAT12 boot loader, which is
;capable of reading up to almost 640kb of data into low memory, using multi-
;sector reads... and it digs into FAT, which allows you to copy your "system
;file" to the floppy in a usual manner... and enjoy the loading process.
;
;Written in the syntax of Tomasz Grysztar's fasm, get it at:
;
;   http://flatassembler.net/
;
;Or look for it anywhere else. Nothing to say about fasm but the fact that it
;SIMPLY ROCKS.
;
;Can be easily converted for nasm or whatever perverted assembler could there
;be.
;
;If you find the code useful, if you write something very valuable that it
;will load for you, or if you just simply want to talk about the dying world
;of assembly programming, feel free to write to petroffheroj@yahoo.com; sorry,
;at the moment there's no address that I can be proud of, that one is lame.
;
;Good luck in coding, my asm friends over the world.
;
;        PetroffHeroj
;
;P.S. Skipped the main part and eager to load anything immediately? The file
;name is specified under "sFileName", the physical address is 1600h by
;default, e.g. to change it, replace "mov ax,160h" and "jmp far 0000h:1600h"
;with whatever values you like. Also you could change the comments accordingly
;(uhhuhu).
;
;P.P.S. And quit using mustdie (wind0ze)! The author is using PC DOS 7.0,
;want to join? ;)
;
;2001-08-31
;
;A bug, as serious as stupid, was fixed: sector number was increased one extra
;time when loading root directory sector by sector. This made it impossible
;(usually) to boot if the file name was not in the first sector of the root
;directory. Don't use previous versions.
;
;2002-01-31
;
;Some BIOS incompatibilities were considered (preserving sector count in
;read_linear was commented out and has now been restored).
;The boot loader now works fine on my Commodore (:P) PC-10-II (BIOS written by
;Phoenix) and an old 286 (BIOS written by AMI), on both it didn't work before.
;The previous (more loose) version proved to work fine on different REPentiums
;and 486's and even on a cool Ukrainian brand "KOMPAN Plus 286" :) So, BIOS
;developers, ...!
;
;2002-03-15
;
;   ??????????????????????????????????????????????????????????????????????????????????????????????????????
;?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
;?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
;
;2021-09-30
;

	org	7C00h

FATSize 	equ 6144		;4096*1.5, max entries*entry size
RootSize	equ 512 		;we'll read one sector (512b) at once

start:
	jmp	short boot_code
	nop

b08_OEM 	db 'FucKnows'	;??????????????????????????????
wSecSize	dw ?  		;always must be a multiplier of 32!
						;(actually not used, 512b assumed)
bSecsPerCluster db ?	;number of sectors per one cluster
wResSecs	dw ? 		;boot and reserved sectors
						;also serves as data sector variable
bNumFATs	db ?		;number of FATs
wRootEntries	dw ?	;number of root entries
wTotSecs	dw ? 		;total sectors
bMedia		db ?		;"media descriptor", hehehe
wSecsPerFAT	dw ? 		;number of sector occupied by one FAT
wSecsPerTrack	dw ?	;sectors per track, should be < 64!
wSidesPerTrack	dw ?	;number of sides
dHiddenSecs	dd ?		;used only by DOS instead of MBR data
dBigTotSecs	dd ?		;big total sectors (not used)
bDrive		db ?		;drive number, filled from BIOS
			db ?
bExtBootSig	db ?		;extended boot sector signature
dSerNum 	dd 0BA5EC0DEh			;serial number :)
b11_VolumeLabel db '=cakepiece='	;volume label, addition to ser.num.?
b08_FileSysID	db 'FAT12   '		;completely unused FS signature...

boot_code:
;the modified DPT, along with the address of the old one, will be stored here
	push cs
	pop	ds			;ds=cs (0)
;	mov	[bDrive],dl		;save the boot drive number
	cmp	word [413h],(90000h+7C00h+FATSize+RootSize)/1024+1
					;do we have the memory we need?
					;??????98Mb ????????????
	jb	short error		;can't boot if less

	mov	ax,09000h		;set ss to 9000h
	mov	ss,ax			;interrupts disabled for the next op.
	mov	sp,start		;ss:sp=9000:7C00
	mov	es,ax			;es=9000

	mov	si,sp			;si=7C00
	mov	di,sp			;di=7C00
	mov	ch,01h			;256 to 511 words ;)
;      cld                             ;hopefully not needed...
	rep	movsw			;copy from 0000:7C00 to 9000:7C00

	lds	si,[1Eh*4]		;ds:si->int 1Eh "handler"
	mov	di,boot_code+4		;es:di->boot_code+4
	mov	[cs:di-4],si		;save the address of the old...
	mov	[cs:di-2],ds		;...int 1Eh "handler"
	mov	[cs:1Eh*4],di		;store the offset and...
	mov	[cs:1Eh*4+2],ax 	;...segment of new int 1Eh "handler"
	mov	cl,11			;copy 11 bytes (ch=0 already)
	rep	movsb			;from the old "handler" to the new one

	mov	ds,ax			;ds=9000 now
	mov	byte [di-2],15		;set head settle time to 15ms
;       mov     al,byte [wSecsPerTrack] ;al=sectors per track (last sector)
;       mov     byte [di-7],al          ;set last sector on track
	mov	byte [di-7],36		;set last sector on track <-- hmm, ok?

;should recalibrate after changing DPT?

	jmp	far 9000h:jump_here	;jump to the new code

error:
	mov	si,szError		;si->error string
	mov	ah,0Eh			;TTY output function number
       mov     bx,0007h                ;attribute (weird...)
	mov	cx,lenError		;string length

write:
	lodsb				;get a byte
	int	10h			;BIOS video interrupt
	loop	write			;repeat for the rest

write_done:
	xor	ah,ah			;wait key function number
	int	16h			;BIOS keyboard interrupt

	mov	ax,0E0Dh		;TTY output, CR
	int	10h			;BIOS video interrupt
	mov	al,0Ah			;now LF
	int	10h			;BIOS video interrupt

;restore the address of the old int 1Eh "handler"
	les	bx,[boot_code]		;get the address of the old int 1Eh
	xor	ax,ax			;ax=0
	mov	ds,ax			;ds=0
	mov	[1Eh*4],bx		;save offset to interrupt table
	mov	[1Eh*4+2],es		;save segment to interrupt table

	int	19h			;bootstrap

jump_here:
;read FAT to es:bx (9000:FAT) (es=ds)
	mov	al,[bNumFATs]		;ax=number of FATs
	mov	ah,byte [wSecsPerFAT]	;how many sectors to read, assumed <256
	mul	ah			;ax=sectors per all FATs
	push	[wResSecs]		;preserve reserved sectors variable
	add	[wResSecs],ax		;fix up the data sector variable
					;now it points to the root directory
	xchg	cx,ax			;cx=sectors per all FATs
	pop	ax			;ax=FAT sector number
	mov	bx,FAT			;read to es:bx, which->FAT

	call	read_linear		;read sectors

;read the root directory to es:bx (whatever it is)
;       mov     ax,[wResSecs]           ;root directory sector number, not
					;needed: root directory goes right
					;after both FATs
	mov	di,[wRootEntries]	;di=number of entries in the root dir.
	mov	cl,4			;shift four bits right (/16)
	shr	di,cl			;di=di*32/512 (assumed sector size)
					;so, di=number of root dir. sectors
	add	[wResSecs],di		;fix up the data sector variable
					;now it points to the first cluster

read_root:
	push	di			;preserve the counter

	push	es			;preserve es
	mov	cl,1			;one sector
	call	read_linear		;read sector (ax gets increased)
	pop	es			;restore es

	mov	di,bx			;es:di->RootDir
	mov	cl,512/32		;16 entries, sector size of 512 assumed
					;(32=size of one entry)
read_root_nextfile:
	push	cx			;preserve counter

	mov	cl,11			;file name length
	mov	si,sFileName		;ds:di->OS file name
	repe	cmpsb			;compare
	je	short found_system	;jump if equal (file found)
	add	di,cx			;increase si by the rest of cx
	add	di,21			;and fix up by 21 bytes - move to the
					;next entry
	pop	cx			;restore counter
	loop	read_root_nextfile	;repeat for next entry

	pop	di			;restore counter
	dec	di			;decrease it
	jnz	short read_root 	;if not zero, repeat for next sector

;didn't find the OS file
	jmp	short error

found_system:
	;pop    bx                      ;pop two cx counters
	;pop    bx
	mov	di,[es:di+15]		;di=cluster number from directory entry

	mov	ax,160h 		;0160 (segment)
	mov	es,ax			;load to 0160:0000 (0000:1600)
	xor	bx,bx			;0000 (offset)

next_block:
	xor	cx,cx
	mov	cl,[bSecsPerCluster]	;reset sector count to 1 cluster
	mov	si,di			;si=next should-be cluster for
					;contiguous reads
next_contiguous:
	mov	ax,3			;3
	mul	si			;multiply cluster number by 3
					;dx assumed to be 0, it's a floppy!
	shr	ax,1			;divide by two
	xchg	bp,ax			;bp=ax
	mov	ax,word [FAT+bp]	;ax=FAT element with junk
					;(addressing with bp, since ss=ds)
	jc	short odd_cluster	 ;jump if the value was odd

even_cluster:
	and	ax,0FFFh		;leave only lower 12 bits
	jmp	got_cluster		;got it

odd_cluster:
	push	cx			;preserve sector count
	mov	cl,4			;shift four bits right
	shr	ax,cl			;(leave only bits 4-15)
	pop	cx			;restore sector count

got_cluster:
	inc	si			;si=current cluster+1
;the following two lines may be omitted, since it would give an error (fatal)
;only if at cluster FF7-FFE there would be FF8-FFF (EOF), then, yes, this will
;think that FAT entry #FF7-FFE points to cluster FF8-FFF (contiguous) and will
;continue the process, which will definitely lead to an error. But since on
;usual floppies there's normally no such cluster numbers... well, we can skip
;this part and the code that follows it will do all we need
;       cmp     ax,0FF8h                ;EOF (FF8-FFF)?
;       jae     byte force_read         ;if yes, force read

	cmp	ax,si			;next cluster=current cluster+1?
	je	short still_contiguous	 ;it's still contiguous

force_read:
	xchg	di,ax			;ax=di (base cluster), di=new cluster
	dec	ax			;decrease by 2 to get the actual... (1)
	dec	ax			;...cluster number (2)
;currently 1 sector per cluster assumed for floppies
	xor	dx,dx
	mov	dl,[bSecsPerCluster]
	mul	dx			;multiply by sectors per cluster
					;(dx ignored)
	add	ax,[wResSecs]		;fix up by data sector variable
	call	read_linear		;read cx sectors at ax to es:bx :)

	cmp	di,0FF8h		;the new cluster is EOF (FF8-FFF)?
	jb	short next_block	 ;if not in this range, read next block

;we got it all!
all_read:
	jmp	far 0000h:1600h 	;jump to the code we've read

still_contiguous:
;prevent overflow of cx... but since the number of sectors on a normal floppy
;can't even get more than 4096, don't care. this is indeed stupid...
;?
;       cmp     cx,640*1024/512         ;anyway, not more than 640kb at once :)
;       jae     byte force_read         ;if it's more... ;) (this is stupid)
;?
	add	cl,[bSecsPerCluster]	;increase sector count by 1 cluster
	adc	ch,0
	jmp	next_contiguous

read_linear:	;in: ax=LBA starting sector, cx - number, es:bx->buffer

;!!! The supplied es:bx should not only be paragraph aligned in physical !!!
;!!!                memory, but even 512-byte page aligned               !!!

;should preserve ax,bx,???
;destroys: es (increased, points to memory right after the last sector read),
;               bp, si...

;read:
; convert x (LBA starting sector) to CHS triple
; count=SecsPerTrack-S+1
; if count>n (number of sectors to read) then count=n
; calculate the maximum number of sectors that can be read between the
;   physical address of es:bx and the next 64kb boundary
; if count>number then count=number
; read count sectors at CHS to es:bx
; sub n,count
; add x,count
; if n<>0 then jmp read

read_linear_next:
	push	ax			;preserve LBA sector number
	push	cx			;preserve count

;convert LBA sector number to CHS triple
;       cmp     dx,[SecsPerTrack]       ;prevent overflow
;       jnb     byte read_linear_fail
;won't overflow on a floppy in normal conditions, and since we don't use dx at
;all, zero it (cwd used since the LBA sector will definitely be below 8000h on
;a floppy... lots of assumptions!):
	cwd				;dx=0

	div	[wSecsPerTrack] 	;dx=0-based sector (hopefully, < 256
					;and even < 64), ax=quotient
	inc	dx			;make sector 1-based
	push	dx			;preserve it
	cwd				;dx=0 again
	div	[wSidesPerTrack]	;dx=head, ax=track (should be < 256)
	pop	cx			;restore sector number to cx
	mov	ch,al			;ch=track number (only bits 7-0)
	mov	dh,dl			;dh=head number, cl=sector (bits 5-0)
	mov	dl,[bDrive]		;dl=drive number

	mov	ax,[wSecsPerTrack]	;al=sectors per track, should be < 256
	sub	al,cl			;al=sectors we can read at once
	inc	ax			;need to do that: sectors are 1-based
					;(can_read=SecsPerTrack-S+1)

;may be we can address the saved cx using [ss:imm]?
	pop	si			;restore count to si
	push	si			;and save si back
	cmp	ax,si			;may be even less is left to be read?
	jna	short read_linear_count_ok	 ;no, not less

	xchg	si,ax			;yes, less, so ax=si

read_linear_count_ok:
;now calculate the maximum number of sectors that can be read between the
;physical address of es:bx and the next 64kb boundary
; -= the following code sucks =-
	push	bx			;begin suck - preserve them all!
	push	cx
	push	ax

	mov	ax,es			;ax=segment and bx=offset to read to
	mov	cl,4			;shift four bits right, divide by 16
	shr	bx,cl			;bx=offset/16
	add	ax,bx			;ax=physical address in paragraphs
	mov	bx,ax			;and bx is the same
	and	bx,0F000h		;mask of lower 12 bits
	add	bh,010h 		;increase bits 12-15
					;(so we got the next 64kb boundary)
	sub	bx,ax			;so, bx=number of paragraphs between
					;es:bx and the next 64kb boundary
	inc	cx			;cl=5 (for shift, divide by 32)
	shr	bx,cl			;now bx=number of 512b blocks between
					;es:bx and the next 64kb boundary
	pop	ax			;restore ax
	pop	cx			;restore cx

	cmp	al,bl			;may be we're trying to read too much?
	jna	short read_linear_count_really_ok	 ;no, quite fair amount

	xchg	ax,bx			;yes, so read less (till the next 64kb
					;boundary)
read_linear_count_really_ok:
	pop	bx			;end suck - restore the last register

	mov	bp,3			;number of retries

read_linear_again:
	push	ax			;save ax; count can be destroyed? RIGHT
	mov	ah,02h			;read sectors
	int	13h			;BIOS disk interrupt
	jnc	short read_linear_ok	;cool, no error (really?!! 8) )

	xor	ah,ah			;recalibrate
	int	13h			;well, dl already contains drive
					;number if somebody needs it :I
	pop	ax			;restore count
	dec	bp			;decrease tries counter
	jnz	short read_linear_again ;jump if not zero (try again)
	jmp	error			;well, error            <-- hmm

read_linear_ok:
;-= this code also sucks! =-
	pop	ax			;restore count
	push ax			;and preserve it again
	mov	cl,5			;shift five bits left (*32)
	shl	ax,cl			;ax=number of paragraphs we've read
					;(number of sectors*512/16=...*32)
	mov	cx,es			;cx=current es
	add	cx,ax			;fix up cx
	mov	es,cx			;and put it back to es
	pop	si			;restore count to si

	pop	cx			;restore the number of sectors to read
	pop	ax			;restore LBA sector number
	add	ax,si			;increase it by the number of sectors
					;already read
	sub	cx,si			;decrease it by the number of sectors
					;already read
	jnz	short read_linear_next	;if any more sectors to read, do

	retn				;bye

szError 	db 'Load error or no code>'
lenError=	$-szError
sFileName	 db 'BASECODE    '	;mister, what's that? guess yourself

		rb 7C00h+512-2-$	;fill up to the boot record signature
		db 055h,0AAh		;the signature itself

;end of sector - offset 200h (512)

FAT		rb 3072*2
IMG		rb 1024*98
