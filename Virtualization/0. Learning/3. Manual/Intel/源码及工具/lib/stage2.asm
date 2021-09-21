;*************************************************
; stage2.asm                                     *
; Copyright (c) 2009-2013 ��־                   *
; All rights reserved.                           *
;*************************************************
   
   
   


;----------------------------------------------------------------------------------------------
; init_global_page(): ��ʼ������ PAE-paging ģʽ��ҳת����ṹ
; input:
;       none
; output:
;       none
; 
; ϵͳҳ��ṹ:
;       * 0xc0000000-0xc07fffff����8M��ӳ�䵽����ҳ�� 0x200000-0x9fffff �ϣ�ʹ�� 4K ҳ��
;
; ��ʼ����������:
;       1) 0x7000-0x1ffff �ֱ�ӳ�䵽 0x8000-0x1ffff ����ҳ�棬����һ�������
;       2) 0xb8000 - 0xb9fff ��ӳ�䵽��0xb8000-0xb9fff �����ַ��ʹ�� 4K ҳ�棬���� VGA ��ʾ����
;       3) 0x80000000-0x8000ffff����64K��ӳ�䵽�����ַ 0x100000-0x10ffff �ϣ�����ϵͳ���ݽṹ        
;       4) 0x400000-0x400fff ӳ�䵽 1000000h page frame ʹ�� 4K ҳ�棬���� DS store ����
;       5) 0x600000-0x7fffff ӳ�䵽 0FEC00000h ����ҳ���ϣ�ʹ�� 2M ҳ�棬���� LPC ����������I/O APIC��
;       6) 0x800000-0x9fffff ӳ�䵽 0FEE00000h �����ַ�ϣ�ʹ�� 2M ҳ�棬���� local APIC ����
;       7) 0xb0000000 ��ʼӳ�䵽�����ַ 0x1100000 ��ʼ��ʹ�� 4K ҳ�棬���� VMX ���ݿռ�
;---------------------------------------------------------------------------------------------
init_global_page:
        push ecx

        ;;
        ;; 0x7000-0x9000 �ֱ�ӳ�䵽 0x7000-0x9000 ����ҳ��, ʹ�� 4K ҳ��               
        ;;
        mov esi, 7000h
        mov edi, 7000h
        mov ecx, (10000h - 7000h) / 1000h        
        mov eax, PHY_ADDR | US | RW | P
        call do_virtual_address_mapping_n


%ifdef GUEST_ENABLE        
        mov esi, GUEST_BOOT_SEGMENT
        mov edi, GUEST_BOOT_SEGMENT
        mov eax, PHY_ADDR | US | RW | P
        call do_virtual_address_mapping
        
        mov esi, GUEST_KERNEL_SEGMENT
        mov edi, GUEST_KERNEL_SEGMENT
        mov eax, PHY_ADDR | US | RW | P
        mov ecx, [GUEST_KERNEL_SEGMENT]        
        add ecx, 0FFFh
        shr ecx, 12
        call do_virtual_address_mapping_n
%endif        
        
        ;;
        ;; ӳ�� protected ģ������ʹ�� 4K ҳ
        ;;
        mov esi, PROTECTED_SEGMENT
        mov edi, PROTECTED_SEGMENT
        mov eax, PHY_ADDR | US | RW | P
        
%ifdef __STAGE2
        mov ecx, (PROTECTED_LENGTH + 0FFFh) / 1000h
