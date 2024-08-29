		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      	; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512			; 2^9 = 512 entries
	
INVALID		EQU		-1			; an invalid id
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
		EXPORT	_heap_init
_heap_init
		;save registers
		STMFD	SP!, {R1-R12,LR}
		
		LDR		R0, =MAX_SIZE
		LDR		R1, =MCB_TOP
		; store max_size at top
		STR		R0 , [R1], #4
		
		MOV 	R4, #0x0
		ADD		R3, R1, #0x400
		
loop	CMP		R1, R3
		BGT		heap_init_done
		STR		R4, [R1]
		STR		R4, [R1, #1]
		
		ADD		R1, R1, #2
		B		loop
heap_init_done
		;Retrieve registers
		LDMFD	SP!, {R1-R12, LR}
		;return
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc
		;Save registers
		STMFD	SP!, {R1-R12,LR}
		MOV		R3, R0 ; R3 = size
		
		LDR		R1, =MCB_TOP
		LDR		R2, =MCB_BOT
		
		BL		_ralloc		
		
		;Retrieve registers
		LDMFD	sp!, {r1-r12, lr}
		;return
		MOV		pc, lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_ralloc
		STMFD	SP!, {R1-R12,LR}
		
		; R2 = mcb bottom (right), R1 = mcb top (left)
		SUB 	R11, R2, R1
		
		; R10 = mcb entire size
		LDR 	R10, =MCB_ENT_SZ
		; R4 = entire
		ADD		R4, R11, R10
		; R5 = half
		ASR		R5, R4, #1
		; R6 = midpoint
		ADD		R6, R1, R5
		; R7 = heap_addr
		MOV		R7, #0x0
		
		; R8 = act_entire_size
		LSL		R8, R4, #4
		; R9 = act_half_size
		LSL		R9, R5, #4
		
		;compare size to act_half_size
		CMP		R3, R9
		BGT		ralloc_3
		
		;recursive call to ralloc
		SUB		R2, R6, R10
		BL		_ralloc
	
		MOV		R7, R0
		CMP		R7, #0 ;if heap address is 0
		BNE		ralloc_1
		
		SUB		R12, R4, R10
		ADD		R12, R12, R1
		MOV		R2, R12
		MOV		R1, R6
		
		;recursive call to ralloc
		BL		_ralloc
		MOV		R7, R0
		B		ralloc_done
		
ralloc_1
		LDR		R11, [R6]
		AND		R11, R11, #0x01
		CMP		R11, #0
		BNE 	ralloc_2
		STR		R9, [R6]
		
ralloc_2
		MOV		R7, R0
		B		ralloc_done
		
ralloc_3
		LDR		R11, [R1]
		AND		R11, R11, #1
		
		CMP		R11, #0
		BEQ		ralloc_4
		
		MOV		R7, #0
		B		ralloc_done
		
ralloc_4
		LDR		R11, [R1]
		CMP		R11, R8
		BGE		ralloc_5   
		
		MOV		R7, #0
		B		ralloc_done
		
ralloc_5
		LDR		R11, [R1]
		MOV		R12, R8
		
		ORR		R12, R12, #0x1
		STR		R12, [R1]
		
		LDR		R12, =MCB_TOP
		SUB		R11, R1, R12
		LSL		R11, R11, #4
		
		LDR		R12, =HEAP_TOP
		ADD		R7, R11, R12
		
		
ralloc_done
		MOV		R0, R7
		;Retrieve registers
		LDMFD	SP!, {R1-R12, LR}
		;return
		MOV		pc, lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
		EXPORT	_kfree
_kfree
		;Save registers
		STMFD	SP!, {R1-R12,LR}
		
		LDR		R1, =HEAP_TOP
		LDR		R2, =MCB_TOP
		
		SUB		R3, R0, R1
		ASR		R3, R3, #4
		
		MOV		R5, R0
		ADD		R0, R2, R3
		
		BL		_rfree
		
		MOV		R0, R5
		
		;Retrieve registers
		LDMFD	SP!, {R1-R12, LR}
		;return
		MOV		pc, lr					
_rfree
		;Save registers
		STMFD	SP!, {R1-R12,LR}
		
		; load mcb contents
		LDR		R1, [R0]
		; mcb index
		LDR		R5, =MCB_TOP
		SUB		R2, R0, R5
		; divide mcb contents by 2^4
		ASR		R1, R1, #4
		MOV		R3, R1
		; multiple mcb contents by 2^4
		LSL		R1, R1, #4
		MOV 	R4, R1
		STR		R1, [R0]
		
		SDIV	R6, R2, R3
		MOV		R12, #2
		
		SDIV	R11, R6, R12
		MLS		R7, R12, R11, R6
		
		CMP		R7, #0
		BNE		rfree_2
		ADD		R6, R0, R3
		
		LDR		R7, =MCB_BOT
		CMP		R6, R7
		BLT		rfree_1	
		
		MOV		R9, #0
		B		rfree_done

rfree_1
		LDR		R10, [R6]	
		AND		R12, R10, #0x01 
		CMP		R12, #0
		BNE		rfree_4
		
		ASR		R10, R10, #5
		LSL		R10, R10, #5
		CMP		R10, R4
		
		BNE		rfree_4
		MOV		R11, #0
		STR		R11, [R6]
		LSL		R4, R4, #1
		STR		R4, [R0]
		
		;recursive call to rfree
		BL		_rfree
		MOV		R9, R0
		B		rfree_done

rfree_2
		SUB		R6, R0, R3
		LDR		R7, =MCB_TOP
		CMP		R6, R7
		BGE		rfree_3
		MOV		R9, #0
		B		rfree_done

rfree_3
		LDR		R10, [R6]
		AND		R12, R10, #0x01 
		CMP		R12, #0
		BNE		rfree_4
		
		ASR		R10, R10, #5
		LSL		R10, R10, #5
		CMP		R10, R4
		BNE		rfree_4
		
		MOV		R11, #0
		STR		R11, [R0]
		LSL		R4, R4, #1
		STR		R4, [R6]
		MOV		R0, R6
		
		;recursive call to rfree
		BL		_rfree
		
		MOV		R9, R0
		B		rfree_done

rfree_4
		MOV		R9, R0

rfree_done
		MOV		R0, R9
		; Retrieve registers
		LDMFD	SP!, {R1-R12, LR}
		; return
		MOV		pc, lr
		
		END
