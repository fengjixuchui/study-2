;*************************************************
; crt16.asm                                      *
; Copyright (c) 2009-2013 ��־                   *
; All rights reserved.                           *
;*************************************************


%include "..\inc\support.inc"

;;
;; ���� 16λʵģʽ��ʹ�õ� runtime ��
;;


	bits 16
	
%include "..\lib\a20.asm"



;------------------------------------------------------
; clear_screen()
; description:
;       clear the screen & set cursor position at (0,0)
;------------------------------------------------------
cls:
        mov ax, 0x0600
        xor cx, cx
        xor bh, 0x0f            ; white
        mov dh, 24
        mov dl, 79
        int 0x10
        mov ah, 02
        xor bh, bh
        xor dx, dx
        int 0x10        
        ret
        
        

;-----------------------------------------------------------------
; read_sector(): ��ȡ����
; input:
;       ʹ�� disk_address_packet �ṹ
; output:
;       0 - successful, otherwise - error code
;----------------------------------------------------------------        
read_sector:
        push es
        push bx
        mov es, WORD [buffer_selector]                  ; es = buffer_selector
               
        ;
        ; ��ʼ�������� 0FFFFFFFFh
        ;
        cmp DWORD [start_sector + 4], 0
        jnz check_lba
        
        ;
        ; ���ģ���ڵ��� 504M ��������ʹ�� CHS ģʽ
        ;
        cmp DWORD [start_sector], 504 * 1024 * 2        ; 504M
        jb chs_mode
        
check_lba:
        ;
        ; ����Ƿ�֧�� 13h ��չ����
        ;
        call check_int13h_extension
        test ax, ax
        jz chs_mode
        
lba_mode:        
        ;
        ; ʹ�� LBA ��ʽ�� sector
        ;
        call read_sector_with_extension
        test ax, ax
        jz read_sector_done


        ;
        ; ʹ�� CHS ��ʽ�� sector
        ;
chs_mode:       

        ;
        ; ���һ�ζ����� 63 �������������ȡ��ÿ������63����
        ;
        movzx cx, BYTE [read_sectors]
        mov bx, cx
        and bx, 3Fh                                     ; bl = 64����������
        shr cx, 6                                       ; read_sectors / 64
        
        mov BYTE [read_sectors], 64                     ; ÿ�ζ�ȡ64������
        
chs_mode.@0:        
        test cx, cx
        jz chs_mode.@1

        call read_sector_with_chs                       ; ������
                
        ;
        ; ������ʼ������buffer
        ;
        add DWORD [start_sector], 64                    ; ��һ����ʼ����
        add WORD [buffer_offset], 64 * 512              ; ָ����һ�� buffer ��
        setc al
        shl ax, 12
        add WORD [buffer_selector], ax                  ; selector ����
        dec cx
        jmp chs_mode.@0


chs_mode.@1:
        ;
        ; ��ȡʣ������
        ;
        mov [read_sectors], bl
        call read_sector_with_chs                
        
read_sector_done:      
        pop bx
        pop es
        ret



;--------------------------------------------------------
; check_int13h_extension(): �����Ƿ�֧�� int13h ��չ����
; input:
;       ʹ�� driver_paramter_table �ṹ
; ouput:
;       1 - support, 0 - not support
;--------------------------------------------------------
check_int13h_extension:
        push bx
        mov bx, 55AAh
        mov dl, [driver_number]                 ; driver number
        mov ah, 41h
        int 13h
        setnc al                                ; c = ʧ��
        jc do_check_int13h_extension_done
        cmp bx, 0AA55h
        setz al                                 ; nz = ��֧��
        jnz do_check_int13h_extension_done
        test cx, 1
        setnz al                                ; z = ��֧����չ���ܺţ�AH=42h-44h,47h,48h
do_check_int13h_extension_done:        
        pop bx
        movzx ax, al
        ret
        
        
        
