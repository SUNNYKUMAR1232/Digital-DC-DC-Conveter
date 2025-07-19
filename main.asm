;====================================================================
; Frequency: 971 Hz
; Project: Design DC-DC Converter Using 8051 Microcontroller
; Function: Converts 5V to 3.3V
; Created: Thu Nov 14, 2024
; Processor: AT89C52
; Compiler: ASEM-51 (Proteus)
;====================================================================

$NOMOD51
$INCLUDE (80C52.MCU)

;====================================================================
; DEFINITIONS
;====================================================================
SIG         EQU P3.7         ; Output signal
DATA_LINE   EQU P2           ; Data Port (DB0-DB7 on Port 2)
RS          EQU P1.0         ; RS of LCD
RW          EQU P1.1         ; RW of LCD
EN          EQU P1.2         ; Enable signal for LCD

;====================================================================
; VARIABLES
;====================================================================
T0_H        EQU 30H          ; Timer 0 High byte
T0_L        EQU 31H          ; Timer 0 Low byte
T1_H        EQU 32H          ; Timer 1 High byte
T1_L        EQU 33H          ; Timer 1 Low byte
CHANGE_H    EQU 34H          ; Change in duty cycle (High byte)
CHANGE_L    EQU 35H          ; Change in duty cycle (Low byte)
TEN         EQU 36H          ; Tens digit of duty cycle
UNIT        EQU 37H          ; Units digit of duty cycle

;====================================================================
; INTERRUPT VECTORS
;====================================================================
        ORG 0000H
        JMP Start            ; Reset Vector

        ORG 0003H
        JMP EX0_ISR          ; External Interrupt 0

        ORG 0013H
        JMP EX1_ISR          ; External Interrupt 1

        ORG 000BH
        JMP T0_ISR           ; Timer 0 Interrupt

        ORG 001BH
        JMP T1_ISR           ; Timer 1 Interrupt

;====================================================================
; MAIN CODE SEGMENT
;====================================================================
        ORG 0100H
Start:
        MOV TMOD, #11H       ; Timer 0 and Timer 1 in mode 1
        MOV TCON, #00H       ; Clear Timer control
        ACALL LCD_INIT       ; Initialize LCD
        ACALL RELOAD_MSG     ; Display welcome message

        ; Configure external interrupts
        SETB IT0
        SETB IT1

        ; Load initial duty cycle timings
        MOV T1_H, #0FDH      ; 700 us
        MOV T1_L, #07AH
        MOV T0_H, #0FEH      ; 300 us
        MOV T0_L, #0EBH

        ; Initialize variables
        MOV CHANGE_H, #0FFH
        MOV CHANGE_L, #0F6H
        MOV TEN, #07H
        MOV UNIT, #00H

        ACALL Display         ; Display initial values
        MOV IE, #8FH          ; Enable interrupts
        SETB TR0              ; Start Timer 0

Loop:
        JMP Loop              ; Infinite loop

;====================================================================
; TIMER INTERRUPTS
;====================================================================
T0_ISR:
        SETB SIG              ; Set signal high
        CLR TR0               ; Stop Timer 0
        CLR TF0               ; Clear Timer 0 flag
        MOV TH0, T0_H         ; Reload Timer 0
        MOV TL0, T0_L
        SETB TR1              ; Start Timer 1
        RETI

T1_ISR:
        CLR SIG               ; Set signal low
        CLR TR1               ; Stop Timer 1
        CLR TF1               ; Clear Timer 1 flag
        MOV TH1, T1_H         ; Reload Timer 1
        MOV TL1, T1_L
        SETB TR0              ; Start Timer 0
        RETI

