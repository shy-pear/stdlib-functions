		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Timer Definition
STCTRL		EQU		0xE000E010		; SysTick Control and Status Register
STRELOAD	EQU		0xE000E014		; SysTick Reload Value Register
STCURRENT	EQU		0xE000E018		; SysTick Current Value Register
	
STCTRL_STOP	EQU		0x00000004		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 0, Bit 0 (ENABLE) = 0
STCTRL_GO	EQU		0x00000007		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 1, Bit 0 (ENABLE) = 1
STRELOAD_MX	EQU		0x00FFFFFF		; MAX Value = 1/16MHz * 16M = 1 second
STCURR_CLR	EQU		0x00000000		; Clear STCURRENT and STCTRL.COUNT	
SIGALRM		EQU		14			; sig alarm

; System Variables
SECOND_LEFT	EQU		0x20007B80		; Secounds left for alarm( )
USR_HANDLER     EQU		0x20007B84		; Address of a user-given signal handler function	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer initialization
; void timer_init( )
		EXPORT		_timer_init
_timer_init
		;Save registers
		STMFD	SP!, {R1-R12, LR}
		;store stctrl_stop value into control and status register
		LDR		R0, =STCTRL
		MOV		R1, #STCTRL_STOP
		STR 	R1, [R0]
		
		;store streload_mx value into reload value register
		LDR		R0, =STRELOAD
		MOV		R1, #STRELOAD_MX
		STR		R1, [R0]
		
		;Retrieve registers
		LDMFD	SP!, {R1-R12, LR}
		MOV		pc, lr		; return to Reset_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer start
; int timer_start( int seconds )
		EXPORT		_timer_start
_timer_start
		; Save registers
		STMFD	SP!, {R1-R12, LR}
		
		CMP		R0, #0
		BLE		_timer_start_done
		
		LDR		R1, =SECOND_LEFT
		LDR		R2, [R1]
		STR 	R0, [R1]
		
		;store stctrl_go in stctrl
		LDR		R3, =STCTRL
		MOV		R4, #STCTRL_GO
		STR		R4, [R3]
		
		;sore strcurr_clr in stcurrent
		LDR		R3, =STCURRENT
		MOV		R4, #STCURR_CLR
		STR		R4, [R3]
		
_timer_start_done
		MOV		R0, R2
		;Retrieve registers
		LDMFD	sp!, {r1-r12, lr}
		;return
		MOV		pc, lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void timer_update( )
		EXPORT		_timer_update
_timer_update
		LDR		R3, =SECOND_LEFT
		LDR		R0, [R3]
		SUB		R0, R0, #1
		STR		R0, [R3]
		
		CMP		R0, #0
		BNE		_timer_update_done
		
		LDR		R3, =STCTRL
		MOV		R4, #STCTRL_STOP
		STR		R4, [R3]
		
		; change to usr thread
		MOVS	R0, #3
		MSR		CONTROL, R0
		; branch to user function
		LDR 	R3, =USR_HANDLER
		LDR		R4, [R3]
		BX		R4
	
_timer_update_done
		;return
		MOV		pc, lr		


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void* signal_handler( int signum, void* handler )
	    EXPORT	_signal_handler
_signal_handler
		;Save registers
		STMFD	SP!, {R1-R12, LR}
		
		CMP		R0, #14
		BNE		_signal_handler_done

		LDR		R3, =USR_HANDLER
		LDR		R2, [R3]
		STR		R1, [R3]
	
_signal_handler_done
		MOV		R0, R2
		;Retrieve registers
		LDMFD	SP!, {R1-R12, LR}
		;return
		MOV		pc, lr
		
		END		
