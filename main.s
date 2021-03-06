;*******************************************************************
; main.s
; Author: Quinn Kleinfelter
; Date Created: 10/20/2020
; Last Modified: 10/20/2020
; Section Number: 001/003
; Instructor: Devinder Kaur / Suba Sah
; Lab number: 6
; Brief description of the program
;   If the switch is presses, the LED toggles at 8 Hz
; Hardware connections
;   PE1 is switch input  (1 means pressed, 0 means not pressed)
;   PE0 is LED output (1 activates external LED on protoboard) 
; Overall functionality is similar to Lab 5, with three changes:
;   1) Initialize SysTick with RELOAD 0x00FFFFFF 
;   2) Add a heartbeat to PF2 that toggles every time through loop 
;   3) Add debugging dump of input, output, and time
; Operation
;	1) Make PE0 an output and make PE1 an input. 
;	2) The system starts with the LED on (make PE0 =1). 
;   3) Wait about 62 ms
;   4) If the switch is pressed (PE1 is 1), then toggle the LED
;      once, else turn the LED on. 
;   5) Steps 3 and 4 are repeated over and over
;*******************************************************************

SWITCH                  EQU 0x40024004  ;PE0
LED                     EQU 0x40024008  ;PE1
SYSCTL_RCGCGPIO_R       EQU 0x400FE608
SYSCTL_RCGC2_GPIOE      EQU 0x00000010  ;port E Clock Gating Control
SYSCTL_RCGC2_GPIOF      EQU 0x00000020  ;port F Clock Gating Control
GPIO_PORTE_DATA_R       EQU 0x400243FC
GPIO_PORTE_DIR_R        EQU 0x40024400
GPIO_PORTE_AFSEL_R      EQU 0x40024420
GPIO_PORTE_PUR_R        EQU 0x40024510
GPIO_PORTE_DEN_R        EQU 0x4002451C
GPIO_PORTF_DATA_R       EQU 0x400253FC
GPIO_PORTF_DIR_R        EQU 0x40025400
GPIO_PORTF_AFSEL_R      EQU 0x40025420
GPIO_PORTF_PUR_R        EQU 0x40025510
GPIO_PORTF_DEN_R        EQU 0x4002551C
GPIO_PORTF_AMSEL_R      EQU 0x40025528
GPIO_PORTF_PCTL_R       EQU 0x4002552C
GPIO_PORTF_LOCK_R  	    EQU 0x40025520
GPIO_PORTF_CR_R         EQU 0x40025524
NVIC_ST_CTRL_R          EQU 0xE000E010
NVIC_ST_RELOAD_R        EQU 0xE000E014
NVIC_ST_CURRENT_R       EQU 0xE000E018
GPIO_PORTE_AMSEL_R      EQU 0x40024528
GPIO_PORTE_PCTL_R       EQU 0x4002452C
           
		   THUMB
           AREA    DATA, ALIGN=4
SIZE       EQU    50
;You MUST use these two buffers and two variables
;You MUST not change their names
DataBuffer SPACE  SIZE*4
TimeBuffer SPACE  SIZE*4
DataPt     SPACE  4
TimePt     SPACE  4
;These names MUST be exported
           EXPORT DataBuffer  
           EXPORT TimeBuffer  
           EXPORT DataPt [DATA,SIZE=4] 
           EXPORT TimePt [DATA,SIZE=4]
    
      ALIGN          
      AREA    |.text|, CODE, READONLY, ALIGN=2
      THUMB
      EXPORT  Start
      IMPORT  TExaS_Init

Start BL   TExaS_Init  ; running at 80 MHz, scope voltmeter on PD3
      ; initialize Port E
      ; initialize Port F
      ; initialize debugging dump, including SysTick

InitPortE
	; SYSCTL_RCGCGPIO_R = 0x10
	MOV R0, #0x30
	LDR R1, =SYSCTL_RCGCGPIO_R
	STR R0, [R1]
	
	LDR R0, [R1] ; Delay before we continue on

	; GPIO_PORTE_AMSEL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTE_AMSEL_R
	STR R0, [R1]
	
	; GPIO_PORTE_PCTL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTE_PCTL_R
	STR R0, [R1]
	
	; GPIO_PORTE_DIR_R = 0x01
	MOV R0, #0x01
	LDR R1, =GPIO_PORTE_DIR_R
	STR R0, [R1]
	
	; GPIO_PORTE_AFSEL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTE_AFSEL_R
	STR R0, [R1]
	
	; GPIO_PORTE_DEN_R = 0x03
	MOV R0, #0x03
	LDR R1, =GPIO_PORTE_DEN_R
	STR R0, [R1]
	
	; Start with the LED on
	MOV R0, #0x01
	LDR R1, =GPIO_PORTE_DATA_R
	STR R0, [R1]
	