;--------------------------------------------------------------
; read_sector_with_extension(): ʹ����չ���ܶ�����        
; input:
;       ʹ�� disk_address_packet �ṹ
; output:
;       0 - successful, otherwise - error code
;--------------------------------------------------------------
read_sector_with_extension:
        mov si, disk_address_packet             ; DS:SI = disk address packet        
        mov dl, [driver_number]                 ; driver
        mov ah, 42h                             ; ��չ���ܺ�
        int 13h
        movzx ax, ah                            ; if unsuccessful, ah = error code
        ret
                


;-------------------------------------------------------------
; read_sector_with_chs(): ʹ�� CHS ģʽ������
; input:
;       ʹ�� disk_address_packet �� driver_paramter_table
; output:
;       0 - successful
; unsuccessful:
;       ax - error code
;-------------------------------------------------------------
read_sector_with_chs:
        push bx
        push cx
        ;
        ; �� LBA ת��Ϊ CHS��ʹ�� int 13h, ax = 02h ��
        ;
        call do_lba_to_chs
        mov dl, [driver_number]                 ; driver number
        mov es, WORD [buffer_selector]          ; buffer segment
        mov bx, WORD [buffer_offset]            ; buffre offset
        mov al, BYTE [read_sectors]             ; number of sector for read
        test al, al
        jz read_sector_with_chs_done
        mov ah, 02h
        int 13h
        movzx ax, ah                            ; if unsuccessful, ah = error code
read_sector_with_chs_done:
        pop cx
        pop bx
        ret
        
        
        
;-------------------------------------------------------------
; do_lba_to_chs(): LBA ��ת��Ϊ CHS
; input:
;       ʹ�� driver_parameter_table �� disk_address_packet �ṹ
; output:
;       ch - cylinder �� 8 λ
;       cl - [5:0] sector, [7:6] cylinder �� 2 λ
;       dh - header
;
; ������
;       
; 1) 
;       eax = LBA / (head_maximum * sector_maximum),  cylinder = eax
;       edx = LBA % (head_maximum * sector_maximum)
; 2)
;       eax = edx / sector_maximum, head = eax
;       edx = edx % sector_maximum
; 3)
;       sector = edx + 1      
;-------------------------------------------------------------
do_lba_to_chs:
        movzx ecx, BYTE [sector_maximum]        ; sector_maximum
        movzx eax, BYTE [header_maximum]        ; head_maximum
        imul ecx, eax                           ; ecx = head_maximum * sector_maximum
        mov eax, DWORD [start_sector]           ; LBA[31:0]
        mov edx, DWORD [start_sector + 4]       ; LBA[63:32]        
        div ecx                                 ; eax = LBA / (head_maximum * sector_maximum)
        mov ebx, eax                            ; ebx = cylinder
        mov eax, edx
        xor edx, edx        
        movzx ecx, BYTE [sector_maximum]
        div ecx                                 ; LBA % (head_maximum * sector_maximum) / sector_maximum
        inc edx                                 ; edx = sector, eax = head
        mov cl, dl                              ; secotr[5:0]
        mov ch, bl                              ; cylinder[7:0]
        shr bx, 2
        and bx, 0C0h
        or cl, bl                               ; cylinder[9:8]
        mov dh, al                              ; head
        ret
        
        
        
        
;---------------------------------------------------------------------
; get_driver_parameters(): �õ� driver ����
; input:
;       ʹ�� driver_parameters_table �ṹ
; output:
;       0 - successful, 1 - failure
; failure: 
;       ax - error code
;---------------------------------------------------------------------
get_driver_parameters:
        push dx
        push cx
        push bx
        mov ah, 08h                             ; 08h ���ܺţ��� driver parameters
        mov dl, [driver_number]                 ; driver number
        mov di, [parameter_table]               ; es:di = address of parameter table
        int 13h
        jc get_driver_parameters_done
        mov BYTE [driver_type], bl              ; driver type for floppy drivers
        inc dh
        mov BYTE [header_maximum], dh           ; ��� head ��
        mov BYTE [sector_maximum], cl           ; ��� sector ��
        and BYTE [sector_maximum], 3Fh          ; �� 6 λ
        shr cl, 6
        rol cx, 8
        and cx, 03FFh                           ; ��� cylinder ��
        inc cx
        mov [cylinder_maximum], cx              ; cylinder
