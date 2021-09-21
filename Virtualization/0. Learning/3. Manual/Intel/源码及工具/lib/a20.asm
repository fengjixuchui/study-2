    bits 16


;----------------------------------------------
; int a20_test(int loops)
; ����:
;       ���� a20 �Ƿ���
; input:
;       esi - �ṩ���Դ���
; output:
;       0 - unsuccessful
;       other - successful
;----------------------------------------------
a20_test:
    xor ax, ax
    mov fs, ax
    dec ax
    mov gs, ax
    mov ax, [fs:0x200]
    push ax
a20_test.loop:
    inc ax
    mov [fs:0x200], ax          ; �� 0000:0200 д��ֵ
    IO_DELAY
    xor ax, [gs:0x210]          ; ��� ffff:0210 ��ֵ�Ƿ����
    jnz a20_test.done
    dec esi
    jnz a20_test.loop           ; ���ʱ����������
a20_test.done:
    pop WORD [fs:0x200]
    ret




;--------------------------------------
; int empty_8042()
; ����:
;       �ȴ�ֱ�� keyboard input-buf Ϊ��,�ɽ�������
; ����:
;       0 - unsuccessful
;       other - successful
;--------------------------------------
empty_8042:
    mov esi, 100000
    mov di, 32

empty_8042.loop:
    IO_DELAY
    in al, 0x64                 ; �����̿�����״̬
    cmp al, 0xff 
    jne empty_8042.@0
    dec di
    jz empty_8042.result
    
empty_8042.@0:
    ;;
    ;; bit0 = 1 ʱ, ָʾ output buf 60h ������
    ;; ��Ҫ������, ��� output buf
    ;;
    test al, 1
    jnz empty_8042.@1

    ;;
    ;; bit1 = 0 ʱ, ָʾ input buf Ϊ��, �ɽ�����������
    ;;
    test al, 2
    jnz empty_8042.@2

    mov ax, 1
    ret

empty_8042.@1:
    ;;
    ;; �� buf ��ȡ����, �� output-buf
    ;;
    IO_DELAY
    in al, 0x60

empty_8042.@2:
    dec esi
    jnz empty_8042.loop

empty_8042.result:
    xor ax, ax
    ret




;--------------------------------------
; int enable_a20()
; ����:
;       ���� A20 ��ַ��
; ����:
;       0 - unsuccessful
;       other - successful
;--------------------------------------
enable_a20:
    push cx
    mov cx, 255
    call a20_test_short
    jmp enable_a20_bios

a20_test_short:
    mov esi, 32
a20_test_long:
    call a20_test
    or ax, ax    
    jz enable_a20.done
    pop si
    pop cx
enable_a20.done:
    ret
 
enable_a20_bios:
    mov ax, 0x2401
    int 0x15
    call a20_test_short

    call empty_8042
    or ax, ax     
    mov esi, 32 
    jz enable_a20_kbc.test

enable_a20_kbc:
    call empty_8042
    mov al, 0xd1
    out 0x64, al
    call empty_8042
    mov al, 0xdf
    out 0x60, al                    ; A20 on
    call empty_8042
    mov al, 0xff
    out 0x64, al                    ; null command, but UHCI wants it
    call empty_8042
    mov esi, 2097152
enable_a20_kbc.test:
    call a20_test_long

enable_a20_fast:
    FAST_A20_ENABLE    
    mov esi, 2097152
    call a20_test_long
    dec cx
    jnz enable_a20_bios
    pop cx
    ret