InitPortF
	; SYSCTL_RCGCGPIO_R = 0x20
	;MOV R0, #0x20
	;LDR R1, =SYSCTL_RCGCGPIO_R
	;STR R0, [R1]
	
	LDR R0, [R1] ; Delay before we continue on
	
	; Before we write to the CR Register
	; we need to unlock the port F, using the
	; constant #0x4C4F434B, however we can't
	; write this constant directly to using MOV
	; so we use MOV and MOVT to add it into the register
	; in 2 parts, note: we must use the MOV command before
	; MOVT, otherwise the MOV command will overwrite the top
	; half of the register not unlocking the port
	; GPIO_PORT_F_LOCK_R = 0x4C4F434B
	MOV R0, #0x434B
	MOVT R0, #0x4C4F
	LDR R1, =GPIO_PORTF_LOCK_R
	STR R0, [R1]

	; GPIO_PORTF_CR_R = 0x04
	MOV R0, #0x04
	LDR R1, =GPIO_PORTF_CR_R
	STR R0, [R1]

	; GPIO_PORTF_AMSEL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTF_AMSEL_R
	STR R0, [R1]
	
	; GPIO_PORTF_PCTL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTF_PCTL_R
	STR R0, [R1]
	
	; GPIO_PORTF_DIR_R = 0x04
	MOV R0, #0x04
	LDR R1, =GPIO_PORTF_DIR_R
	STR R0, [R1]
	
	; GPIO_PORTF_AFSEL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTF_AFSEL_R
	STR R0, [R1]
	
	; GPIO_PORTF_PUR_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTF_PUR_R
	STR R0, [R1]
	
	; GPIO_PORTF_DEN_R = 0x04
	MOV R0, #0x04
	LDR R1, =GPIO_PORTF_DEN_R
	STR R0, [R1]
	BL Debug_Init
	

      CPSIE  I    ; TExaS voltmeter, scope runs on interrupts
loop  BL   Debug_Capture
    BL heartbeat
    ; Delay
    ;input PE1 test output PE0
	BL delay62MS ; We want to delay at the beginning now
	;Read the switch and test if the switch is pressed
	LDR R1, =GPIO_PORTE_DATA_R ; Load the address of Port E data into R1 so we can use it
	LDR R0, [R1] ; Load the value at R1 (the port data) into R0
	LSR R0, #1 ; Shift the port data to the right 1 bits since we only need pin 1
	CMP R0, #1 ; Compare the value to 1
	BEQ toggleLED ; If the value at R0 is 1, we want to toggle the LED
	; If we didn't branch off on the previous instruction,
	; then all we want to do is turn on the LED and then
	; restart the loop
	MOV R0, #0x01 
	LDR R1, =GPIO_PORTE_DATA_R
	; This will move 0x01 into the Port E data register
	; which will turn on the LED
	STR R0, [R1]
	; go to the beginning of the loop
    B loop
	
toggleLED ; Toggles the LED
	; Read our current Port F data because
	; we need to check if the LED is on or not
	LDR R1, =GPIO_PORTE_DATA_R ; Load the address of the Port F data into R1 so we can use it
	LDR R0, [R1] ; Load the value at R1 (the port data) into R0
	; Pin 1 is always on when we call toggleLED
	CMP R0, #0x02 ; Check if the value in R0 is 10, which indicates pin 0 is off and pin 1 is on, hence the LED is off
	BEQ turnOnLED ; if this value is 10, then that means our LED is currently off and we need to turn it on
	; Otherwise, just turn off the LED
	MOV R0, #0x00
	LDR R1, =GPIO_PORTE_DATA_R
	; This will move 0x00 into the Port E data register
	; which will turn off the LED
	STR R0, [R1]
	; And begin our loop again
	B loop
	
turnOnLED ; Turns the LED on, no matter what state it is in currently
	MOV R0, #0x01
	LDR R1, =GPIO_PORTE_DATA_R
	STR R0, [R1]
	; and begin our loop again
	B loop

delay62MS ; Subroutine that will delay our code by roughly 62ms
	; To delay the running by about 62ms we need to put
	; a large number into a register and slowly reduce it
	; so that we take up 62ms worth of cycles
	; the large number we've chosen is #0xCD000
	MOV R7, #0xD000
	MOVT R7, #0xC