get_driver_parameters_done:
        movzx ax, ah                            ; if unsuccessful, ax = error code
        pop bx
        pop cx
        pop dx
        ret
 
 
;-------------------------------------------------------------------
; load_module(int module_sector, char *buf)
; input:
;       ʹ�� disk_address_packet �ṹ���ṩ�Ĳ���
; output:
;       none
; ������
;       1) ����ģ�鵽 buf ������
;-------------------------------------------------------------------
load_module:
        push es
        push cx
        
        ;;
        ;; ���� 1 ���������õ�ģ��� size ֵ��Ȼ�������� size ��������ģ���ȡ
        ;;
        mov WORD [read_sectors], 1
	    call read_sector
	    test ax, ax
	    jnz do_load_module_done
        movzx esi, WORD [buffer_offset]
        mov es, WORD [buffer_selector]
        mov ecx, [es: esi]                                              ; ��ȡģ�� siz
        test ecx, ecx
        setz al
        jz do_load_module_done
        
        ;;
        ;; size ���ϵ����� 512 ����
        ;;
        add ecx, 512 - 1
        shr ecx, 9							; ���� block��sectors��
        mov WORD [read_sectors], cx                                     ; 
        call read_sector
do_load_module_done:  
        pop cx
        pop es
        ret


;------------------------------------------------------
; putc16()
; input: 
;       si - �ַ�
; output:
;       none
; ������
;       ��ӡһ���ַ�
;------------------------------------------------------
putc16:
	push bx
	xor bh, bh
	mov ax, si
	mov ah, 0Eh	
	int 10h
	pop bx
	ret

;------------------------------------------------------
; println16()
; input:
;       none
; output:
;       none
; ������
;       ��ӡ����
;------------------------------------------------------
println16:
	mov si, 13
	call putc16
	mov si, 10
	call putc16
	ret

;------------------------------------------------------
; puts16()
; input: 
;       si - �ַ���
; output:
;       none
; ������
;       ��ӡ�ַ�����Ϣ
;------------------------------------------------------
puts16:
	pusha
	mov ah, 0Eh
	xor bh, bh	

do_puts16.loop:	
	lodsb
	test al,al
	jz do_puts16.done
	int 10h
	jmp do_puts16.loop

do_puts16.done:	
	popa
	ret	
	
	
;------------------------------------------------------
; hex_to_char()
; input:
;       si - Hex number
; ouput:
;       ax - �ַ�
; ����:
;       �� Hex ����ת��Ϊ��Ӧ���ַ�
;------------------------------------------------------
hex_to_char16:
	push si
	and si, 0Fh
	movzx ax, BYTE [Crt16.Chars + si]
	pop si
	ret
	
	
;------------------------------------------------------
; convert_word_into_buffer()
; input:
;       si - ��ת��������word size)
;       di - Ŀ�괮 buffer�������Ҫ 5 bytes������ 0)
; ������
;       ��һ��WORDת��Ϊ�ַ����������ṩ�� buffer ��
;------------------------------------------------------
convert_word_into_buffer:
	push cx
	push si
	mov cx, 4                                       ; 4 �� half-byte
convert_word_into_buffer.loop:
	rol si, 4                                       ; ��4λ --> �� 4λ
	call hex_to_char16
	mov BYTE [di], al
	inc di
	dec cx
	jnz convert_word_into_buffer.loop
	mov BYTE [di], 0
	pop si
	pop cx
	ret

;------------------------------------------------------
; convert_dword_into_buffer()
; input:
;       esi - ��ת��������dword size)
;       di - Ŀ�괮 buffer�������Ҫ 9 bytes������ 0)
; ������
;       ��һ��WORDת��Ϊ�ַ����������ṩ�� buffer ��
;------------------------------------------------------
convert_dword_into_buffer:
	push cx
	push esi
	mov cx, 8					; 8 �� half-byte
