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

bits 				16					; Tell NASM that this is a 16bit program
org 				0x7c00					; Start at memory address 0x7c00 is where BIOS loads the bootloader into memory
x_cursor:			db 0
y_cursor:			db 0

genesis:
	mov ax, 0x0003							; BIOS.SetVideoMode 80x25 16-color text
	int 0x10

	call color_red

loop:
	call read_key
	cmp ah, 0x50							; DOWN key, special key we check `ah`
	je move_down

	cmp ah, 0x48							; UP key, special key we check `ah`
	je move_up

	cmp ah, 0x4b							; LEFT key, special key we check `ah`
	je move_left

	cmp ah, 0x4d							; RIGHT key, special key we check `ah`
	je move_right

	cmp al, 0x31							; 1 key
	je color_red

	cmp al, 0x32							; 2 key
	je color_green

	cmp al, 0x33							; 3 key
	je color_blue

	cmp al, 0x20							; SPACE key
	je draw

	jmp loop

display_char:								; display char that is on AL
	mov ah, 0x0e
	mov bx, 0x000f
	int 0x10

	mov ax, 0x0003							; BIOS.SetVideoMode 80x25 16-color text
	int 0x10

	jmp loop
	ret

read_key:
	mov ah, 0x00							; read key and wait
	int 0x16
	ret

color_red:
	mov bx, 0x00cc							; red for background and foreground
	jmp loop
	ret

color_green:
	mov bx, 0x0022							; green for background and foreground
	jmp loop
	ret

color_blue:
	mov bx, 0x0099							; blue for background and foreground
	jmp loop
	ret

draw:
	mov cx, 0x01							; we want 1 replication of char
	mov al, 0x20							; Will add empty SPACE 
	mov ah, 0x09							; we apply WriteCharacterAndAttribute
	int 0x10

	jmp loop
	ret

move_left:
	mov al, [y_cursor]
	cmp al, 0 							; check if position is > 0
	jnle .continue							; go left with decrease value in cursor

	call loop
	ret

	.continue:
		dec al
		mov [y_cursor], al
		call move_cursor
		ret

move_right:
	mov al, [y_cursor]
	cmp al, 79							; check if position is > 79
	jl .continue	 						; go right with increasing value in cursor

	call loop
	ret

	.continue:
		inc al
		mov [y_cursor], al
		call move_cursor
		ret

move_down:
	mov al, [x_cursor]
	cmp al, 24							; check if position is > 24
	jl .continue 							; go down with increasing value in cursor

	call loop
	ret

	.continue:
		inc al
		mov [x_cursor], al
		call move_cursor
		ret

move_up:
	mov al, [x_cursor]
	cmp al, 0 							; check if position is > 0
	jnle .continue 							; go up with decrease value in cursor

	call loop
	ret

	.continue:
		dec al
		mov [x_cursor], al
		call move_cursor
		ret
	

move_cursor:
	mov dh, [x_cursor]						; Row
	mov dl, [y_cursor]						; Column
	mov bh, 0x00							; DisplayPage
	mov ah, 0x02							; BIOS.SetCursorPosition
	int 0x10

	call loop
	ret

done:
	jmp $								; This is an infinite loop

times 510 - ($-$$) db 0							; Fill the sector except for the actual code with zeros
dw 0xAA55								; Boot sector signature