delay
	SUBS R7, R7, #0x01 ; Subtract the current value of R12 by 1 and put it into R12
	BNE delay ; Compare R12 to 0 and if it is not 0, go back to delay
	BX LR ; Go back to the line after the delay62MS was called
	  B    loop

;------------Debug_Init------------
; Initializes the debugging instrument
; Note: push/pop an even number of registers so C compiler is happy
; Debug init basic stpes are as follows
; 1. Init both buffers to be entirely 0xFFFFFFFF
; 2. Init the pointers to the beginning of each buffer
; 3. Activate the SysTick timer
Debug_Init
	PUSH {R0-R4, LR} ; we only use r0-r3, but we push r4 because we also need to push LR and we should push an even number of registers
; Step 1 part 1
initFirstBuf
	LDR R0, =DataBuffer ; Load the address of the buffer into R0
	MOV R1, #0 ; offset = 0
	MOV R2, #0xFFFFFFFF ; the value we want to init to
initLoop
	STR R2, [R0, R1] ; put r2 into the address stored by R0 + R1
	ADD R1, #4 ; add 4 to offset to get to the next address
	CMP R1, #200 ; check if our offset has reached 200 (4 * SIZE)
	BLO initLoop ; if it hasn't reached it yet, keep going

; Step 1 part 2
initSecondBuf
	LDR R0, =TimeBuffer ; Load the address of the buffer into R0
	MOV R1, #0 ; offset = 0
	MOV R2, #0xFFFFFFFF ; the value we want to init to
initLoop2
	STR R2, [R0, R1] ; put r2 into the address stored by R0 + R1
	ADD R1, #4 ; add 4 to offset to get to the next address
	CMP R1, #200 ; check if our offset has reached 200 (4 * SIZE)
	BLO initLoop2 ; if it hasn't reached it yet, keep going
	
	; Step 2 part 1
	LDR R2, =DataBuffer
	LDR R3, =DataPt
	STR R2, [R3] ;Point DataPt to DataBuffer
	
	; Step 2 part 2
    LDR R0, =TimeBuffer
    LDR R1, =TimePt
    STR R0, [R1] ;Point TimePt to TimeBuffer
	

	
	; Activate the SysTick timer
	BL SysTick_Init

	POP {R0-R4, PC} ; pop all of our stuff back in from before
    BX LR

