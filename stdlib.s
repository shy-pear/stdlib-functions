		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero
		; R0 = S
		; R1 = n
		
		; save registers
		PUSH	{R1-R12, LR}
loop	
		CMP		R1, #0 ; check if any more bytes left
		BEQ		end_loop
		
		MOV		R9, #0
		STRB	R9, [R0], #1
		SUB		R1, R1, #1
		B		loop
end_loop
		POP		{R1-R12, LR}
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   	dest 	- pointer to the buffer to copy to
;	src	- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest
		EXPORT	_strncpy
_strncpy
		; R0 = dest
		; R1 = src
		; R2 = size
		
		PUSH	{R1-R12, LR}
		
loop_copy
		CMP		R2, #0 ; check if size = 0
		BEQ		end_loop_copy
		
		LDRB	R9, [R1], #1
		STRB	R9, [R0], #1
		SUB		R2, R2, #1
		B		loop_copy
end_loop_copy
		POP		{R1-R12,LR}
		MOV		pc, lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   	void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc
		STMFD	SP!, {R1-R12,LR}
		; malloc R7 value: 4
		MOV		R7, #0x04
	    SVC     #0x0
		
		; resume registers
		LDMFD	SP!, {R1-R12, LR}
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   	none
		EXPORT	_free
_free
		; save registers
		STMFD	SP!, {R1-R12,LR}
		
		; free R7 value: 5
		MOV		R7, #0x05
        SVC     #0x0
		
		; resume registers
		LDMFD	SP!, {R1-R12, LR}
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unsigned int _alarm( unsigned int seconds )
; Parameters
;   seconds - seconds when a SIGALRM signal should be delivered to the calling program	
; Return value
;   unsigned int - the number of seconds remaining until any previously scheduled alarm
;                  was due to be delivered, or zero if there was no previously schedul-
;                  ed alarm. 
		EXPORT	_alarm
_alarm
		; save registers
		STMFD	SP!, {R1-R12,LR}
		
		; alarm R7 value: 1
		MOV		R7, #0x01
        	SVC     #0x0
			
		; resume registers
		LDMFD	sp!, {r1-r12, lr}
		MOV		pc, lr		
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _signal( int signum, void *handler )
; Parameters
;   signum - a signal number (assumed to be 14 = SIGALRM)
;   handler - a pointer to a user-level signal handling function
; Return value
;   void*   - a pointer to the user-level signal handling function previously handled
;             (the same as the 2nd parameter in this project)
		EXPORT	_signal
_signal
		; save registers
		STMFD	SP!, {R1-R12,LR}
		
		; signal R7 value: 2
		MOV		R7, #0x02
        SVC     #0x0
		
		; resume registers
		LDMFD	SP!, {R1-R12, LR}
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		END			
