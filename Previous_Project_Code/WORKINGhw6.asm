*****************************************************************************
*
* Title:        SCI Serial Port and 7-segment Display at PORTB
*
* Objective:    CMPEN 472 Homework 4 program
*
* Revision:     V1 for CodeWarrior 5.9.0 Debugger Simulator
*
* Date:         Feb. 12, 2025
*
* Programmer:   Evan Yang
*
* Company:      The Pennsylvania State University
*               Department of Computer Science and Engineering
*
* Program:      Simple SCI Serial Port I/O and Demonstration
*               Typewriter program and 7-Segment display, at PORTB
*
* Register use: LED 4 goes 0%-100% in 0.4 seconds
*               LED 4 then goes 100%-0% in 0.4 seconds
*               LED 1, 3, and 2 OFF
*               
*
* Memory use:   RAM Locations from $3000 for data
*               RAM locations from $3100 for program & extra data
*
* Input:        Parameters hard-coded in the program - PORTB
*               Terminal input trough SCI port
*
* Output:       LED 1 at PORTB bit 4
*               LED 2 at PORTB bit 5
*               LED 3 at PORTB bit 6
*               LED 4 at PORTB bit 7
*
* Observation:  This is a program that dims and switches LEDs through terminal
*               commands, while other commands are ignored.
*
* Comments:     On CSM-12C128 board,
*               Switch 1 is @ PORTB bit 0,
*               LED 4 is @ PORTB bit 7,
*               This program is developed and simulated using CodeWarrior
*               development software with switch simulation problem
*               As such, one must set "switch 1" @ PORTB bit 0 as an OUTPUT,
*               not INPUT. (on the board, PORTB bit 0 set to INPUT)
*
*****************************************************************************
* Parameter Declaration Section
*
* Export Symbols
            XDEF       pstart       ; export 'pstart' symbol (kind of like import API)
            ABSENTRY   pstart       ; for assembly entry point (absolute entry @ pstart)

* Symbols and Macros
PORTA       EQU        $0000        ; i/o port A addresses
DDRA        EQU        $0002        
PORTB       EQU        $0001        ; i/0 port B addresses
DDRB        EQU        $0003   
  
SCIBDH      EQU        $00C8        ; Serial port (SCI) Baud Register H
SCIBDL      EQU        $00C9        ; Serial port (SCI) Baud Register L
SCICR2      EQU        $00CB        ; Serial port (SCI) Control Register 2
SCISR1      EQU        $00CC        ; Serial port (SCI) Status Register 1
SCIDRL      EQU        $00CF        ; Serial port (SCI) Data Register

CR          EQU        $0D          ; carriage return, ASCII 'Return' key
LF          EQU        $0A          ; line feed, ASCII 'next line' character   
SC          EQU        $53          ; S char
WC          EQU        $57          ; W char
QC          EQU        $51          ; Q char
DSC         EQU        $24          ; $ char
N0          EQU        $30          ; 0 num (up to num 0 @ $39)
N9          EQU        $39          ; 9 num 
AC          EQU        $41          ; A char (up to F @ $46)
FC          EQU        $46          ; F char
SPA         EQU        $20          ; Space

*****************************************************************************
* Data Section: address used [ $3000 to $30FF ] RAM memory
*
            ORG        $3000        ; Reserved RAM memory starting address
                                    ;   for Date for CMPEN 472 class
buffer      DS.B       65           ; reserves 65 bytes of mem for char buffer (64 actual)

hexCounter  DC.B       6            ; num of hex letter

decCounter  DC.B       10           ; num of dec val

asciiHexBuf DS.B       6            ; reserve 6 bytes of mem for char to hex buffer

hexValBuf   DS.B       36           ; 16-digit binary + 4 space + DSC + 4-digit hex + 4 space + 1 NULL
                                    ;   5-digit decimal is variable length w/ 1 NULL @ end
wInputBuf   DS.B       8            ; buffer to hold 5-digit decimals OR 4-digit hex + 1 $FF + 2 shrink addresses

; Each message ends with $00 (NULL ASCII character) for your program.
;
; There are 256 bytes from $3000 to $3100.  If you need more bytes for
; your messages, you can put more messages 'msg3' and 'msg4' at the end of 
; the program - before the last "END" line.                                     
; Remaining data memory space for stack
;   up to program memory start
*
*****************************************************************************
* Program Section: address used [$3100 to $3FFF] RAM memory
*
            ORG       $3100                 ; Program origin (ORG) address in RAM