convert_dword_into_buffer.loop:
	rol esi, 4					; ��4λ --> �� 4λ
	call hex_to_char16
	mov BYTE [di], al
	inc di
	dec cx
	jnz convert_dword_into_buffer.loop
	mov BYTE [di], 0
	pop esi
	pop cx
	ret

;------------------------------------------------------
; check_cpuid()
; output:
;       1 - support,  0 - no support
; ����:
;       ����Ƿ�֧�� CPUID ָ��
;------------------------------------------------------
check_cpuid:
	pushfd                                          ; save eflags DWORD size
	mov eax, DWORD [esp]                            ; get old eflags
	xor DWORD [esp], 0x200000                       ; xor the eflags.ID bit
	popfd                                           ; set eflags register
	pushfd                                          ; save eflags again
	pop ebx                                         ; get new eflags
	cmp eax, ebx                                    ; test eflags.ID has been modify
	setnz al                                        ; OK! support CPUID instruction
	movzx eax, al
	ret


;------------------------------------------------------
; ccheck_cpu_environment()
; input:
;       none
; output:
;       none
; ������
;       ����Ƿ�֧�� x64
;------------------------------------------------------
check_cpu_environment:
        mov eax, [CpuIndex]
        cmp eax, 16
        jb check_cpu_environment.check_x64
        hlt
        jmp $-1
check_cpu_environment.check_x64:
        mov eax, 80000000h
        cpuid
        cmp eax, 80000001h
        jb check_cpu_environment.no_support

        mov eax, 80000001h
        cpuid 
        bt edx, 29
        jc check_cpu_environment.done

check_cpu_environment.no_support:
        mov si, SDA.ErrMsg2
        call puts16
        hlt
        RESET_CPU

check_cpu_environment.done:
        ret    



;------------------------------------------------------
; get_system_memory()
; input:
;       none
; output:
;       none
; ������
;       1) �õ��ڴ� size�������� MMap.Size ��
;------------------------------------------------------
get_system_memory:
        push ebx
        push ecx
        push edx
        
;;
;; ��������
;;
SMAP_SIGN       EQU     534D4150h
MMAP_AVAILABLE  EQU     01h
MMAP_RESERVED   EQU     02h
MMAP_ACPI       EQU     03h
MMAP_NVS        EQU     04h




        xor ebx, ebx                            ; �� 1 �ε���
        mov edi, MMap.Base        
        
        ;;
        ;; ��ѯ memory map
        ;;
get_system_memory.loop:      
        mov eax, 0E820h
        mov edx, SMAP_SIGN
        mov ecx, 20
        int 15h
        jc get_system_memory.done
        
        cmp eax, SMAP_SIGN
        jne get_system_memory.done
        
        mov eax, [MMap.Type]
        cmp eax, MMAP_AVAILABLE
        jne get_system_memory.next
        
        mov eax, [MMap.Length]
        mov edx, [MMap.Length + 4]
        add [MMap.Size], eax
        adc [MMap.Size + 4], edx
        
get_system_memory.next:
        test ebx, ebx
        jnz get_system_memory.loop
        
get_system_memory.done:
        pop edx
        pop ecx
        pop ebx        
        ret
        


;------------------------------------------------------
; unreal_mode_enter()
; input:
;       none
; output:
;       none
; ������
;       1) �� 16 λ real mode ������ʹ��
;       2) �������غ󣬽��� 32λ unreal mode��ʹ�� 4G ����
;------------------------------------------------------
unreal_mode_enter:
        push ebp
        push edx
        push ecx
        push ebx
               
        mov cx, ds
        
        ;;
        ;; ������뱣��ģʽ�ͷ���ʵģʽ��ڵ��ַ
        ;;        
        call _TARGET
