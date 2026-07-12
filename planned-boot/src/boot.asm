[BITS 16]
[ORG 0x7c00]

CODE_OFFSET equ 0x8
DATA_OFFSET equ 0x10
KERNEL_PHYS_ADDR equ 0x10000   ; must match KERNEL_LOAD_SEGMENT:KERNEL_LOAD_OFFSET below

start:
   cli ;clears interrupts or sum
   mov [boot_drive], dl ;BIOS passes boot drive in dl - save it before it's clobbered
   mov ax, 0x00
   mov ds, ax
   mov es, ax
   mov ss, ax
   mov sp, 0x7c00
   sti ;Enables them
   mov si, msg
   call print

   call load_kernel

   jmp load_PM

print:
    lodsb ;loads the byte at ds:si to AL register and incremens SI
    cmp al, 0
    je print_done
    mov ah, 0x0E
    int 0x10
    jmp print
print_done:
    ret

msg: db 'Welcome to Planned! Booting...', 0


KERNEL_LOAD_SEGMENT equ 0x1000   ; load to physical 0x10000
KERNEL_LOAD_OFFSET  equ 0x0000
KERNEL_SECTOR_COUNT equ 100      ; number of 512-byte sectors to read - adjust to your kernel's size
KERNEL_START_LBA    equ 1        ; sector right after the boot sector

load_kernel:
    mov si, dap
    mov ah, 0x42               ; BIOS extended read (LBA)
    mov dl, [boot_drive]
    int 0x13
    jc disk_error
    ret

disk_error:
    mov si, err_msg
    call print
    cli
    hlt

dap:                        ; Disk Address Packet for int 13h, ah=0x42
    db 0x10                 ; size of packet
    db 0
    dw KERNEL_SECTOR_COUNT
    dw KERNEL_LOAD_OFFSET
    dw KERNEL_LOAD_SEGMENT
    dq KERNEL_START_LBA

boot_drive: db 0
err_msg: db 'Critical Error: Boot Drive Missing', 0

load_PM:
    cli
    lgdt[gdt_descriptor]
    mov eax, cr0 
    or al, 1
    mov cr0, eax
    jmp CODE_OFFSET:PModeMain


;GDT Implemetation

gdt_start:
    dd 0x00000000
    dd 0x00000000

    ; Code segment descriptor
    dw 0xFFFF ; Limte
    dw 0x0000 ; Base #1 
    db 0x00 ; Base #2 - I don't think i should number them... No one cares! Or will they? I don't know :(
    db 10011010b ; access byte
    db 11001111b ; flags + limit high
    db 0x00 ; Base #3

    ; Data segment descriptor
    dw 0xFFFF
    dw 0x0000 ;base #1
    db 0x00 ; base #2
    db 10010010b ; access byte
    db 11001111b ; Flags...?
    db 0x00 ; base #3

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; size of GDT is -1
    dd gdt_start
[BITS 32]

PModeMain:
    mov ax, DATA_OFFSET
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov ss, ax
    mov gs, ax
    mov ebp, 0x9C00
    mov esp, ebp

    in al, 0x92
    or al, 2
    out 0x92, al

    jmp CODE_OFFSET:KERNEL_PHYS_ADDR   ; hand off control to the loaded kernel


times 510 - ($ - $$) db 0

dw 0xAA55 ; Boot sector signature, makes disk bootable