pstart      LDS       #$3100                ; load the stack pointer to after saved data 

            LDAA      #%11111111            ; LED 1,2,3,4 at PORTB bit 4,5,6,7 for Simulation only
            STAA      DDRB                  ; set PORTB bit 4,5,6,7 as output
            
            LDAA      #%00000000
            STAA      PORTB                 ; Turn off all LEDs & switches (all bits in PORTB for simulation)
            
            LDAA      #$0C                  ; Enable SCI port Tx and Rx units
            STAA      SCICR2                ; disable SCI interrupts
            
            LDD       #$0001                ; Set SCI Baud Register = $0001 => 1.5M baud at 24MHz (for simulation)
            STD       SCIBDH                ; SCI port baud rate change
            
            LDX       #showMsg              ; print quit msg
            JSR       printmsg
            
            JSR       nextLine
            
            LDX       #writeMsg             ; print quit msg
            JSR       printmsg
            
            JSR       nextLine            
            
            LDX       #quitMsg              ; print off msg
            JSR       printmsg
            
            JSR       nextLine
               
            LDY       #hexValBuf + 16       ; point to mem after bin
preLoadBuf  LDAA      #SPA                  ; load 4 spaces into mem
            STAA      1,Y+
            LDAA      #SPA        
            STAA      1,Y+
            LDAA      #SPA          
            STAA      1,Y+
            LDAA      #SPA          
            STAA      1,Y+
            CPY       #hexValBuf + 20       ; check if $ or no $
            BNE       preloadAlm            ; preload almost done
            LDAA      #DSC                  ; load "$" into mem
            STAA      1,Y+
            LDY       #hexValBuf + 25       ; point to mem after hex
            BRA       preLoadBuf            ; load 4 spaces again
            
preloadAlm  LDY       #buffer               ; load buffer on Y           
                        
mainLoop    
            JSR       getchar               ; check keyboard input
            CMPA      #$00                  ; if nothing keep checking (loop via BEQ)
            BEQ       mainLoop
            
            STAA      1,Y+                  ; store char on buffer & increment to next addr
            CPY       #buffer + 65  ; check if exceeded char limit
            BEQ       wrongInCaseJmp
            JSR       putchar               ; display what was typed on keyboard to terminal window (echo)
             
            CMPA      #CR                   ; if enter pressed move to next line
            BNE       mainLoop              ; enter not pressed (go back to null check)           
            LDAA      #LF                   ; move to next line
            JSR       putchar
                        
            LDAB      buffer                ; load char on buffer (check buffer after press enter)
            CMPB      #SC           
            BEQ       inCaseJmp             ; jump to S case JSR if S
            CMPB      #WC
            BEQ       inCaseJmp             ; jump to W case JSR oi W
            CMPB      #QC
            BEQ       qCaseCheck            ; jump to Q case JSR if Q
            JSR       wrongInCase           ; no chars match; assume wrong case

caseDone    LDY       #buffer               ; load buffer on Y
            JSR       zeroBuff              ; reset buffer
            BRA       mainLoop   

; End Main Loop            
;**************************************************************
; Extras

inCaseJmp
            JSR       inCheck
            BRA       caseDone

wrongInCaseJmp
            JSR       nextLine
            JSR       wrongInCase
            BRA       caseDone

qCaseCheck  
            LDY       #buffer + 1
            LDAB      0,Y                   ; starts @ 2nd char
           
            CMPB      #$55                  ; checks U
            BNE       wrongInCaseJmp        ; if not U skip to wrongCase
             
            LDAB      1,Y                   ; moves to next char
            CMPB      #$49                  ; checks I
            BNE       wrongInCaseJmp        ; if not I skip to wrongCaseJmp (will go back to mainLoop after error msg)               
             
            LDAB      2,Y                   ; moves to next char
            CMPB      #$54                  ; checks T
            BNE       wrongInCaseJmp        ; if not T skip to wrongCaseJmp (will go back to mainLoop after error msg)              
            BRA       typewrite

; End Extras            
;**************************************************************
; Typerwriter Program

typewrite   
            LDX       #msgt                 ; print the first message, 'Hello'
            JSR       printmsg

            JSR       nextLine

twLoop      JSR       getchar               ; type writer - check the key board
            CMPA      #$00                  ;  if nothing typed, keep checking
            BEQ       twLoop
                                            ;  otherwise - what is typed on key board
            JSR       putchar               ; is displayed on the terminal window - echo print

            STAA      PORTB                 ; show the character on PORTB

            CMPA      #CR
            BNE       twLoop                ; if Enter/Return key is pressed, move the
            LDAA      #LF                   ; cursor to next line
            JSR       putchar
            BRA       twLoop
                        
*****************************************************************************
* Subroutine Section: address used [ $3100 to $3FFF ] RAM memory
*

;**************************************************************
; Wrong Input Case subroutine
;
; prints out error message if case is wrong
;
; Input: N/A
; Output: Prints out error msg, prompts user to press enter to return to loop
; Registers in use: A, X 
; Memory locations in use: None

wrongInCase    LDX       #wrongInMsg
               JSR       printmsg
               JSR       nextLine      ; if entered, go to next line and resets buffer
               JSR       nextLine
               RTS

;**************************************************************
; Wrong Data Case subroutine
;
; prints out error message if case is wrong
;
; Input: N/A
; Output: Prints out error msg, prompts user to press enter to return to loop
; Registers in use: A, X 
; Memory locations in use: None