;====================================================================
; EXTERNAL INTERRUPTS
;====================================================================
EX0_ISR:                      ; Interrupt Service Routine for External Interrupt 0
                              ; Triggered to increase the duty cycle
    ; Adjust low period (T0) for higher duty cycle
    MOV R1, T0_L             ; Load T0 low byte into R1
    MOV R2, T0_H             ; Load T0 high byte into R2
    ACALL Minus_1ms          ; Decrease low period by 1ms
    MOV T0_L, R5             ; Update T0 low byte with result
    MOV T0_H, R6             ; Update T0 high byte with result

    ; Adjust high period (T1) for higher duty cycle
    MOV R1, T1_L             ; Load T1 low byte into R1
    MOV R2, T1_H             ; Load T1 high byte into R2
    ACALL Plus_1ms           ; Increase high period by 1ms
    MOV T1_L, R5             ; Update T1 low byte with result
    MOV T1_H, R6             ; Update T1 high byte with result

    ; Reset the timers with new values
    ACALL Reset_Timer        

    ; Increment the displayed duty cycle percentage
    CLR C                    ; Clear carry flag for addition
    MOV A, UNIT              ; Load current units digit of duty cycle
    ADD A, #1                ; Increment units digit
    SUBB A, #0AH             ; Check if units exceed 9 (decimal carry)
    JZ ADD_H                 ; If carry occurs, increment tens digit

    ; No carry: Update units digit only
    MOV A, UNIT              ; Reload current units digit
    ADD A, #1                ; Increment units digit
    MOV UNIT, A              ; Store updated units digit
    MOV A, TEN               ; Load current tens digit
    ADDC A, #0               ; Add carry to tens digit (if any)
    MOV TEN, A               ; Store updated tens digit

    ; Update LCD display
    ACALL Display            
    RETI
EX1_ISR:                      ; Interrupt Service Routine for External Interrupt 1
                              ; Triggered to decrease the duty cycle
    ; Adjust low period (T0) for lower duty cycle
    MOV R1, T0_L             ; Load T0 low byte into R1
    MOV R2, T0_H             ; Load T0 high byte into R2
    ACALL Plus_1ms           ; Increase low period by 1ms
    MOV T0_L, R5             ; Update T0 low byte with result
    MOV T0_H, R6             ; Update T0 high byte with result

    ; Adjust high period (T1) for lower duty cycle
    MOV R1, T1_L             ; Load T1 low byte into R1
    MOV R2, T1_H             ; Load T1 high byte into R2
    ACALL Minus_1ms          ; Decrease high period by 1ms
    MOV T1_L, R5             ; Update T1 low byte with result
    MOV T1_H, R6             ; Update T1 high byte with result

    ; Reset the timers with new values
    ACALL Reset_Timer        

    ; Decrement the displayed duty cycle percentage
    CLR C                    ; Clear carry flag for subtraction
    MOV A, UNIT              ; Load current units digit of duty cycle
    JZ SUB_L                 ; If units digit is 0, decrement tens digit
    SUBB A, #1               ; Decrement units digit
    MOV UNIT, A              ; Store updated units digit
    MOV A, TEN               ; Load current tens digit
    SUBB A, #0               ; Subtract carry from tens digit (if any)
    MOV TEN, A               ; Store updated tens digit

    ; Update LCD display
    ACALL Display            
    RETI

SUB_L:                       ; Handle underflow in duty cycle
    MOV A, #9                ; Set units digit to 9
    MOV UNIT, A              ; Store updated units digit
    MOV A, TEN               ; Load current tens digit
    SUBB A, #1               ; Decrement tens digit
    MOV TEN, A               ; Store updated tens digit
    ACALL Display            ; Update LCD display
    RETI  
ADD_H:                       ; Handle decimal carry in duty cycle
    CLR A                    ; Reset accumulator to 0
    MOV UNIT, A              ; Set units digit to 0
    MOV A, TEN               ; Load current tens digit
    ADD A, #1                ; Increment tens digit
    MOV TEN, A               ; Store updated tens digit
    ACALL Display            ; Update LCD display
    RETI  
