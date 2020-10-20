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
	MOV R0, #0x10
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
	
; copied from SysTick_4C123asm
SysTick_Init
    ; disable SysTick during setup
    LDR R1, =NVIC_ST_CTRL_R         ; R1 = &NVIC_ST_CTRL_R
    MOV R0, #0                      ; R0 = 0
    STR R0, [R1]                    ; [R1] = R0 = 0
    ; maximum reload value
    LDR R1, =NVIC_ST_RELOAD_R       ; R1 = &NVIC_ST_RELOAD_R
    LDR R0, =NVIC_ST_RELOAD_M;      ; R0 = NVIC_ST_RELOAD_M
    STR R0, [R1]                    ; [R1] = R0 = NVIC_ST_RELOAD_M
    ; any write to current clears it
    LDR R1, =NVIC_ST_CURRENT_R      ; R1 = &NVIC_ST_CURRENT_R
    MOV R0, #0                      ; R0 = 0
    STR R0, [R1]                    ; [R1] = R0 = 0
    ; enable SysTick with core clock
    LDR R1, =NVIC_ST_CTRL_R         ; R1 = &NVIC_ST_CTRL_R
                                    ; R0 = ENABLE and CLK_SRC bits set
    MOV R0, #(NVIC_ST_CTRL_ENABLE+NVIC_ST_CTRL_CLK_SRC)
    STR R0, [R1]                    ; [R1] = R0 = (NVIC_ST_CTRL_ENABLE|NVIC_ST_CTRL_CLK_SRC)
    BX  LR                          ; return
	
main
	; Nothing needs to be initialized here
	; because it will run through all of InitPortE first

loop  
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
	; Then we need to delay by 62ms
	BL delay62MS
	; And begin our loop again
	B loop
	
turnOnLED ; Turns the LED on, no matter what state it is in currently
	MOV R0, #0x01
	LDR R1, =GPIO_PORTE_DATA_R
	STR R0, [R1]
	; Again, we need to delay 62ms
	BL delay62MS
	; and begin our loop again
	B loop

delay62MS ; Subroutine that will delay our code by roughly 62ms
	; To delay the running by about 62ms we need to put
	; a large number into a register and slowly reduce it
	; so that we take up 62ms worth of cycles
	; the large number we've chosen is #0xB5000
	MOV R7, #0x5000
	MOVT R7, #0xB
delay
	SUBS R7, R7, #0x01 ; Subtract the current value of R12 by 1 and put it into R12
	BNE delay ; Compare R12 to 0 and if it is not 0, go back to delay
	BX LR ; Go back to the line after the delay62MS was called

      CPSIE  I    ; TExaS voltmeter, scope runs on interrupts
debugloop  BL   Debug_Capture
      ;heartbeat
      ; Delay
      ;input PE1 test output PE0
	  B    loop

;------------Debug_Init------------
; Initializes the debugging instrument
; Note: push/pop an even number of registers so C compiler is happy
Debug_Init
      
; init SysTick

      BX LR

;------------Debug_Capture------------
; Dump Port E and time into buffers
; Note: push/pop an even number of registers so C compiler is happy
Debug_Capture

      BX LR


    ALIGN      ; make sure the end of this section is aligned
    END        ; end of file
        