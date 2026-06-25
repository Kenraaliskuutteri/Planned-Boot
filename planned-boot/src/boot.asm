[BITS 16]
[ORG 0x7c00]

CODE_OFFSET equ 0x8
DATA_OFFSET equ 0x10

start:
   cli ;clears interrupts or sum
   mov ax, 0x00
   mov ds, ax
   mov es, ax
   mov ss, ax
   mov sp, 0x7c00
   sti ;Enables them
   mov si, msg

print:
    lodsb ;loads the byte at ds:si to AL register and incremens SI
    cmp al, 0
    je done
    mov ah, 0x0E
    int 0x10
    jmp print

done:
   cli
   hlt ;Stop further

msg: db 'Welcome to Planned! Booting...', 0

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
    db 1001101 ; access byte

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
    move esp, ebp

    in al, 0x92
    or al, 2
    out 0x92, al

    jmp


times 510 - ($ - $$), db 0

dw 0xAA55 ; Boot sector signature, makes disk bootable