;====================================================================
; SUPPORT FUNCTIONS
;====================================================================
Reset_Timer:
        ; Reset and reload the timer values for both Timer 0 and Timer 1.
        CLR TR1           ; Stop Timer 1
        CLR TF1           ; Clear Timer 1 overflow flag
        CLR TR0           ; Stop Timer 0
        CLR TF0           ; Clear Timer 0 overflow flag
        MOV TH0, T0_H     ; Load Timer 0 High byte
        MOV TL0, T0_L     ; Load Timer 0 Low byte
        MOV TH1, T1_H     ; Load Timer 1 High byte
        MOV TL1, T1_L     ; Load Timer 1 Low byte
        SETB TR0          ; Start Timer 0
        SETB TR1          ; Start Timer 1
        RET               ; Return to the calling function

Minus_1ms:
        MOV R3, CHANGE_L  ; Load the 1ms Low byte value
        MOV R4, CHANGE_H  ; Load the 1ms High byte value
        CLR C             ; Clear the carry flag for subtraction
        MOV A, R1         ; Load the Low byte of the timer into A
        SUBB A, R3        ; Subtract the 1ms Low byte value
        MOV R5, A         ; Store the updated Low byte
        MOV A, R2         ; Load the High byte of the timer into A
        SUBB A, R4        ; Subtract the 1ms High byte value
        MOV R6, A         ; Store the updated High byte
        RET               ; Return to the calling function

Plus_1ms:
        MOV R3, CHANGE_L  ; Load the 1ms Low byte value
        MOV R4, CHANGE_H  ; Load the 1ms High byte value
        MOV R7, #00       ; Initialize the 3rd byte (if needed) to zero
        CLR C             ; Clear the carry flag for addition
        MOV A, R1         ; Load the Low byte of the timer into A
        ADD A, R3         ; Add the 1ms Low byte value
        MOV R5, A         ; Store the updated Low byte
        MOV A, R2         ; Load the High byte of the timer into A
        ADDC A, R4        ; Add the 1ms High byte value with carry
        MOV R6, A         ; Store the updated High byte
        RET               ; Return to the calling function
;====================================================================
; DISPLAY FUNCTIONS
;====================================================================
Display:
    ; Reload the LCD measurement messages and update the duty cycle and voltage display
    ACALL RELOAD_MESUREMENT
    
    ; Move to the 13th position of the first line on the LCD (duty cycle)
    MOV R1, #0CH
    ACALL LCD_GOTO
    
    ; Display the "Tens" digit of the duty cycle
    MOV A, TEN
    ADD A, #30H
    ACALL LCD_DATA

    ; Display the "Units" digit of the duty cycle
    MOV A, UNIT
    ADD A, #30H
    ACALL LCD_DATA

    ; Display the "%" symbol after the duty cycle value
    MOV A, #'%'
    ACALL LCD_DATA

    ; Move to the 13th position of the second line on the LCD (voltage)
    MOV R1, #4CH
    ACALL LCD_GOTO

    ; Display the pre-defined voltage string (e.g., "3.5V")
    MOV DPTR, #MSG2
    ACALL DISPLAY_STRING
    RET

Update_Display:
    ; Increment the "UNIT" variable and handle carry to the "TEN" variable
    CLR C
    MOV A, UNIT
    ADD A, #1
    SUBB A, #0AH
    JZ ADD_H          ; If carry, jump to add carry handling
    MOV UNIT, A       ; Update "UNIT" and refresh the display
    ACALL Display
    RET
;====================================================================
; LCD FUNCTIONS
;====================================================================

LCD_CMD:
    ; Send a command to the LCD
    ACALL LCD_busy
    MOV DATA_LINE, A
    CLR RS            ; RS=0 (Command mode)
    CLR RW            ; RW=0 (Write mode)
    SETB EN           ; Generate enable pulse
    CLR EN
    RET

LCD_DATA:
    ; Send data to the LCD
    ACALL LCD_busy
    MOV DATA_LINE, A
    SETB RS           ; RS=1 (Data mode)
    CLR RW            ; RW=0 (Write mode)
    SETB EN           ; Generate enable pulse
    CLR EN
    RET

LCD_INIT:
    ; Initialize the LCD in 8-bit mode with cursor settings
    MOV A, #38H       ; 8-bit data, 2 lines, 5x7 font
    ACALL LCD_CMD
    MOV A, #0EH       ; Display ON, cursor ON
    ACALL LCD_CMD
    MOV A, #01H       ; Clear the display
    ACALL LCD_CMD
    MOV A, #06H       ; Increment cursor, no shift
    ACALL LCD_CMD
    MOV A, #80H       ; Move cursor to the first position
    ACALL LCD_CMD
    RET