_TARGET  EQU     $
        pop ax
        mov bx, ax
        add ax, (_RETURN_TARGET - _TARGET)                      ; ����ʵģʽ���ƫ����
        add bx, (_ENTER_TARGET - _TARGET)                       ; ���뱣��ģʽ���ƫ����
          
        ;;
        ;; ����ԭ GDT pointer
        ;;
        sub esp, 6
        sgdt [esp]
        
        ;;
        ;; ѹ�뷵��ʵģʽ�� far pointer(16:16)
        ;;
        push cs
        push ax
      
        
        ;;
        ;; ��¼���ص�ʵģʽǰ�� stack pointer ֵ
        ;;        
        mov ebp, esp
        
        ;;
        ;; ѹ�� code descriptor
        ;;
        mov ax, cs
        xor edx, edx
        shld edx, eax, 20
        shl eax, 20
        or eax, 0000FFFFh                                       ; limit = 4G, base = cs << 4
        or edx, 00CF9A00h                                       ; DPL = 0, P = 1,��32-bit code segment
        ;or edx, 008F9A00h
        push edx
        push eax
        
        ;;
        ;; ѹ�� data descriptor
        ;;
        mov ax, ds
        xor edx, edx       
        shld edx, eax, 20
        shl eax, 20
        or eax, 0000FFFFh                                       ; limit = 4G, base = ds << 4
        or edx, 00CF9200h                                       ; DPL = 0, P = 1, 32-bit data segment
        push edx
        push eax
        
        ;;
        ;; ѹ�� NULL descriptor
        ;;
        xor eax, eax
        push eax
        push eax    

        
        ;;
        ;; ���뱣֤ ds = ss
        ;;
        mov ax, ss
        mov ds, ax
        
        ;;
        ;; ѹ�롡GDT pointer(16:32)
        ;;
        push esp
        push WORD (3 * 8 - 1)
        
        ;;
        ;; ���� GDT
        ;;
        lgdt [esp]
        
        ;;
        ;; �л��� 32 λ����ģʽ
        ;;
        mov eax, cr0
        bts eax, 0
        mov cr0, eax
        
        ;;
        ;; ת�뱣��ģʽ���˴� operand size = 16)
        ;;
        push 10h
        push bx
        retf
       


;;
;; 32 λ����ģʽ���
;;

_ENTER_TARGET   EQU     $

        bits 32
        ;bits 16
        
        ;;
        ;; ���� segment
        ;;
        mov ax, 08
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax
        mov ss, ax
        mov esp, ebp
        
        ;;
        ;; �رձ���ģʽ
        ;;
        mov eax, cr0
        btr eax, 0
        mov cr0, eax
        
        ;;
        ;; ���ص�ʵģʽ���˴� operand size = 32)
        ;; ��ˣ�ʹ�� 66h �������� 16 λ operand
        ;;
        DB 66h
        retf
        ;retf

        
_RETURN_TARGET  EQU     $

        ;;
        ;; �ָ�ԭ data segment ֵ
        ;;
        mov ds, cx
        mov es, cx
        mov fs, cx
        mov gs, cx
        mov ss, cx
        
        ;;
        ;; �ָ�ԭ GDT pointer ֵ
        ;;
        lgdt [esp]
        add esp, 6
        
        pop ebx
        pop ecx
        pop edx
        pop ebp
        
        ;;
        ;; �˴��� 32-bit operand size
        ;; ��ˣ���ʹ�� 16 λ�ķ��ص�ַ
        ;;
        DB 66h
        ret
        

;------------------------------------------------------
; protected_mode_enter()
; input:
;       none
; output:
;       none
; ������
;       1) �������л�������ģʽ
;       2) ����Ϊ FS ���õ�������
;------------------------------------------------------
        bits 16
        
protected_mode_enter:
	    pop ax
        push esp
        push ebp
        push edx
        push ecx
        push ebx

        xor ebx, ebx
        xor edi, edi
	    movzx eax, ax
                
        ;;
        ;; ������뱣��ģʽ�ͷ���ʵģʽ��ڵ��ַ
        ;;        
        call _TARGET1
