		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL	EQU		0x20007B00 ; originally 0x20007500
SYS_EXIT		EQU		0x0		; address 20007B00
SYS_ALARM		EQU		0x1		; address 20007B04
SYS_SIGNAL		EQU		0x2		; address 20007B08
SYS_MEMCPY		EQU		0x3		; address 20007B0C
SYS_MALLOC		EQU		0x4		; address 20007B10
SYS_FREE		EQU		0x5		; address 20007B14


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Initialization
		EXPORT	_syscall_table_init
		
_syscall_table_init
	;save registers
	STMFD	SP!, {R1-R12,LR}
	LDR		R0, =SYSTEMCALLTBL
	
	; Initialize timer_start: 0x20007B04
	IMPORT _timer_start
	LDR		R2, =_timer_start
	STR		R2, [R0, #4]!
	
	; Initialize signal_handler: 0x20007B08
	IMPORT _signal_handler	
	LDR		R2, =_signal_handler
	STR		R2, [R0, #4]!
	
	; Initialize kalloc: 0x20007B0C
	IMPORT _kalloc
	LDR		R2, =_kalloc
	STR		R2, [R0, #4]!
		
	; Initialize kfree: 0x20007B0C
	IMPORT _kfree
	LDR		R2, =_kfree
	STR		R2, [R0, #4]!	
	
	; Retrieve registers
	LDMFD	SP!, {R1-R12, LR}
	; return
	MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
        EXPORT	_syscall_table_jump
_syscall_table_jump
	;Save registers
		STMFD	SP!, {R1-R12,LR}
		LDR		R11, =SYSTEMCALLTBL
		
		CMP		R7, #0x1
		BEQ		_run_timer_start
		
		CMP		R7, #0x2
		BEQ		_run_signal_handler
		
		CMP		R7, #0x4
		BEQ		_run_kalloc
		
		CMP		R7, #0x5
		BEQ		_run_kfree
		
		B		done
		
_run_timer_start
		ADD		R11, R11, #4
		LDR		R10, [R11]
		BLX		R10
		B		done
		
_run_signal_handler
		ADD		R11, R11, #8
		LDR		R10, [R11]
		BLX		R10
		B		done
		
_run_kalloc
		ADD		R11, R11, #12
		LDR		R10, [R11]
		BLX		R10
		B		done

_run_kfree
		ADD		R11, R11, #16
		LDR		R10, [R11]
		BLX		R10
		B		done
		
done
		;Retrieve registers
		LDMFD	SP!, {R1-R12, LR}
		;return
		MOV		pc, lr			
		
		END