wrongDaCase    LDX       #wrongDaMsg
               JSR       printmsg
               JSR       nextLine      ; if entered, go to next line and resets buffer
               JSR       nextLine
               RTS

;**************************************************************
; Input Checking Subroutine
; 
; Checks if input is within realm of mem locations AND values (pure ASCII for the latter)
; Since both S & W uses same input format w/ some diff, consolidated into 1 subroutine
; S & W is guaranteed through conditionals in the main loop
;
; Input: Buffer address @ Y loaded into B
; Output: does operation or prints out error msg if no match (returns after)
; Registers in use: B, Y 
; Memory locations in use: 3100 and on
            
inCheck        LDY       #buffer + 1   ; start @ 2nd char
               LDAB      0,Y           ; check 2nd char
               CMPB      #DSC          ; compare with $ ASCII
               BNE       wrongIn       ; if 2nd char not $, wrong case
               INY         
               LDAB      0,Y           ; move to 3rd char
               CMPB      #N0           ; compare B input with 0
               BLO       wrongIn       ; if lower, invalid
               CMPB      #FC           ; compare B input with F
               BHI       wrongIn       ; if higher, invalid
               CMPB      #N9           ; compare B input with 9
               BLS       firstAddrOk   ; within 0-9 (valid), move to next char loop
               CMPB      #AC           ; compare B input with A
               BLO       wrongIn       ; if lower, invalid (between 9 & A) (if BHI then move to firstAddrOk)

firstAddrOk    INY                     ; move Y to next char
               LDAB      0,Y           ; load 4th-6th char per loop
               CMPB      #N0           ; compare B input with 0
               BLO       checkSpace    ; if lower, check space/enter
               CMPB      #FC           ; compare B input with F
               BHI       wrongIn       ; if higher, invalid (space less than other ASCII)
               CMPB      #N9           ; compare B input with 9
               BLS       nextAddrChar  ; within 0-9 (valid), move to next char
               CMPB      #AC           ; compare B input with A
               BLO       wrongIn       ; if lower, invalid (between 9 & A) (if BHI then move to nextAddrChar)
               
nextAddrChar   CPY       #buffer + 6   ; check if Y is @ 7th char
               BNE       firstAddrOk   ; check next char again if not reached 7th char
               BEQ       wrongIn       ; if entered here @ 7th char (5th char of addr), either not space or not return; assume wrong

checkSpace     PSHY                    ; save Y (addr after addr input) into stack
               LDAB      buffer        ; load first char into B (preserve Y pointer)
               CMPB      #SC           ; check if S-type cmd
               BEQ       checkSFinal   ; if S, no data input needed (if next char not return, invalid)
               LDAB      0,Y           ; reload last char (most likely enter)
               CMPB      #CR           ; compare B with return (assume W-type; return invalid)
               BEQ       undoPSHYIn    ; incomplete address
               CMPB      #SPA          ; compare B with space (assume W-type; return invalid)
               BNE       wrongData     ; no space (exclude return); potential wrong addr format
               
checkData      INY
               LDAB      1,Y+          ; load 8th char into B
               LDAA      #5            ; counter (can only be 5 more digits)
               CMPB      #DSC          ; check if $ (hex data)
               BEQ       hexData       ; check in hex context (if not default is dec context)
               BRA       decDataInit   ; skip over wrongIn

undoPSHYIn     PULY                    ; undo push for proper RTS
wrongIn        JSR       wrongInCase
               BRA       done          ; skip wrongData case 
               
decDataInit    CMPB      #N0           ; compare B input with 0
               BLO       wrongData     ; invalid decimal (ASCII under 0)
               CMPB      #N9           ; compare B input with 9
               BHI       wrongData     ; invalid decimal (ASCII over 9)

decData        LDAB      1,Y+          ; increment Y & load next char into B
               CMPB      #N0           ; compare B input with 0 (start decData loop @ char 9)
               BLO       checkWFinal   ; check if return (lower than 0)
               CMPB      #N9           ; compare B input with 9
               BHI       wrongData     ; invalid decimal (ASCII over 9)
               ;INY
               ;CPY       #buffer + 13  ; check if Y is @ 13th char (has to be return & caught by BLO above)
               DECA                    ; reduce counter value
               BNE       decData
               LDAB      0,Y           ; load last char (after supposed last char)
               CMPA      #CR           ; check if return
               BEQ       checkWFinal   ; is return
               BRA       wrongData     ; exceeded 5 digits & not return; assume wrong

hexData        LDAB      1,Y+           ; increment Y & load next char into B
               CMPB      #N0           ; compare B input with 0
               BLO       checkWFinal   ; if lower, check enter
               CMPB      #FC           ; compare B input with F
               BHI       wrongData     ; if higher, invalid (space less than other ASCII)
               CMPB      #N9           ; compare B input with 9
               BLS       hexCheckOk    ; within 0-9 (valid), move to next char loop
               CMPB      #AC           ; compare B input with A
               BLO       wrongData     ; if lower, invalid (between 9 & A) (if BHI then move to hexCheckOk)
                              