LCD_busy:
    ; Check if the LCD is busy (wait until not busy)
    SETB P2.7         ; Set DB7 as input (busy flag)
    SETB EN           ; Enable LCD for read
    CLR RS            ; RS=0 (Command mode)
    SETB RW           ; RW=1 (Read mode)
Check_Busy:
    CLR EN            ; Clear enable to latch data
    SETB EN           ; Set enable again
    JB P2.7, Check_Busy ; Repeat if DB7 is high (busy)
    RET

RELOAD_MSG:
    ; Display the startup message on the LCD
    MOV A, #01H       ; Clear display
    ACALL LCD_CMD

    MOV DPTR, #START_MSG0 ; Display "WELCOME !!!"
    ACALL DISPLAY_STRING
    ACALL DELAY

    MOV A, #0C0H      ; Move to the second line
    ACALL LCD_CMD
    MOV DPTR, #START_MSG1 ; Display "DC-DC Converter"
    ACALL DISPLAY_STRING
    RET

RELOAD_MESUREMENT:
    ; Reload the measurement labels on the LCD
    MOV A, #01H       ; Clear display
    ACALL LCD_CMD

    MOV DPTR, #DUTY_CYCLE ; Display "DUTY_CYCLE :"
    ACALL DISPLAY_STRING
    ACALL DELAY

    MOV A, #0C0H      ; Move to the second line
    ACALL LCD_CMD
    MOV DPTR, #VOLTAGE ; Display "VOLTAGE :"
    ACALL DISPLAY_STRING
    RET

DISPLAY_STRING:
    ; Display a null-terminated string on the LCD
NEXT_CHAR:
    CLR A
    MOVC A, @A+DPTR   ; Fetch next character from DPTR
    JZ END_STRING     ; Exit if null character is reached
    ACALL LCD_DATA    ; Display character
    ACALL DELAY       ; Small delay for stability
    INC DPTR          ; Increment pointer
    SJMP NEXT_CHAR
END_STRING:
    RET

LCD_GOTO:
    ; Move cursor to the specified position
    MOV A, R1         ; Load desired position
    ORL A, #80H       ; Convert to LCD address
    ACALL LCD_CMD
    RET

;====================================================================
; DELAY SUBROUTINES
;====================================================================

DELAY: 
        ; Generates a delay loop
        ; R5 controls the number of outer loops
        ; R4 controls the number of inner loops
        ; Total Delay â‰ˆ R5 * R4 iterations
        MOV R5, #100         ; Set the outer loop counter (adjust for delay tuning)
Outer:
        MOV R4, #255         ; Set the inner loop counter
Inner:
        DJNZ R4, Inner       ; Decrement R4 until it reaches zero
        DJNZ R5, Outer       ; Decrement R5 and repeat the outer loop
        RET                  ; Return after completing all iterations

TRIPLE_DELAY: 
        ; Generates a longer delay by calling DELAY three times
        ACALL DELAY          ; Call the DELAY subroutine
        ACALL DELAY          ; Repeat for additional delay
        ACALL DELAY          ; Third delay call
        RET                  ; Return after completing all three calls

;====================================================================
; CONSTANT STRINGS
;====================================================================

START_MSG0: 
        DB '  WELCOME !!! ', 0       ; Welcome message for LCD (line 1)
START_MSG1: 
        DB ' DC-DC Converter  ', 0   ; Project title for LCD (line 2)

DUTY_CYCLE: 
        DB 'DUTY_CYCLE : ', 0        ; Label for displaying duty cycle on LCD
VOLTAGE: 
        DB 'VOLTAGE : ', 0           ; Label for displaying voltage on LCD

MSG2: 
        DB '3.5V', 0                 ; Example voltage display value

;====================================================================
; END OF PROGRAM
;====================================================================
END

