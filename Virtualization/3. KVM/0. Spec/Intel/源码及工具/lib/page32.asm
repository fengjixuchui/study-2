;*************************************************
; page32.asm                                     *
; Copyright (c) 2009-2013 ��־                   *
; All rights reserved.                           *
;*************************************************


%include "..\inc\page.inc"





        bits 32




;-------------------------------------------------------------
; clear_8m_for_pae(): �� 8M ����PAE ģʽʹ�õ�ҳת����
; input:
;       esi - address
;-------------------------------------------------------------
clear_8m_for_pae:
        push ecx
        mov ecx, (8 * 1024 * 1024) / 4096
clear_8m_for_pae.loop:        
        call clear_4k_buffer
        add esi, 4096
        dec ecx
        jnz clear_8m_for_pae.loop
        pop ecx
        ret
        
        
;--------------------------------------------------
; get_pte_offset()
; input:
;       esi - virutal address or physical address
; output:
;       eax - pte address offset
;-------------------------------------------------- 
get_pte_offset:
        mov eax, esi
        shr eax, 12                             ; get pte index
        shl eax, 3                              ; pte index * 8
        ret
        
;--------------------------------------------------
; get_pte_virtual_address()
; input:
;       esi - virutal address
; output:
;       eax - virtual address of pte address
;--------------------------------------------------        
get_pte_virtual_address:
        mov eax, esi
        shr eax, 12
        shl eax, 3
        add eax, [fs: SDA.PtBase]
        ret

;--------------------------------------------------
; get_pte_physical_address()
; input:
;       esi - physical address
; output:
;       eax - physical address of pte address
;--------------------------------------------------        
get_pte_physical_address:
        mov eax, esi
        shr eax, 12
        shl eax, 3
        add eax, [fs: SDA.PtPhysicalBase]
        ret

        


;-------------------------------------------------------------------
; load_pdpt()
; input:
;       esi - physical address of PDPT(page directory pointer table)
; output:
;       eax - pde address
;------------------------------------------------------------------
load_pdpt:
        push ecx
        push ebx
        mov ebx, esi
        xor ecx, ecx

        ;;
        ;; �� PDPT ��ַ������ 32 bytes ����
        ;;
        add ebx, 31
        and ebx, 0FFFFFFE0h

        ;;
        ;; ������ PDPT ����
        ;;
        mov eax, [fs: SDA.PdtPhysicalBase]                      ; PDT �������ַ
        and eax, 0FFFFF000h
        or eax, P                                               ; PDPTE0
        mov [ebx], eax
        add eax, 1000h                                          ; PDPTE1
        mov [ebx + 4], ecx
        mov [ebx + 8], eax
        add eax, 1000h                                          ; PDPTE2
        mov [ebx + 8 + 4], ecx
        mov [ebx + 16], eax
        add eax, 1000h                                          ; PDPTE3       
        mov [ebx + 16 + 4], ecx
        mov [ebx + 24], eax
        mov [ebx + 24 + 4], ecx
        mov cr3, ebx
        pop ebx
        pop ecx
        ret



;-----------------------------------------------------------------
; init_pae_ppt:
; input:
;       none
; output:
;       none
; ����:
;       1) ��ʼ���������� PPT ��
;-----------------------------------------------------------------
init_pae_ppt:
        mov DWORD [gs: PCB.Ppt], PDT0_PHYSICAL_BASE | P
        mov DWORD [gs: PCB.Ppt+4], 0
        mov DWORD [gs: PCB.Ppt+8], PDT1_PHYSICAL_BASE | P
        mov DWORD [gs: PCB.Ppt+12], 0
        mov DWORD [gs: PCB.Ppt+16], PDT2_PHYSICAL_BASE | P
        mov DWORD [gs: PCB.Ppt+20], 0
        mov DWORD [gs: PCB.Ppt+24], PDT3_PHYSICAL_BASE | P
        mov DWORD [gs: PCB.Ppt+28], 0
        ret


;-----------------------------------------------------------------
; init_pae_page():
; input:
;       none
; output:
;       none
; ����:
;       1) ӳ��ҳת����ṹ����
;       2) ʹ�� 4K ҳ��
;-----------------------------------------------------------------
init_pae_page:
        push ecx

        ;;
        ;; ��ҳת��������(8M)
        ;;
        mov esi, [fs: SDA.PtPhysicalBase]
        call clear_8m_for_pae

        ;;
        ;; ӳ��PAEҳת����ṹ
        ;;
        mov esi, PT_PHYSICAL_BASE | P
        mov edi, PDT_PHYSICAL_BASE
        xor ecx, ecx
        xor eax, eax
map_pae_page_transition_table.loop:
        mov [edi+ecx*8], esi
        mov [edi+ecx*8+4], eax
        add esi, 1000h
        inc ecx
        cmp ecx, 4000h / 8
        jb map_pae_page_transition_table.loop 

        pop ecx
        ret
        
        


        