hexCheckOk     ;CPY       #buffer + 13  ; check if Y is @ 13th char (has to be return & caught by BLO above)
               DECA                    ; decrease counter
               BNE       hexData
               LDAB      0,Y           ; load last char (after supposed last char)
               CMPA      #CR           ; check if return
               BEQ       checkWFinal   ; is return
               BRA       wrongData     ; exceeded 5 digits & not return; assume wrong

checkWFinal    CMPB      #CR           ; compare last B input with return
               BNE       wrongData     ; if not return, invalid end of input
               PULY                    ; restore last addr char ptr from stack (space)
               JSR       wFunc
               BRA       done          ; exit subroutine (back to polling)

checkSFinal    LDAB      0,Y           ; reload last char (most likely enter)
               CMPB      #CR           ; compare last B input with return
               BNE       wrongIn       ; if not return, invalid end of input               
               PULY                    ; restore last addr char ptr from stack (return)
               JSR       sFunc
               BRA       done          ; exit subroutine (back to polling)

wrongData      PULY                    ; undo push for proper RTS               
               JSR       wrongDaCase   

done           RTS


;**************************************************************
; S function subroutine
; 
; Reads and prints value @ address inputted @ S
;
; Input: Buffer address @ Y with 0 in A
; Output: 0's out every addr in buffer till end
; Registers in use: B, Y 
; Memory locations in use: None

sFunc          JSR       prefixPrint
               PSHX                    ; save X starting addr
               LDY       #buffer + 2   ; load 1st addr char addr into Y (for later loops)
               CPD       #buffer + 6   ; compares with maximum address input length
               BEQ       addrFullS     ; no padding; directly process addr

               JSR       padAddr
               BRA       checkAddrLoopS; skip assumeAddrFull (custom B counter from 1-3)
  
addrFullS      LDAB      #4            ; all address values filled
checkAddrLoopS JSR       checkAddr               
                
               PULY                    ; restore X original ptr val @ Y
               JSR       shrinkAddr

               LDX       #asciiHexBuf + 4 ; load completed val addr to X
               LDY       0,X           ; loads addr value pted by X into Y
               LDD       0,Y           ; loads value held in addr loaded onto Y (the value to show)
               JSR       showVal

               JSR       nextLine
               JSR       nextLine                  
               RTS                

;**************************************************************
; W function subroutine
; 
; Reads and prints value @ address & input value inputted @ W
;
; Input: Buffer address @ Y with 0 in A
; Output: 0's out every addr in buffer till end
; Registers in use: B, Y 
; Memory locations in use: None

wFunc          PSHY                    ; save Y last addr value into stack
               LDAB      1,Y           ; load $/digit into B
               CMPB      #DSC          ; check if $ (hex data)
               BEQ       startPrintW   ; no need to check max for hex (4 digits max is 65535, or $FFFF)
               LDX       #wInputBuf    ; load buffer addr into X
               INY                     ; move Y to first input data digit
               
wDecDataLoop   LDAA      1,Y+          ; load num into A (increment ptr done @ conversion subroutine)
               CMPA      #$0D          ; check if enter
               BEQ       checkDecMax   ; check val if yes
               JSR       ASCIINum      ; convert ASCII into num
               BRA       wDecDataLoop

checkDecMax    LDAA      #$FF          ; set breakpt of num as $FF
               STAA      0,X           ; load breakpt into mem
               CPX       #wInputBuf + 5; check if FF is at end (if not value is within max)
               BLO       startPrintW   ; def less than max (only 4 digits or less)
               LDY       #wInputBuf    ; reload decimal buffer to Y
               LDAB      1,Y+          ; load MSB decimal into B
               CMPB      #6            ; compare B with 6
               BHI       wrongDataW    ; must be higher than 65535 (MSB dec is out of max)
               BLO       startPrintW   ; lower than 6 implies less than 65535
               LDAB      1,Y+          ; load next MSB decimal into B (assuming last decimal was 6)
               CMPB      #5            ; compare B with 5
               BHI       wrongDataW    ; must be higher than 65535 (MSB dec is out of max)
               BLO       startPrintW   ; lower than 6 implies less than 65535
               LDAB      1,Y+          ; load next MSB decimal into B (assuming last decimal was 5)
               CMPB      #5            ; compare B with 5
               BHI       wrongDataW    ; must be higher than 65535 (MSB dec is out of max)
               BLO       startPrintW   ; lower than 6 implies less than 65535
               LDAB      1,Y+          ; load next MSB decimal into B (assuming last decimal was 5)
               CMPB      #3            ; compare B with 5
               BHI       wrongDataW    ; must be higher than 65535 (MSB dec is out of max)
               BLO       startPrintW   ; lower than 6 implies less than 65535
               LDAB      1,Y+          ; load next MSB decimal into B (assuming last decimal was 3)
               CMPB      #5            ; compare B with 5
               BHI       wrongDataW    ; must be higher than 65535 (MSB dec is out of max)
               