_TARGET1 EQU $
        pop bx

        mov di, cs
        shl edi, 4
    	lea ebx, [edi+ebx+_TARGET2-_TARGET1]
	    mov [cs:_OFFSET], ebx
	    lea ebx, [eax+edi]

        
        ;;
        ;; ��¼���ص�ʵģʽǰ�� stack pointer ֵ
        ;;        
	    mov ax, ss
	    shl eax, 4
        lea ebp, [esp+eax]

	    ;;
        ;; ������ʱ�� GDT �������� GDT   
	    ;;
	    mov esi, [CpuIndex]
        shl esi, 7
        add esi, setup.Gdt
	    call set_stage1_gdt 
        lgdt [eax]


        ;;
        ;; �л��� 32 λ����ģʽ
        ;;
        mov eax, cr0
        bts eax, 0
        mov cr0, eax

        DB 66H, 0EAh
_OFFSET:
        DD 0
        DW KernelCsSelector32



;;
;; 32 λ����ģʽ���
;;

_TARGET2  EQU     $

        bits 32

        ;;
        ;; ���� segment
        ;;
        mov ax, FsSelector
        mov fs, ax        
        mov ax, GsSelector
        mov gs, ax
        mov ax, KernelSsSelector32
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov esp, ebp
        mov ax, TssSelector32
        ltr ax
        mov eax, [CpuIndex]
        shl eax, 13
        lea eax, [eax+KERNEL_STACK_PHYSICAL_BASE+1FF0h]
        mov [esp+10h], eax
        mov eax, ebx
        pop ebx
        pop ecx
        pop edx
        pop ebp
        pop esp
        jmp eax        



;------------------------------------------------------
; get_spin_lock16()
; input:
;       esi - lock
; output:
;       none
; ����:
;       1) �˺����������������
;       2) �������Ϊ spin lock ��ַ
;------------------------------------------------------
get_spin_lock16:
        ;;
        ;; ��������������˵��:
        ;; 1) ʹ�� bts ָ�������ָ������
        ;;    lock bts DWORD [esi], 0
        ;;    jnc AcquireLockOk
        ;;
        ;; 2) ������ʹ�� cmpxchg ָ��
        ;;    lock cmpxchg [esi], edi
        ;;    jnc AcquireLockOk
        ;;    
        
        xor eax, eax
        mov edi, 1        
        
        ;;
        ;; ���Ի�ȡ lock
        ;;
get_spink_lock16.acquire:
        lock cmpxchg [esi], edi
        je get_spink_lock16.done

        ;;
        ;; ��ȡʧ�ܺ󣬼�� lock �Ƿ񿪷ţ�δ������
        ;; 1) �ǣ����ٴ�ִ�л�ȡ����������
        ;; 2) �񣬼������ϵؼ�� lock��ֱ�� lock ����
        ;;
get_spink_lock16.check:        
        mov eax, [esi]
        test eax, eax
        jz get_spink_lock16.acquire
        pause
        jmp get_spink_lock16.check
        
get_spink_lock16.done:                
        ret
        


;;
;; ���ڱ��� int 13h/ax=08h ��õ� driver ����
;;
driver_parameters_table:        
        driver_number           DB      0               ; driver number
        driver_type             DB      0               ; driver type       
        cylinder_maximum        DW      0               ; ���� cylinder ��
        header_maximum          DW      0               ; ���� header ��
        sector_maximum          DW      0               ; ���� sector ��
        parameter_table         DW      0               ; address of parameter table 
                
;;
;; ���� int 13h ʹ�õ� disk address packet������ int 13h ��/д
;;        
disk_address_packet:
        size                    DW      10h             ; size of packet
        read_sectors            DW      0               ; number of sectors
        buffer_offset           DW      0               ; buffer far pointer(16:16)
        buffer_selector         DW      0               ; Ĭ�� buffer Ϊ 0
        start_sector            DQ      0               ; start sector


Crt16.Chars     DB      '0123456789ABCDEF', 0