;------------Debug_Capture------------
; Dump Port E and time into buffers
; Note: push/pop an even number of registers so C compiler is happy
; Debug capture steps are as follows
; 1. Save any registers needed
; 2. Return immediately if the buffers are full (pointer > start + 4 * SIZE)
; 3. Read Port E and the SysTick timer (NVIC_ST_CURRENT_R)
; 4. Mask capturing just bits 1,0 of Port E data
; 5. Shift the Port E data bit 1 into bit 4, leave bit 0 in bit 0
; 6. Dump this information into DataBuffer using the pointer DataPt
; 7. Increment DataPt to next address.
; 8. Dump time into TimeBuffer using the pointer TimePt
; 9. Increment TimePt to next address
; 10. Restore any registers saved and return
; ESTIMATE INTRUSIVENESS:
; Debug Capture contains 43 instructions
; 43 * 2 * 12.5ns = 1075ns
; Total delay 62ms + 0.001075ms = 62.001075ms
; 0.001075ms / 62.001075ms = 1.733 * 10^-5 * 100 = 0.001733% intrusiveness
; Therefore the intrusiveness is negligible
Debug_Capture
	; Step 1 - Save registers
	PUSH {R0-R12, LR} ; push em all for now, we can reduce this later if needed

	; Step 2 - return if buffers full
	LDR R1, =DataPt ; Load the address of the data pointer into R0
	LDR R0, [R1]
	LDR R1, =DataBuffer ; Load the address of the beginning of the data buffer into R1
	LDR R2, =SIZE ; Move the Size value into R2
	MOV R3, #4 ; set r3 to 4 for multiplying
	MUL R2, R3 ; Multiply R2 by 4 to get the total offset for where the last pointer is
	ADD R1, R2 ; Add the data buffer beginning address with the total offset
	CMP R0, R1 ; Compare the address of the data pointer with the address at the end of the buffer
	BHS done ; If R0 is greater than R1 than we want to return immediately
	
	LDR R1, =TimePt ; Load the address of the time pointer into R0
	LDR R0, [R1]
	LDR R1, =TimeBuffer ; Load the address of the beginning of the time buffer into R1
	LDR R2, =SIZE ; Move the Size value into R2
	MOV R3, #4 ; set r3 to 4 for multiplying
	MUL R2, R3 ; Multiply R2 by 4 to get the total offset for where the last pointer is
	ADD R1, R2 ; Add the time buffer beginning address with the total offset
	CMP R0, R1 ; Compare the address of the time pointer with the address at the end of the buffer
	BHS done ; If R0 is greater than R1 than we want to return immediately
	
	; Step 3 - read port e and systick (into r0 and r2 respectively)
	LDR R1, =GPIO_PORTE_DATA_R ; Load the address of the Port E data into R1 so we can use it
	LDR R0, [R1] ; Load the value at R1 (the port data) into R0
	
	LDR R3, =NVIC_ST_CURRENT_R ; Load the address of the SysTick timer data into R3 so we can use it
	LDR R2, [R3] ; Load the value at R3 (the systick data) into R2
	
	; Step 4 - mask to only get bits 1,0 from port e
	AND R0, #0x03 ; We want R0 to only worry about bits 1,0
	
	; Step 5 - shift data bit 1 into bit 4 in port e
	LSL R4, R0, #3 ; In R4 put R0 shifted left by 3 bits (we need bit 1 to move to bit 4)
	MOV R5, #0xFFEF
	MOVT R5, #0xFFFF
	BIC R4, R5 ; clear everything but bit 4 in R4
	MOV R5, #0xFFFE
	MOVT R5, #0xFFFF
	BIC R0, R5 ; clear everything but bit 0 in R5
	ORR R0, R4 ; OR R0 and R4 together to get the values in the correct places
	
	; Step 6 - dump into databuffer using datapt
	LDR R1, =DataPt ; Loads the address of the memory for our pointer into R1
	LDR R3, [R1] ; Loads the value DataPt points to into R3
	STR R0, [R3] ; Stores R0 (the port e data) into the current address of the data pointer
	
	; Step 7 - increment datapt
	ADD R3, #4 ; Increments pointer by 4
	STR R3, [R1] ; Stores the pointer back into the DataPt
	
	; Step 8 - dump time into timebuffer
	LDR R1, =TimePt ; Loads the address of the memory for our pointer into R1
	LDR R3, [R1] ; Loads the value TimePt points to into R3
	STR R2, [R3] ; Stores R2 (the systick data) into R3
	
	; Step 9 - increment timept
	ADD R3, #4 ; Increments pointer by 4
	STR R3, [R1] ; Stores the pointer back into the TimePt
	
	; Step 10 - restore and return
done	POP {R0-R12, PC} ; Pop everything back
    BX LR
	  
heartbeat
	PUSH {R0-R12, LR}
	; Read our current Port F data because
	; we need to check if the LED is on or not
	LDR R1, =GPIO_PORTF_DATA_R ; Load the address of the Port F data into R1 so we can use it
	LDR R0, [R1] ; Load the value at R1 (the port data) into R0
	; Pin 1 is always on when we call toggleLED
	CMP R0, #0x00 ; Check if the value in R0 is 0, which indicates pin 2 is on, hence the LED is off
	BEQ turnOnLEDPortF ; if this value is 10, then that means our LED is currently off and we need to turn it on
	; Otherwise, just turn off the LED
	MOV R0, #0x00
	LDR R1, =GPIO_PORTF_DATA_R
	; This will move 0x00 into the Port E data register
	; which will turn off the LED
	STR R0, [R1]
	POP {R0-R12, PC}
	BX LR

turnOnLEDPortF ; Turns the LED on, no matter what state it is in currently
	MOV R0, #0x04
	LDR R1, =GPIO_PORTF_DATA_R
	STR R0, [R1]
	POP {R0-R12, PC}
	BX LR
	
; copied from the book
SysTick_Init
    LDR R1, =NVIC_ST_CTRL_R
    MOV R0, #0 ; disable SysTick during setup
    STR R0, [R1]
    LDR R1, =NVIC_ST_RELOAD_R ; R1 = &NVIC_ST_RELOAD_R
    LDR R0, =0x00FFFFFF; ; maximum reload value
    STR R0, [R1] ; [R1] = R0 = NVIC_ST_RELOAD_M
    LDR R1, =NVIC_ST_CURRENT_R ; R1 = &NVIC_ST_CURRENT_R
    MOV R0, #0 ; any write to current clears it
    STR R0, [R1] ; clear counter
    LDR R1, =NVIC_ST_CTRL_R ; enable SysTick with core clock
    MOV R0, #0x05
    STR R0, [R1] ; ENABLE and CLK_SRC bits set
    BX LR


    ALIGN      ; make sure the end of this section is aligned
    END        ; end of file
        