startPrintW    PULY                    ; restore Y value from stack
               JSR       prefixPrint
               PSHX                    ; save X starting addr
               LDY       #buffer + 2   ; load 1st addr char addr into Y (for later loops)
               CPD       #buffer + 6   ; compares with maximum address input length
               BEQ       addrFullW     ; no padding; directly process addr

               JSR       padAddr
               BRA       checkAddrLoopW; skip assumeAddrFull (custom B counter from 1-3)

wrongDataW     PULY                    ; undo push
               JSR       wrongDaCase   ; wrongDataW here due to 128 jump limit
               RTS
  
addrFullW      LDAB      #4            ; all address values filled
checkAddrLoopW JSR       checkAddr               
               
               TFR       Y,X           ; transfer ptr to end of addr input from Y to X
               PULY                    ; restore X original ptr val @ Y
               PSHX                    ; save mentioned ptr into stack from X
               LDX       #asciiHexBuf + 4; reload X for shrinkAddr
               JSR       shrinkAddr

               LDX       #asciiHexBuf + 4 ; load completed val addr to X
               PULY                    ; restore ptr to end of addr input to Y

               INY                     ; move pty from space to $/digit
               LDAB      0,Y           ; load $/digit into B
               CMPB      #DSC          ; check if $ (hex data)
               BNE       checkDecVal   ; check in hex context (if not default is dec context)

               INY                     ; skip $
               LDX       #wInputBuf    ; load decimal buffer to X
wHexDataLoop   LDAA      1,Y+          ; load num into A (increment ptr done @ conversion subroutine)
               CMPA      #$0D          ; check if enter
               BEQ       checkHexVal   ; check val if yes
               CMPA      #N9           ; compare with 9 ASCII
               BLS       wHexDataNum   ; of numerical, convert in terms of num
               JSR       ASCIIAlpha    ; convert ASCII into num
               BRA       wHexDataLoop               
              
wHexDataNum    JSR       ASCIINum      ; process hex if numerical
               BRA       wHexDataLoop  ; return to loop
               
checkHexVal    LDD       #$0004        ; set A counter as 0, B counter as 4 by default
               CPX       #wInputBuf + 4; check if input is X
               BHS       writeFull     ; no padding needed
               
padHexData     TFR       X,D           ; transfer addr stored in X to D
               DECB                    ; move D to non-return char
               SUBB      #$6A          ; sub B by $6A to achieve 3,4,5
               JSR       padAddrCtr    ; not BHS; start finding pad values               
               LDX       #wInputBuf + 5; load starting addr for shrunken hex
               LDY       #wInputBuf    ; load starting addr for unshrunk hex
               ;PSHB                    ; save B ctr to stack
               ;LDAB      #$00          ; load 0 to B (if A=1 or 2, the MSBs are 0)
               CMPA      #3            ; compare ctr to 3 (3 0s)
               BEQ       writeB1       ; consider A3/B1 case if true
               
writeA12       ;STAB      0,X           ; store 0 to mem pted by X
               ;PULA                    ; restore A
               CMPA      #1            ; compare ctr to 1
               BEQ       writeB3       ; start inputting remaining 3
               BRA       writeB2       ; if not 1 or 3, assume 2 for A

writeB1        INX           
               LDAB      0,Y           ; load unshrunk value pted @ Y to B
               STAB      0,X           ; store @ mem pted by X (shrunk mem addr LSB)
               BRA       writeDone

writeB2        INX                     ; move X to next addr (LSB of shrunk val)
               LDAB      1,Y+          ; load first input hex into B and increment Y
               LSLB                    ; shift loaded value 4 bits to the left
               LSLB
               LSLB
               LSLB
               ORAB      0,Y           ; OR second input hex into B
               STAB      0,X           ; store values into shrunk addr pted by X
               BRA       writeDone

writeB3        LDAB      1,Y+          ; load first input hex into B and increment Y
               STAB      1,X+           ; store values into shrunk addr pted by X and increment X
               LDAB      1,Y+          ; load second input hex into B and increment Y
               LSLB                    ; shift loaded value 4 bits to the left
               LSLB
               LSLB
               LSLB
               ORAB      0,Y           ; OR third input hex into B
               STAB      0,X           ; store values into shrunk addr pted by X
               BRA       writeDone

writeFull      LDX       #wInputBuf + 5; load starting addr for shrunken hex
               LDY       #wInputBuf    ; load starting addr for unshrunk hex
               LDAB      1,Y+          ; load first input hex into B and increment Y
               LSLB                    ; shift loaded value 4 bits to the left
               LSLB
               LSLB
               LSLB
               ORAB      1,Y+          ; OR second input hex into B
               STAB      1,X+          ; store values into shrunk addr pted by X
               LDAB      1,Y+          ; load third input hex into B and increment Y
               LSLB                    ; shift loaded value 4 bits to the left
               LSLB
               LSLB
               LSLB
               ORAB      0,Y           ; OR fourth input hex into B
               STAB      0,X           ; store values into shrunk addr pted by X