;-----------------------------------------------------------
; do_virtual_address_mapping32(): ִ�������ַӳ��
; input:
;       esi - virtual address
;       edi - physical address
;       eax - attribute
; output:
;       0 - succssful, ���򷵻ش�����
;
; desciption:
;       eax ���ݹ����� attribute �������־λ��ɣ�
;       [0] - P
;       [1] - R/W
;       [2] - U/S
;       [3] - PWT
;       [4] - PCD
;       [5] - A
;       [6] - D
;       [7] - PAT
;       [8] - G
;       [12] - ingore
;       [28] - ingore
;       [29] - FORCE����λʱ��ǿ�ƽ���ӳ��
;       [30] - PHYSICAL����λʱ����ʾ���������ַ����ӳ�䣨���ڳ�ʼ��ʱ��
;       [31] - XD
;----------------------------------------------------------
do_virtual_address_mapping32:
        push ecx
        push ebx
        push edx
        push esi    
        push edi
        
        and esi, 0FFFFF000h
        and edi, 0FFFFF000h
        mov ecx, eax
        
                
        ;;
        ;; PT_BASE - PT_TOP �����Ѿ���ʼ��ӳ�䣬�����ٽ���ӳ��
        ;; ����ӳ�䵽 PT_BASE - PT_TOP �����ھ�ʧ�ܷ���
        ;;
        cmp esi, [fs: SDA.PtBase]
        jb do_virtual_address_mapping32.next
        cmp esi, [fs: SDA.PtTop]
        ja do_virtual_address_mapping32.next

        mov eax, MAPPING_USED
        jmp do_virtual_address_mapping32.done
        

do_virtual_address_mapping32.next:
        ;;
        ;; ��ȡ PTE ��ַ
        ;;
        test ecx, PHY_ADDR                              ; physical address ��־λ
        mov eax, get_pte_virtual_address
        mov edx, get_pte_physical_address
        cmovnz eax, edx
        call eax
        mov ebx, eax

        ;;
        ;; ��� present ��־λ
        ;;
        test DWORD [ebx], P
        jz do_virtual_address_mapping32.set_pte
        test ecx, FORCE
        jnz do_virtual_address_mapping32.set_pte
        
        ;;
        ;; �Ѿ���ʹ��, ���س���״̬
        ;;
        mov eax, MAPPING_USED
        jmp do_virtual_address_mapping32.done


        ;;
        ;; ���� PTE
        ;; 
do_virtual_address_mapping32.set_pte:
        mov edx, [fs: SDA.XdValue]
        and edx, ecx
        mov eax, ecx
        and eax, 1FFh
        or eax, edi

        ;; д�� PTE ֵ
        mov [ebx], eax
        mov [ebx+4], edx

        mov eax, MAPPING_SUCCESS

do_virtual_address_mapping32.done:
        pop edi
        pop esi
        pop edx
        pop ebx
        pop ecx
        ret


;-----------------------------------------------------------
; do_virtual_address_mapping32_n()
; input:
;       esi - virtual address
;       edi - physical address
;       eax - attribute
;       ecx - n ��ҳ��
; output:
;       0 - succssful, ���򷵻ش�����
; ������
;       1) ӳ�� n �� ҳ��
;-----------------------------------------------------------
do_virtual_address_mapping32_n:
        push ecx
        push edx
        mov edx, eax

do_virtual_address_mapping32_n.loop:        
        mov eax, edx
        call do_virtual_address_mapping32
        add esi, 1000h
        add edi, 1000h
        dec ecx
        jnz do_virtual_address_mapping32_n.loop
        
        pop edx
        pop ecx
        ret



        

;-----------------------------------------------------------
; query_physical_page()
; input:
;       esi - va
; output:
;       edx:eax - ����ҳ�棬ʧ��ʱ������ -1
; ������
;       1) ��ѯ�����ַӳ�������ҳ��
;       2) �������ַ��ӳ��ҳ��ʱ������ -1 ֵ
;-----------------------------------------------------------
query_physical_page:
        push ebx
        
        
        ;;
        ;; �� PTE ֵ
        ;;
        call get_pte_virtual_address
        mov edx, [eax + 4]
        mov eax, [eax]
        mov esi, -1
        and edx, [gs: PCB.MaxPhyAddrSelectMask + 4]
        
        ;;
        ;; ��� PTE �Ƿ���Ч
        ;;
        test eax, P
        cmovz edx, esi
        cmovz eax, esi
        jz query_physical_page.done
        
query_physical_page.ok:
        and eax, 0FFFFF000h
        
query_physical_page.done:        
        pop ebx
        ret        
        
        


;-----------------------------------------------------------
; do_virtual_address_unmapped(): ��������ַӳ��
; input:
;       esi - virtual address
; output:
;       0 - successful,  otherwise - error code
;-----------------------------------------------------------
do_virtual_address_unmapped:
        push ecx

        ;;
        ;; PT_BASE - PT_TOP �����ܱ����ӳ��
        ;; ����ӳ�䵽 PT_BASE - PT_TOP �����ھ�ʧ�ܷ���
        ;;
        cmp esi, [fs: SDA.PtBase]
        jb do_virtual_address_unmapped.next
        cmp esi, [fs: SDA.PtTop]
        ja do_virtual_address_unmapped.next 
        mov eax, UNMAPPING_ADDRESS_INVALID
        jmp do_virtual_address_unmapped.done
        
do_virtual_address_unmapped.next:    
        call get_pte_virtual_address
        mov ecx, [eax]
        test ecx, P
        jz do_virtual_address_unmapped.ok

        xor ecx, ecx
        xchg [eax], ecx
        invlpg [esi]                                    ; ˢ�� TLB

do_virtual_address_unmapped.ok:
        mov eax, UNMAPPED_SUCCESS        

do_virtual_address_unmapped.done:
        pop ecx
        ret
                



        