%endif        
        call do_virtual_address_mapping_n
        
        ;;
        ;; 0xb8000 - 0xb9fff ��ӳ�䵽��0xb8000-0xb9fff �����ַ��ʹ�� 4K ҳ��
        ;;
        mov esi, 0B8000h
        mov edi, 0B8000h
        mov eax, XD | PHY_ADDR | US | RW | P
        call do_virtual_address_mapping
        mov esi, 0B9000h
        mov edi, 0B9000h
        mov eax, XD | PHY_ADDR | US | RW | P
        call do_virtual_address_mapping

        ;;
        ;; ӳ������ PCB ��
        ;;
        mov esi, PCB_BASE
        mov edi, PCB_PHYSICAL_POOL
        mov ecx, PCB_POOL_SIZE / 1000h
        mov eax, PHY_ADDR | XD | RW | P
        call do_virtual_address_mapping_n

        ;;
        ;; ӳ�� System Data Area ����
        ;;
        mov esi, [fs: SDA.Base]                                 ; SDA virtual address
        mov edi, [fs: SDA.PhysicalBase]                         ; SDA physical address
        mov ecx, [fs: SDA.Size]                                 ; SDA size
        add ecx, 0FFFh
        shr ecx, 12                                             
        mov eax, XD | PHY_ADDR | RW | P
        call do_virtual_address_mapping_n

       
        ;;
        ;; ӳ�� System service routine table ����4K��
        ;;
        mov esi, [fs: SRT.Base]
        mov edi, [fs: SRT.PhysicalBase]
        mov eax, XD | PHY_ADDR | RW | P
        call do_virtual_address_mapping
        
        
        ;;
        ;; ӳ�� stack
        ;;
        mov esi, KERNEL_STACK_BASE
        mov edi, KERNEL_STACK_PHYSICAL_BASE
        mov ecx, KERNEL_STACK_SIZE/1000h
        mov eax, PHY_ADDR | XD | RW | P
        call do_virtual_address_mapping_n
        mov esi, USER_STACK_BASE
        mov edi, USER_STACK_PHYSICAL_BASE
        mov ecx, USER_STACK_SIZE/1000h
        mov eax, PHY_ADDR | XD | US | RW | P
        call do_virtual_address_mapping_n

        ;;
        ;; ӳ�� pool
        ;;
        mov esi, KERNEL_POOL_BASE
        mov edi, KERNEL_POOL_PHYSICAL_BASE
        mov ecx, KERNEL_POOL_SIZE/1000h 
        mov eax, PHY_ADDR | RW | P
        call do_virtual_address_mapping_n
        mov esi, USER_POOL_BASE
        mov edi, USER_POOL_PHYSICAL_BASE
        mov ecx, USER_POOL_SIZE/1000h
        mov eax, PHY_ADDR | US | RW | P
        call do_virtual_address_mapping_n

        
        ;;
        ;; ӳ�� VM domain pool
        ;;
        mov esi, DOMAIN_BASE
        mov edi, DOMAIN_PHYSICAL_BASE
        mov ecx, DOMAIN_POOL_SIZE/1000h
        mov eax, PHY_ADDR | US | RW | P
        call do_virtual_address_mapping_n

       
        ;;
        ;; 0x400000-0x400fff ӳ�䵽 1000000h page frame ʹ�� 4K ҳ��
        ;;
        mov esi, 400000h
        mov edi, 1000000h
        mov eax, XD | PHY_ADDR | RW | P
        call do_virtual_address_mapping
        
        ;;              
        ;; 0x600000-0x600fff ӳ�䵽 0FEC00000h �����ַ�ϣ�ʹ�� 4K ҳ��
        ;;
        mov esi, IOAPIC_BASE
        mov edi, 0FEC00000h
        mov eax, XD | PHY_ADDR | PCD | PWT | RW | P
        call do_virtual_address_mapping
        
        ;;
        ;; 0x800000-0x800fff ӳ�䵽 0FEE00000h �����ַ�ϣ�ʹ�� 4k ҳ��
        ;;
        mov esi, LAPIC_BASE
        mov edi, 0FEE00000h
        mov eax, XD | PHY_ADDR | PCD | PWT | RW | P
        call do_virtual_address_mapping
           
        
        ;;
        ;; 0xb0000000 ��ʼӳ�䵽�����ַ 0x1100000 ��ʼ��ʹ�� 4K ҳ��
        ;;
        mov esi, VMX_REGION_VIRTUAL_BASE                        ; VMXON region virtual address
        mov edi, VMX_REGION_PHYSICAL_BASE                       ; VMXON region physical address
        mov eax, XD | PHY_ADDR | RW | P
        call do_virtual_address_mapping
        
        pop ecx
        ret
        
        