writeDone      DEX                     ; revert X back to start of shrunken value
               LDD       0,X           ; load value pted by X onto D for printing
               BRA       writeVal      ; start writing val after process

checkDecVal    LDD       #$00          ; set D to 0
               LDY       #wInputBuf
checkDValLoop  ADDB      1,Y+          ; add number @ Y ptr into B and increment Y
               PSHD
               LDAB      0,Y           ; load next val into B for comparing
               CMPB      #$FF          ; compare with breakpt val   
               BEQ       checkDValDone ; if $FF, leave
               PULD                    ; restore D
               PSHY                    ; save Y ptr
               LDY       #$0A          ; load 10 onto Y (mult with D)
               EMUL                    ; multiply D(value) & X (multiplier, 10)
               PULY                    ; restore Y ptr
               BRA       checkDValLoop ; reloop 

checkDValDone  PULD                    ; restore D
               
writeVal       LDX       #asciiHexBuf + 4 ; load addr to mem addr to read from at X
               LDY       0,X           ; load address pted by X in mem to Y
               STD       0,Y           ; store D to address inputted
               JSR       showVal               
               JSR       nextLine                  
               JSR       nextLine
               RTS                

;**************************************************************
; Prefix print subroutine
; 
; Prints "S$" or "W$" upon return key
;
; Input: Buffer address @ Y with 0 in A
; Output: 0's out every addr in buffer till end
; Registers in use: B, Y 
; Memory locations in use: None

prefixPrint    PSHY                    ; save last char ptr into mem
               LDY       #buffer       ; set X as buffer start
               LDX       #asciiHexBuf  ; load ASCII-hex conversion buffer          
               LDAA      0,Y           ; load "S"/"W" into A
               JSR       putchar       ; print "S"/"W"
               INY                     ; increase Y ptr
               LDAA      0,Y           ; load "$" into A
               JSR       putchar       ; print "$"
               PULD                    ; restore D with Y last char info
               RTS
               
;**************************************************************
; Zero pad subroutine
; 
; Pads zeros relative to end of address position
;
; Input: Buffer address @ Y with 0 in A
; Output: 0's out every addr in buffer till end
; Registers in use: B, Y 
; Memory locations in use: None

padAddr        DECB                    ; move D to non-return char
               ADDB      #1            ; add B by 1 for math
               JSR       padAddrCtr
               PSHB                    ; save B to stack
padAddrLoop    LDAB      #$00          ; load 0 for padding
               STAB      1,X+          ; store 0 @ X ptr & increment X ptr
               PSHA
               LDAA      #N0           ; load 0 to A (for putchar)
               JSR       putchar       ; print the char
               PULA
               DECA                    ; decrease A counter
               BNE       padAddrLoop   ; if not zero, continue
               PULB                    ; restore B (if BEQ to checkAddrLoop, B no need to restore)
               RTS

;**************************************************************
; Pad counter subroutine
; 
; Finds number of zeros to pad (A) relative to number of non-zeros (B)
;
; Input: Buffer address @ Y with 0 in A
; Output: 0's out every addr in buffer till end
; Registers in use: B, Y 
; Memory locations in use: None

padAddrCtr     TBA                     ; transfer B (LSB) value to A (MSB not important)
               SUBB      #3            ; subtract B such that it's 0,1,2
               LSLB                    ; multiply B value by 2
               SBA                     ; subtract B (0,2,4) from A (3,4,5); A is the pad loop counter
               LSRB                    ; divide B by 2 (make opposite to A)
               ADDB      #1            ; add B to 1,2,3
               RTS

;**************************************************************
; Check Addr subroutine
; 
; Checks address inputted by user & processes into mem
;
; Input: Buffer address @ Y with 0 in A
; Output: 0's out every addr in buffer till end
; Registers in use: B, Y 
; Memory locations in use: None

checkAddr      LDAA      1,Y+          ; load input char (could be w/ or w/o) & increment Y ptr
               CMPA      #AC           ; compare with A char
               BHS       alphaProc     ; if greater than or equal to A, must be alpha
               BRA       numProc       ; if not, must be numeral
 
alphaProc      JSR       putchar       ; print char first
               JSR       ASCIIAlpha
               DECB                    ; decrease B counter by 1
               BNE       checkAddr     ; if not zero, continue
               BEQ       checkAddrDone

numProc        JSR       putchar       ; print char first
               JSR       ASCIINum
               DECB                    ; decrease B counter by 1
               BNE       checkAddr     ; if not zero, continue

checkAddrDone  RTS               

;**************************************************************
; ASCII to alpha/num subroutine
; 
; Converts ASCII into Alpha or Numeral
;
; Input: Buffer address @ Y with 0 in A
; Output: 0's out every addr in buffer till end
; Registers in use: B, Y 
; Memory locations in use: None

ASCIIAlpha     ADDA      #$09          ; add by 9 (make first 4 bits within alphas)
               ANDA      #$0F          ; mask MSB 4 bits to get hex representation of ASCII alpha
               STAA      1,X+          ; store into memory @ X ptr & increment X
               RTS

