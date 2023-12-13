; +---------+
; | Install |
; +---------+
; brew install dosfstools
; brew install nasm
; brew install qemu 
;
; +----------------------------------+
; | Commands to make bootable floppy |
; +----------------------------------+
; nasm boot.asm -f bin -o boot.img
; dd if=/dev/zero of=floppy.img bs=512 count=2880
; /usr/local/Cellar/dosfstools/4.2/sbin/mkfs.fat -F 12 -n "Nox" floppy.img
; dd if=boot.img of=floppy.img conv=notrunc
;
; +-----------------------------+
; | Command to test in emulator |
; +-----------------------------+
; qemu-system-i386 -fda floppy.img
;

BITS 16								; Tell NASM that this is a 16bit program
org 0x7c00							; Start at memory address 0x7c00 whitc is where BIOS loads the bootloader into memory

boot:
	; Set up segment registers
	mov ax, 0
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov fs, ax
	mov gs, ax

	mov sp, 0x7c00					; The stack grows down, so we set stack pointer to the starting memory address of our program

	; Read the entire first track of the floppy disk (~9.2kb) so that we can run more then 512 bytes of our program
	mov ah, 0x02					; BIOS read from disk function
	mov al, 18						; Read 18 sectors of floppy disk
	mov ch, 0 						; Track 0
	mov cl, 2						; The sector to start reading from
	mov dh, 0						; Head (side) number
	or dl, dl 						; dl is the drive to read from, and the BIOS provides it on startup
	mov bx, 0x7e00					; 0x7e00 is a guarunteed open spot in memory, so this is where the read program data will go.
	int 0x13						; Call the BIOS to read from disk based on what we have just defined

	; We done all need to do in this part, so we can print message confirming it worked and fill the rest
	; of the first secotor with zeros and 0xAA55 at the end.
	mov si, bootmsg
	mov ah, 0x0e					; BIOS video service print character function
	mov bh, 0						; I cant say i know what this does, but im scared to remove it

.loop:
	lodsb 							;Load a byte of the message into AL.
                         					;Remember that DS is 0 and SI holds the
                         					;offset of one of the bytes of the message.
	cmp al, 0 						; Have we made it to the null terminator?
	je .done						; If so, we are done
	int 0x10						; BIOS video service
	jmp .loop

.done:
	; jmp $							; This is an infinite loop
	jmp start						; This is an infinite loop here, but in reality you jump to the place you are going to 
									; that outside the boot sector.

bootmsg: 
	db "floppy booted", 0			; Dont forget null terminators!

times 510 - ($-$$) db 0				; Fill the sector except for the actual code with zeros
dw 0xAA55							; Boot sector signature

; This is outside of the boot sector. Alltough much of the boot sector is zeros, it is always same size and bugs can happen if you go over
; the designated size. Just put most of your stuff out here. It will most likly load.

loaded:
	db "This message is loaded after boot!", 0, 0 	; Dont forget null terminators! for some reason we need two

start:
	call Set_Video_Mode
	mov si, loaded
	call Print

Print:
	mov ah, 0x0e
	mov bh, 0

.loop:
	lodsb
	cmp al, 0
	je .done
	int 0x10
	jmp .loop

.done:
	ret

;
; Set_Video_Mode: Set the display to VGA text mode
; screen size 80x25 size 

Set_Video_Mode:
	mov ah, 00h
	mov al, 03h
	int 0x10
	ret