;-----------------------------------------------------------------------
; init_global_environment()
; input:
;       none
; output:
;       none
; ������
;       1) ��ʼ�� stage2 ����
;-----------------------------------------------------------------------
init_global_environment:
        call init_pae_page
        call init_global_page

        ;; ���� IDT pointer
        mov DWORD [fs: SDA.IdtBase], SDA_BASE+SDA.Idt
        mov DWORD [fs: SDA.IdtBase+4], 0FFFFF800h
        mov WORD [fs: SDA.IdtLimit], 256*16-1
        mov DWORD [fs: SDA.IdtTop], SDA_BASE+SDA.Idt+0FFFh
        mov DWORD [fs: SDA.IdtTop+4], 0FFFFF800h        
        ret

        
;-----------------------------------------------------------------------
; enter_stage2()
; input:
;       none
; output:
;       none
; ������
;       1) ���� stage2 �׶����л���
;-----------------------------------------------------------------------
enter_stage2:
        pop edi
        call init_pae_ppt
        mov esi, [gs: PCB.GdtPointer]
        mov eax, [gs: PCB.PptPhysicalBase]
        mov cr3, eax
        mov eax, CR0_PG | CR0_PE | CR0_NE | CR0_ET
        mov cr0, eax
        lgdt [esi]
        mov ax, FsSelector
        mov fs, ax
        mov ax, GsSelector
        mov gs, ax
        mov ax, TssSelector32
        ltr ax
        lidt [fs: SDA.IdtPointer]
        mov esp, [gs: PCB.KernelStack]
        jmp edi
        


;-----------------------------------------------------
; wait_for_stage2_done()
; input:
;       none
; output:
;       none
; ������
;       1) ���� INIT-SIPI-SIPI ��Ϣ��� AP
;       2) �ȴ� AP ��ɵ�2�׶ι���
;-----------------------------------------------------
wait_for_ap_stage2_done:             
        ;;
        ;; ���ŵ�2�׶� AP Lock
        ;;
        xor eax, eax
        mov ebx, [fs: SDA.Stage2LockPointer]
        xchg [ebx], eax
        
        ;;
        ;; BSP ����ɹ���, ����ֵΪ 1 
        ;;
        mov DWORD [fs: SDA.ApInitDoneCount], 1

        ;;
        ;; �ȴ� AP ��� stage2 ����:
        ;; ��鴦�������� ApInitDoneCount �Ƿ���� LocalProcessorCount ֵ
        ;; 1)�ǣ����� AP ��� stage2 ����
        ;; 2)�񣬼����ȴ�
        ;;
wait_for_ap_stage2_done.@0:        
        xor eax, eax
        lock xadd [fs: SDA.ApInitDoneCount], eax
        cmp eax, CPU_COUNT_MAX
        jae wait_for_ap_stage2_done.ok 
        cmp eax, [gs: PCB.LogicalProcessorCount]
        jae wait_for_ap_stage2_done.ok
        pause
        jmp wait_for_ap_stage2_done.@0

wait_for_ap_stage2_done.ok:
        ;;
        ;;  AP ���� stage2 ״̬
        ;;
        mov DWORD [fs: SDA.ApStage], 2
        ret



                
;-----------------------------------------------------
; put_processor_to_vmx()
; input:
;       none
; output:
;       none
; ������
;       1) �����д��������� VMX root ״̬
;-----------------------------------------------------                
put_processor_to_vmx:
        push ecx

        ;;
        ;; BSP ���� VMX ����
        ;;
        call vmx_operation_enter
        
        ;;
        ;; ʣ��� APs ���� VMX ����
        ;;
        mov ecx, 1
put_processor_to_vmx.@0:
        mov esi, ecx
        mov edi, vmx_operation_enter
        call dispatch_to_processor_with_waitting
        ;;
        ;; �� Status Code ����Ƿ�ɹ�
        ;;
        mov eax, [fs: SDA.LastStatusCode]
        cmp eax, STATUS_SUCCESS
        jne put_processor_to_vmx.done

        inc ecx
        cmp ecx, [fs: SDA.ProcessorCount]
        jb put_processor_to_vmx.@0
        
put_processor_to_vmx.done:        
        pop ecx
        ret