ASCIINum       ANDA      #$0F          ; mask MSB 4 bits to get hex representation of ASCII numeral
               STAA      1,X+          ; store into memory @ X ptr & increment X
               RTS

;**************************************************************
; Shrink address subroutine
; 
; Shrinks address to 16-bit and puts into memory
;
; Input: Buffer address @ Y with 0 in A
; Output: 0's out every addr in buffer till end
; Registers in use: B, A, X, Y 
; Memory locations in use: None

shrinkAddr     LDAB      #2            ; loop 2 times (2 8-bit hexes max)
shrinkAddrLoop LDAA      1,Y+          ; load MSB byte
               LSLA                    ; shift left 4 times
               LSLA
               LSLA
               LSLA
               ORAA      1,Y+          ; load LSB byte
               STAA      1,X+          ; store value into new X ptr addr
               DECB                    ; decrease B counter by 1
               BNE       shrinkAddrLoop; if not zero, continue
               RTS                     ; done looping

;**************************************************************
; Show value subroutine
; 
; Shows value read/to be written
;
; Input: Buffer address @ Y with 0 in A
; Output: 0's out every addr in buffer till end
; Registers in use: B, Y 
; Memory locations in use: None

showVal        PSHD                    ; save read/write value to stack
               LDY       #hexValBuf + 15 ; load buffer for converted numbers onto Y (going backwards)

binConvLoopL   PSHB                    ; save B to stack (LSB)
               ANDB      #1            ; mask left 7 bits
               ADDB      #$30          ; add it to ASCII 1/0
               STAB      1,Y-          ; store @ Y ptr and decrement Y
               PULB                    ; restore B
               LSRB                    ; shift B to the right by 1 bit
               CPY       #hexValBuf + 7 ; check if all of B is checked
               BNE       binConvLoopL
binConvLoopM   PSHA                    ; save A to stack (MSB)
               ANDA      #1            ; mask left 7 bits
               ADDA      #$30          ; add it to ASCII 1/0
               STAA      1,Y-          ; store @ Y ptr and decrement Y
               PULA                    ; restore A
               LSRA                    ; shift A to the right by 1 bit
               CPY       #hexValBuf - 1; check if all of A is checked
               BNE       binConvLoopM
               
               PULD                    ; restore D value
               LDY       #hexValBuf + 24 ;load buffer for converted numbers @ hex to Y (going backwards)
               PSHD                    ; save D again to stack
hexConvLoopL   PSHB                    ; save B to stack (LSB)
               ANDB      #$0F          ; mask left 4 bits
               CMPB      #$0A          ; compare with A val
               BHS       alphaASCIIconL; convert via alpha
               ADDB      #$30          ; add 0-9 by $30 for ASCII rep
               BRA       storehexL     ; skip alpha conversion
alphaASCIIconL ADDB      #$37          ; add A-F by $37 for ASCII rep
storehexL      STAB      1,Y-          ; store @ Y ptr and decrement Y
               PULB                    ; restore B
               LSRB                    ; shift B to the right by 4 bits
               LSRB                    
               LSRB                    
               LSRB                           
               CPY       #hexValBuf + 22 ; check if all of B is checked
               BNE       hexConvLoopL  
hexConvLoopM   PSHA                    ; save A to stack (LSB)
               ANDA      #$0F          ; mask left 4 bits
               CMPA      #$0A          ; compare with A char
               BHS       alphaASCIIconM; convert via alpha
               ADDA      #$30          ; add 0-9 by $30 for ASCII rep
               BRA       storehexM     ; skip alpha conversion
alphaASCIIconM ADDA      #$37          ; add A-F by $37 for ASCII rep
storehexM      STAA      1,Y-          ; store @ Y ptr and decrement Y
               PULA                    ; restore A
               LSRA                    ; shift A to the right by 4 bits
               LSRA                    
               LSRA                    
               LSRA                           
               CPY       #hexValBuf + 20 ; check if all of A is checked
               BNE       hexConvLoopM                                       
               
               LDX       #msgArrow
               JSR       printmsg
               LDX       #hexValBuf    ; load completed bin & hex into X
               JSR       printmsg      ; print @ X
               
               PULD                    ; restore D value
               LDY       #hexValBuf + 34 ;load last addr of buffer (excluding last NULL)
divLoop        PSHY                    ; save Y into stack
               LDY       #$00          ; set Y as NULL (EDIV takes Y:D)
               LDX       #$0A          ; load $A for division with D
               EDIV                    ; divide Y:D with $A from X; remainder @ D
               ADDB      #$30          ; convert number into ASCII representation
               TFR       Y,X           ; transfer quotient from Y to X (quotient)
               PULY                    ; restore Y (buffer ptr)               
               STAB      1,Y-          ; store B into mem @ Y (the buffer) & decrement Y
               TFR       X,D           ; transfer from X to D (quotient)
               CPX       #$00          ; comapre X (has quotient) if it's 0
               BNE       divLoop       ; if D not 0, div incomplete; continue div
               INY                     ; move Y ptr to first decimal nums
               TFR       Y,X           ; transfer ptr from Y to X
               JSR       printmsg
               RTS                     ; value shown, return

