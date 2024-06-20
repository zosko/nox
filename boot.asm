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
row_cursor:		db 0
clumn_cursor:	db 0

genesis:
	mov ax, 0x0003	; BIOS.SetVideoMode 80x25 16-color text
	int 0x10

	;mov ax, 0xb800
	;mov ds, ax
	;mov es, ax

	;mov     ax, 0xcf00
    ;mov     cx, 10 * 25
    ;rep     stosw

	mov  cx, 0x10      ; ReplicationCount
	mov  bx, 0x002C    ; BH is DisplayPage (0) , BL is Attribute (BrightWhiteOnGreen)
	;; 2C means =  2 means Green for background  C means Red for text
	;; https://en.wikipedia.org/wiki/BIOS_color_attributes
	mov  ax, 0x0941    ; BIOS.WriteCharacterAndAttribute, AL is ASCII ("A")
	int  0x10

	;; predefined color
	mov bx, 0x0022	; green for background and foreground

start:
	call read_key
	cmp al, 's'	; DOWN key
	je move_down

	cmp al, 'w'	; UP key
	je move_up

	cmp al, 'a'	; LEFT key
	je move_left

	cmp al, 'd'	; RIGHT key
	je move_right

	cmp al, 0x31	; 1 key
	je choose_color_red

	cmp al, 0x32	; 2 key
	je choose_color_green

	cmp al, 0x33	; 3 key
	je choose_color_blue

	cmp al, 0x20	; SPACE key
	je draw

	jmp start

display_char:
	mov ah, 0x0e
	mov bx, 0x000f
	int 0x10
	ret

read_key:
	mov ah, 0x00
	int 0x16
	ret

choose_color_red:
	mov bx, 0x00CC	; red for background and foreground
	jmp start
	ret

choose_color_green:
	mov bx, 0x0022	; green for background and foreground
	jmp start
	ret

choose_color_blue:
	mov bx, 0x0099	; blue for background and foreground
	jmp start
	ret

draw:
	mov cx, 0x01	; we want 1 replication of char
	mov al, 0x20	; Will add empty SPACE 
	mov ah, 0x09	; we apply WriteCharacterAndAttribute
	int 0x10

	jmp start
	ret

move_left:
	mov al, [clumn_cursor]
	dec al
	mov [clumn_cursor], al

	call move_cursor
	ret

move_right:
	mov al, [clumn_cursor]
	inc al
	mov [clumn_cursor], al

	call move_cursor
	ret

move_down:
	mov al, [row_cursor]
	inc al
	mov [row_cursor], al

	call move_cursor
	ret

move_up:
	mov al, [row_cursor]
	dec al
	mov [row_cursor], al

	call move_cursor
	ret

move_cursor:
	mov dh, [row_cursor]	; Row
	mov dl, [clumn_cursor]	; Column
	mov bh, 0x00			; DisplayPage
	mov ah, 0x02			; BIOS.SetCursorPosition
	int 0x10

	call start
	ret

done:
	jmp $							; This is an infinite loop

times 510 - ($-$$) db 0				; Fill the sector except for the actual code with zeros
dw 0xAA55							; Boot sector signature
