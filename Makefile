bin = bootboot
ASFLAGS = -f bin
$(bin): boot.asm
	nasm $(ASFLAGS) -o $@ $<

floppy.img: $(bin)
	dd if=/dev/zero of=$@ bs=1024 count=1440
	dd if=$< of=$@ bs=512 conv=notrunc

.PHONY: clean
clean:
	rm -f $(bin)

.PHONY: run
run: floppy.img
	qemu-system-i386 -fda $<

.PHONY: disasm
disasm: $(bin)
	ndisasm -b16 -o 0x7c00 $, > dis

.PHONY: debug
debug: floppy.img
	qemu-system-i386 -S -s -fda $<