;**************************************************************
; Zero Buffer subroutine
; 
; Zeros out the buffer (depending on its size)
;
; Input: Buffer address @ Y with 0 in A
; Output: 0's out every addr in buffer till end
; Registers in use: B, Y 
; Memory locations in use: None

zeroBuff       PSHY                    ; stores Y
               PSHA                    ; stores A
               LDY       #buffer       ; loads buffer addr into Y
               LDAA      #0            ; loads 0 into A
buffLoop       STAA      1,Y+          ; stores A (0) into buffer @ Y & increment Y
               CPY       #buffer + 65  ; check if reached buffer length
               BNE       buffLoop      ; if not continue
               LDY       #wInputBuf    ; clearing wInputBuf (proper decimal checking)
wBuffLoop      STAA      1,Y+          ; stores A (0) into buffer @ Y & increment Y
               CPY       #wInputBuf + 8; check if reached buffer length
               BNE       wBuffLoop     ; if not continue
               PULA                    ; restore A
               PULY                    ; restore Y
               RTS                     

;**************************************************************
; Next line subroutine
;
; Program: Output character string to SCI port, goes to next line
; Input:   Register X points to ASCII characters in memory
; Output:  message printed on the terminal connected to SCI port
; 
; Registers modified: none
; Algorithm:
;     Pick up 1 byte from memory where X register is pointing
;     Send it out to SCI port
;     Update X register to point to the next byte
;     Repeat until the byte data $00 is encountered
;       (String is terminated with NULL=$00)

nextLine       PSHA
               LDAA      #CR           ; move cursor to beginning of line
               JSR       putchar
               LDAA      #LF           ; move cursor to next line
               JSR       putchar
               PULA
               RTS    

;**************************************************************
; Printing subroutine
;
; Program: Output character string to SCI port, print message
; Input:   Register X points to ASCII characters in memory
; Output:  message printed on the terminal connected to SCI port
; 
; Registers modified: CCR
; Algorithm:
;     Pick up 1 byte from memory where X register is pointing
;     Send it out to SCI port
;     Update X register to point to the next byte
;     Repeat until the byte data $00 is encountered
;       (String is terminated with NULL=$00)

NULL           EQU     $00
printmsg       PSHA                   ;Save registers
               PSHX
printmsgloop   LDAA    1,X+           ;pick up an ASCII character from string
                                      ;   pointed by X register
                                      ;then update the X register to point to
                                      ;   the next byte
               CMPA    #NULL
               BEQ     printmsgdone   ; if end of string, end subroutine
               JSR     putchar        ; if not, print character and do next
               BRA     printmsgloop

printmsgdone   PULX 
               PULA
               RTS

;**************************************************************
; Put char subroutine
;
; Program: Send one character to SCI port, terminal
; Input:   Accumulator A contains an ASCII character, 8bit
; Output:  Send one character to SCI port, terminal
; Registers modified: CCR
; Algorithm:
;    Wait for transmit buffer become empty
;      Transmit buffer empty is indicated by TDRE bit
;      TDRE = 1 : empty - Transmit Data Register Empty, ready to transmit
;      TDRE = 0 : not empty, transmission in progress

putchar        BRCLR   SCISR1,#%10000000,putchar   ; wait for transmit buffer empty
               STAA    SCIDRL                      ; send a character
               RTS

;**************************************************************
; Get char subroutine
;
; Program: Input one character from SCI port (terminal/keyboard)
;             if a character is received, other wise return NULL
; Input:   none    
; Output:  Accumulator A containing the received ASCII character
;          if a character is received.
;          Otherwise Accumulator A will contain a NULL character, $00.
; Registers modified: CCR
; Algorithm:
;    Check for receive buffer become full
;      Receive buffer full is indicated by RDRF bit
;      RDRF = 1 : full - Receive Data Register Full, 1 byte received
;      RDRF = 0 : not full, 0 byte received

getchar        BRCLR   SCISR1,#%00100000,getchar7
               LDAA    SCIDRL
               RTS
getchar7       CLRA
               RTS
            
*****************************************************************************

; OPTIONAL
; more variable/data section below
; this is after the program code section of the RAM.
; RAM ends at $3FFF in MC9S12C128 chip 
 
showMsg     DC.B       'S: Show the contents of memory location in word', $00
writeMsg    DC.B       'W: Write the data word (not byte) to memory location', $00
quitMsg     DC.B       "QUIT: Quit the main program, run 'Type writer' program.", $00
wrongInMsg  DC.B       'invalid input, address', $00
wrongDaMsg  DC.B       'invalid input, data', $00
msgt        DC.B       'Type-writing now, hit any keys:', $00
msgW        DC.B       'W recognized', $00
msgS        DC.B       'S recognized', $00
msgArrow    DC.B       " => %", $00       
            END                       ; last line of file              