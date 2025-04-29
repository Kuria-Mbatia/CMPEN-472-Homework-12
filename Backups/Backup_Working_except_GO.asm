***********************************************************************
*
* Title:          Simple Memory Access Program
* 
* Objective:      CMPEN 472 Homework 6
*
* Revision:       V1.7
*
* Date:           Feb. 28, 2025
*
* Programmer:     Kuria Mbatia
*
* Company:        The Pennsylvania State University
*
* Algorithm:      Simple SCI Serial I/O and Memory Access
*
* Register use:   A: Command processing, temp calculations
*                 B: Bit manipulation, counters
*                 X,Y: Pointers and memory access
*                 Z: Not used
*
* Memory use:     $3000-$30FF: Variables and data
*                 $3100-$xxxx: Program
*
* Input:          Terminal input via SCI port
*
* Output:         Terminal output via SCI port
*
* Observation:    This is a command-line memory access program that allows
*                 users to view and modify memory contents.
*
* Commands:       S$xxxx - Show the contents of memory location in word
*                 W$xxxx yyyy - Write data word to memory location
*                 QUIT - Quit program, run 'Type writer' program
*
***********************************************************************
* Parameter Declaration Section
*
* Export Symbols
            XDEF        pstart      ; Program entry point
            ABSENTRY    pstart      ; For absolute assembly

* Symbols and Macros
PORTB       EQU         $0001       ; Port B data register
DDRB        EQU         $0003       ; Port B data direction register

SCIBDH      EQU         $00C8       ; SCI Baud Register High
SCIBDL      EQU         $00C9       ; SCI Baud Register Low
SCICR2      EQU         $00CB       ; SCI Control Register 2
SCISR1      EQU         $00CC       ; SCI Status Register 1
SCIDRL      EQU         $00CF       ; SCI Data Register Low

CR          EQU         $0D         ; ASCII carriage return
LF          EQU         $0A         ; ASCII line feed
SPACE       EQU         $20         ; ASCII space
NULL        EQU         $00         ; ASCII null
DOLLAR      EQU         $24         ; ASCII $ character

; Define safe memory range for the program
SAFE_MEM_START EQU     $0000       ; Start of safe memory area (allow any address)
SAFE_MEM_END   EQU     $FFFF       ; End of safe memory area (allow any address)

MAX_CMD_LEN EQU         80          ; Maximum command length

***********************************************************************
* Data Section - Variables and Strings
***********************************************************************
            ORG         $4000       ; Start of data section - Moved from $3800 to avoid code overlap

cmdBuffer   DS.B        MAX_CMD_LEN ; Command input buffer
cmdLength   DS.B        1           ; Length of command
address     DS.W        1           ; Address for S/W commands
dataValue   DS.W        1           ; Data value for W command
tempPtr     DS.W        1           ; Temporary pointer for parsing
tempWord    DS.W        1           ; Temporary word for calculations
hexValid    DS.B        1           ; Temporary byte for hex validation
digCount    DS.B        1           ; Digit counter for parsing
inLDMode    DS.B        1           ; Flag to indicate if in LD mode (1=yes, 0=no)
debugFlag   DS.B        1           ; Flag for debug mode
decBuffer   DS.B        6           ; Buffer for decimal conversion

***********************************************************************
* Program Section
***********************************************************************
            ORG         $3100       ; Start of program section

; Program constants (all message strings in program section to save data space)
msgPrompt   DC.B        '>', NULL
msgLF       DC.B        CR, LF, NULL
welcome1    DC.B        'Welcome to the Simple Memory Access Program!', CR, LF, NULL
welcome2    DC.B        'Enter one of the following commands (examples shown below)', CR, LF, NULL
welcome3    DC.B        'and hit ', $27, 'Enter', $27, '.', CR, LF, CR, LF, NULL
example1    DC.B        '>S$3000                  ;to see the memory content at $3000 and $3001', CR, LF, NULL
example2    DC.B        '>W$3003 $126A            ;to write $126A to memory locations $3003 and $3004', CR, LF, NULL
example3    DC.B        '>W$3003 4714             ;to write $126A to memory location $3003 and $3004', CR, LF, NULL
example4    DC.B        '>MD$3000,$10             ;display 16 bytes starting from memory address $3000', CR, LF, NULL
example5    DC.B        '>LD$3050                 ;to load hex data to memory starting at $3050', CR, LF, NULL
example6    DC.B        '>GO$3050                 ;to execute program at memory location $3050', CR, LF, NULL
example7    DC.B        '>QUIT                    ;quit the Simple Memory Access Program', CR, LF, NULL
msgInvCmd   DC.B        'Invalid command. Use one of the following:', CR, LF
            DC.B        ' S$xxxx   - Show memory contents at address xxxx', CR, LF
            DC.B        ' W$xxxx v - Write value v to address xxxx (v can be decimal or $hex)', CR, LF
            DC.B        ' MD$xxxx,$yyyy - Display yyyy bytes of memory from xxxx (exactly as shown)', CR, LF
            DC.B        ' LD$xxxx - Load data to memory starting at xxxx', CR, LF
            DC.B        ' GO$xxxx - Execute program at address xxxx', CR, LF
            DC.B        ' QUIT     - Exit to typewriter mode', CR, LF, NULL
msgInvAddr  DC.B        'invalid input, address', CR, LF, NULL
msgInvData  DC.B        'invalid input, data', CR, LF, NULL
msgQuit     DC.B        'Type-writing now, hit any keys:', CR, LF, NULL
spaceArrow  DC.B        ' => ', NULL

; Add new message constants
msgNotImplemented DC.B 'Command recognized but not yet implemented.', CR, LF, NULL
msgMDHeader1  DC.B 'Memory display from $', NULL
msgMDHeader2  DC.B ' to $', NULL
msgMDHeader3  DC.B ' (', NULL
msgMDHeader4  DC.B ' bytes)', CR, LF, NULL
msgMDError    DC.B 'Error: Invalid MD command format. Use MD$xxxx,$yyyy (where xxxx = start address, yyyy = byte count)', CR, LF, NULL
msgMDComma    DC.B 'Error: Missing comma in MD command', CR, LF, NULL
msgMDRange    DC.B 'Error: Invalid range for MD command', CR, LF, NULL
msgLDPrompt   DC.B 'Enter hex data (32 chars per line = 16 bytes, empty line to end):', CR, LF
                  DC.B 'Example: 0123456789ABCDEF0123456789ABCDEF', CR, LF, NULL
msgLDError    DC.B 'Error: Invalid LD command format. Use LD$xxxx', CR, LF, NULL
msgLDComplete DC.B 'Data load complete.', CR, LF, NULL
msgLDInvalid  DC.B 'Error: Invalid hex data. Must be exactly 32 hex characters (0-9, A-F) per line.', CR, LF, NULL
msgLDSuccess  DC.B 'Loaded ', NULL
msgLDSuccess2 DC.B ' bytes to memory.', CR, LF, NULL
msgLDCommand  DC.B '-- Processing command while in LD mode --', CR, LF, NULL
msgLDLineOK   DC.B '* Line processed successfully - 16 bytes stored *', CR, LF, NULL
msgLDDebug    DC.B 'Debug - cmdLength = ', NULL
msgGOError    DC.B 'Error: Invalid GO command format. Use GO$xxxx', CR, LF, NULL
msgGOExecute  DC.B 'Executing program at $', NULL

; Add debug print macro to help diagnose issues
msgDebug    DC.B        'Debug: Value=', NULL

printDebug  
            ; Print debug message header
            PSHD                    ; Save D register
            
            LDX         #msgDebug
            JSR         printmsg
            
            ; Print value in D register
            PULD                    ; Restore D
            PSHD                    ; Save again
            JSR         printWordHex
            
            ; Print newline
            LDX         #msgLF
            JSR         printmsg
            
            PULD                    ; Restore D
            RTS

pstart      LDS         #$3F00      ; Initialize stack pointer to valid RAM area

            ; Initialize hardware
            LDAA        #%11111111  ; Set PORTB as output
            STAA        DDRB
            CLR         PORTB       ; Clear all outputs

            ; Initialize serial port - FIXED VALUES FOR 9600 BAUD AT 24MHZ
            CLR         SCIBDH      ; Set baud rate high byte to 0
            LDAA        #$9C        ; Low byte value for 9600 baud at 24MHz (156)
            STAA        SCIBDL      ; 24MHz/(16*156) = 9615 baud (close to 9600)
            LDAA        #$0C        ; Enable SCI transmitter and receiver
            STAA        SCICR2

            ; Clear all variables to make sure we start clean
            LDX         #cmdBuffer
            LDY         #debugFlag  ; End of variables
            
clearVars   CLR         0,X         ; Clear this variable
            INX                     ; Next variable
            CPX         Y           ; Reached the end?
            BLS         clearVars   ; If not, continue clearing
            
            ; Initialize specific variables
            CLR         inLDMode    ; Ensure we start in normal mode, not LD mode
            
            ; Show welcome message and instructions
            LDX         #welcome1
            JSR         printmsg
            LDX         #welcome2
            JSR         printmsg
            LDX         #welcome3
            JSR         printmsg
            
            ; Show example commands
            LDX         #example1
            JSR         printmsg
            LDX         #example2
            JSR         printmsg
            LDX         #example3
            JSR         printmsg
            LDX         #example4
            JSR         printmsg
            LDX         #example5
            JSR         printmsg
            LDX         #example6
            JSR         printmsg
            LDX         #example7
            JSR         printmsg

mainLoop    ; Reset the command length for next command
            CLR         cmdLength
            
            ; Show prompt
            LDX         #msgPrompt  ; Show prompt
            JSR         printmsg
            
            ; Get a new command
            JSR         getCommand  ; Get command from user
            TST         cmdLength   ; Check if command received
            LBEQ        mainLoop    ; If empty command, restart
            
            ; Process the command
            JSR         processCmd  ; Process the command
            
            ; Always return to the main loop
            LBRA        mainLoop    ; Return to main loop

***********************************************************************
* getCommand: Get command from user via serial input
*             Stores command in cmdBuffer and length in cmdLength
* Input:      None
* Output:     cmdBuffer, cmdLength
* Registers:  A, B, X, Y all modified
***********************************************************************
getCommand  
            ; Reset command length
            CLR         cmdLength   ; Reset command length
            
            ; Clear the entire command buffer first for safety
            LDX         #cmdBuffer  ; Point to command buffer
            LDY         #MAX_CMD_LEN ; Get buffer size
            
gcClearLoop CLR         0,X         ; Clear this byte
            INX                     ; Next byte
            DEY                     ; Decrement counter
            LBNE        gcClearLoop ; If not done, continue
            
            ; Now get the command
            LDY         #cmdBuffer  ; Reset to start of buffer
            
gcLoop      JSR         getchar     ; Get a character
            CMPA        #CR         ; Check for Enter key
            BEQ         gcDone      ; If so, done
            
            ; Check maximum command length
            LDAB        cmdLength
            CMPB        #MAX_CMD_LEN-1  ; Ensure space for null
            BHS         gcLoop      ; Ignore if too long
            
            JSR         putchar     ; Echo character
            STAA        0,Y         ; Store in buffer
            INY                     ; Next buffer position
            INC         cmdLength   ; Count the character (Moved here!)
            BRA         gcLoop      ; Get next character
            
gcDone      CLR         0,Y         ; Null-terminate buffer
            
            ; Print newline
            LDX         #msgLF
            JSR         printmsg
            
            RTS

***********************************************************************
* processCmd: Process the command in cmdBuffer
* Input:      cmdBuffer, cmdLength
* Output:     None
* Registers:  All modified
***********************************************************************
processCmd  
            LDX         #cmdBuffer  ; Point to command
            
            ; Check if we're in LD mode but this isn't being called from temporaryCommandMode
            ; If so, we should process the input as hex data for LD, not as a command
            LDAA        inLDMode
            BEQ         normalCommandMode  ; If not in LD mode, process normally
            
            ; If we're here, we're in LD mode but had a JSR directly to processCmd
            ; This would happen during loadMemoryBlock when a line doesn't start with a command
            ; Return to calling function (loadMemoryBlock) to process as data
            RTS
            
normalCommandMode:
            ; Check command length first
            LDAA        cmdLength
            CMPA        #1          ; At least 1 character needed
            BLO         invalidCmd
            
            ; Check first character - should be S, W, or Q (case insensitive)
            LDAA        0,X         ; Get first character
            
            ; Convert to uppercase for case-insensitive comparison
            CMPA        #'a'        ; Check if lowercase
            BLO         pcNotLower
            CMPA        #'z'
            BHI         pcNotLower
            SUBA        #$20        ; Convert to uppercase (a-z to A-Z)
            STAA        0,X         ; Store back to command buffer
            
pcNotLower  ; Now it's uppercase if it was lowercase
            CMPA        #'S'        ; Is it S command?
            LBEQ        procShowCmd
            
            CMPA        #'W'        ; Is it W command?
            LBEQ        procWriteCmd
            
            CMPA        #'M'        ; Is it MD command?
            LBEQ        checkMDCmd
            
            CMPA        #'L'        ; Is it LD command?
            LBEQ        checkLDCmd
            
            CMPA        #'G'        ; Is it GO command?
            LBEQ        checkGOCmd
            
            CMPA        #'Q'        ; Is it Q?
            LBNE        invalidCmd  ; If not a recognized command, invalid
            
            ; Check if command is "QUIT"
            LDAB        cmdLength
            CMPB        #4          ; Must be exactly 4 chars for QUIT
            LBNE        invalidCmd
            
            LDAA        1,X         ; Second character
            CMPA        #'U'
            LBNE        invalidCmd
            LDAA        2,X         ; Third character
            CMPA        #'I'
            LBNE        invalidCmd
            LDAA        3,X         ; Fourth character
            CMPA        #'T'
            LBNE        invalidCmd
            
doQuit      ; QUIT command - go to typewriter mode
            LDX         #msgQuit
            JSR         printmsg
            JSR         typewriter
            ; No return - typewriter loops forever
            
invalidCmd  LDX         #msgInvCmd   ; Invalid command message
            JSR         printmsg
            RTS                      ; Return to main loop

procShowCmd ; Process S command - format should be S$xxxx
            ; Check for minimum command length - need at least "S$X"
            LDAA        cmdLength
            CMPA        #3
            BLO         invalidCmd
            
            LDAA    1,X             ; must be '$'
            CMPA    #DOLLAR
            BNE     invalidCmd

            LEAX    2,X             ; X -> first hex digit
            STX     tempPtr        ; tempPtr = pointer for parser
            JSR     parseHexValue   ; returns value in D, C=1 if OK
            BCC     invalidAddr     ; C=0 → bad hex or >4 digits

            STD     address         ; save parsed 16-bit address
            
            ; Execute show memory command
            JSR         showMemory
            
            RTS
            
invalidAddr LDX         #msgInvAddr  ; Invalid address message
            JSR         printmsg
            RTS

procWriteCmd ; Process W command - format should be W$xxxx data
        ; Check for minimum command length - need at least "W$X v" (5 chars)
        LDAA    cmdLength
        CMPA    #5
        BLO     invalidCmd

        LDAA    1,X             ; Check second char must be '$'
        CMPA    #DOLLAR
        BNE     invalidCmd

        ; Parse the address part
        LEAX    2,X             ; X -> first potential hex digit of address
        STX     tempPtr         ; Save pointer for parseHexValue
        JSR     parseHexValue   ; D = address, C=1 if OK, tempPtr updated
        BCC     invalidAddr     ; Branch if parseHexValue failed (C=0)

        STD     address         ; Save the successfully parsed 16-bit address

        ; Clear data value variable before parsing new data
        LDD     #0
        STD     dataValue

        ; Find the space separating address and data
        ; parseHexValue updated tempPtr to point AFTER the address
        LDY     tempPtr         ; Y points to the char after the parsed address

findSpace
        LDAA    0,Y             ; Get character
        CMPA    #NULL           ; End of string?
        BEQ     invalidData     ; No data found after address
        CMPA    #SPACE          ; Is it a space?
        BEQ     foundSpace      ; Yes, found the separator

        ; If the character after the address isn't a space or NULL,
        ; it implies invalid command format (e.g., S$3000ABC)
        ; According to examples, data must follow a space.
        BRA     invalidData     ; Treat as invalid data format

foundSpace  ; Found space, now skip any *additional* spaces
skipSpaces
        INY                     ; Point past the space
        LDAA    0,Y             ; Get the next character
        CMPA    #SPACE          ; Is it another space?
        BEQ     skipSpaces      ; Yes, skip it and check again
        CMPA    #NULL           ; Is it the end of the string?
        BEQ     invalidData     ; No data value found after space(s)

        ; Y now points to the first character of the data value
        ; A contains the first character of the data value
        STY     tempPtr         ; Store this pointer for data parsing routines

        ; Check if data starts with '$' (hex)
        CMPA    #DOLLAR
        BEQ     parseW_HexData  ; Branch if it's hex data

        ; --- Parse data as Decimal ---
        ; tempPtr is already pointing to the first decimal digit
        JSR     parseDecValue   ; D = parsed value, C=1 if OK
        BCC     invalidData     ; Branch if decimal parse failed

        STD     dataValue       ; Store parsed decimal data
        JSR     writeMemory     ; Write to memory and display
        RTS                     ; Return to main loop

parseW_HexData
        ; Y was pointing to '$', A contained '$'
        INY                     ; Skip the '$'
        LDAA    0,Y             ; Check if anything follows '$'
        CMPA    #NULL
        BEQ     invalidData     ; Error if just '$' with no digits
        CMPA    #SPACE          ; Error if space right after '$'
        BEQ     invalidData
        ; Y now points to the first hex digit of the data
        STY     tempPtr         ; Update tempPtr for parseHexValue

        JSR     parseHexValue   ; D = parsed value, C=1 if OK
        BCC     invalidData     ; Branch if hex parse failed

        STD     dataValue       ; Store parsed hex data
        JSR     writeMemory     ; Write to memory and display
        RTS                     ; Return to main loop

invalidData
        LDX     #msgInvData     ; Invalid data message
        JSR     printmsg
        RTS

checkMDCmd   ; Check if command is MD (Memory Display)
            LDAA        cmdLength
            CMPA        #2          ; Must be at least 2 chars for MD
            LBLO        invalidCmd
            
            LDAA        1,X         ; Second character
            CMPA        #'D'
            LBNE        invalidCmd
            
            ; Check if format is MD$xxxx,yyyy
            LDAA        cmdLength
            CMPA        #8          ; Need at least MD$x,y
            LBLO        invalidMD
            
            LDAA        2,X         ; Check for $ after MD
            CMPA        #DOLLAR
            LBNE        invalidMD
            
            ; Now X points to 'M' in "MD$xxxx,yyyy"
            JSR         procMDCmd
            RTS

procMDCmd   ; Process the MD command - MD$xxxx,yyyy
            ; X points to the start of the command
            LEAX        3,X         ; Skip "MD$" to get to start address
            STX         tempPtr     ; Save pointer for address parsing
            
            ; Parse the starting address
            JSR         parseHexValue   ; Get starting address in D
            LBCC        invalidMD       ; If not valid hex, error
            
            STD         address         ; Store starting address
            
            ; Find the comma separator
            LDY         tempPtr         ; Get updated pointer after parseHexValue
            
findMDComma LDAA        0,Y             ; Get character
            CMPA        #NULL           ; End of string?
            LBEQ        invalidMDComma  ; No comma found
            CMPA        #','            ; Is it a comma?
            LBEQ        foundMDComma    ; Yes, found the separator
            INY                         ; Next character
            LBRA        findMDComma     ; Continue
            
invalidMDComma
            LDX         #msgMDComma     ; Error message
            JSR         printmsg
            RTS
            
foundMDComma
            ; Found comma, now parse the count/size
            INY                         ; Skip comma
            
            ; Skip any spaces after the comma
skipMDSpaces
            LDAA        0,Y             ; Get character after comma
            CMPA        #SPACE          ; Is it a space?
            LBNE        parseMDCount    ; If not a space, start parsing count
            INY                         ; Skip the space
            LBRA        skipMDSpaces    ; Check for more spaces
            
parseMDCount
            ; Check if the value starts with $ (hex prefix)
            CMPA        #DOLLAR
            LBNE        invalidMD       ; Must be hex with $ prefix
            INY                         ; Skip the $ character
            
            STY         tempPtr         ; Save pointer for count parsing
            
            ; Parse the count value
            JSR         parseHexValue   ; Get size/count in D
            LBCC        invalidMD       ; If not valid hex, error
            
            STD         dataValue       ; Store count in dataValue
            
            ; Calculate end address (start + count - 1)
            LDD         address         ; Get starting address
            ADDD        dataValue       ; Add count
            SUBD        #1              ; Subtract 1 for end address
            STD         tempWord        ; Store end address temporarily
            
            ; Validate address range
            CPD         #SAFE_MEM_END
            LBHI        invalidMDRange  ; End beyond memory limit
            
            ; Now display memory in 16-byte rows - without the verbose header
            JSR         displayMemoryBlock
            RTS
            
invalidMD   LDX         #msgMDError     ; Invalid MD command format
            JSR         printmsg
            RTS
            
invalidMDRange
            LDX         #msgMDRange     ; Invalid range
            JSR         printmsg
            RTS

checkLDCmd   ; Check if command is LD (Load Data)
            LDAA        cmdLength
            CMPA        #2          ; Must be at least 2 chars for LD
            LBLO        invalidCmd
            
            LDAA        1,X         ; Second character
            CMPA        #'D'
            LBNE        invalidCmd
            
            ; Check if format is LD$xxxx
            LDAA        cmdLength
            CMPA        #6          ; Need at least LD$x
            LBLO        invalidLD
            
            LDAA        2,X         ; Check for $ after LD
            CMPA        #DOLLAR
            LBNE        invalidLD
            
            ; Now X points to 'L' in "LD$xxxx"
            JSR         procLDCmd
            RTS

procLDCmd   ; Process the LD command - load data to memory
            ; X points to the start of the command
            LEAX        3,X         ; Skip "LD$" to get to start address
            STX         tempPtr     ; Save pointer for address parsing
            
            ; Parse the starting address
            JSR         parseHexValue   ; Get starting address in D
            LBCC        invalidLD       ; If not valid hex, error
            
            STD         address         ; Store starting address
            
            ; Display prompt for data entry
            LDX         #msgLDPrompt
            JSR         printmsg
            
            ; Initialize data load variables - ensure we properly clear to zero
            LDD         #0              ; Explicitly load 0
            STD         dataValue       ; Reset byte counter to 0
            
            ; Call the data load function
            JSR         loadMemoryBlock
            
            ; Show completion message with byte count (already displayed in loadMemoryBlock)
            
            ; Return to main command processing
            RTS

invalidLD   LDX         #msgLDError     ; Invalid LD command format
            JSR         printmsg
            RTS

checkGOCmd   ; Check if command is GO (Execute program)
            LDAA        cmdLength
            CMPA        #2          ; Must be at least 2 chars for GO
            LBLO        invalidCmd
            
            LDAA        1,X         ; Second character
            CMPA        #'O'
            LBNE        invalidCmd
            
            ; Check if format is GO$xxxx
            LDAA        cmdLength
            CMPA        #6          ; Need at least GO$x
            LBLO        invalidGO
            
            LDAA        2,X         ; Check for $ after GO
            CMPA        #DOLLAR
            LBNE        invalidGO
            
            ; Now X points to 'G' in "GO$xxxx"
            JSR         procGOCmd
            RTS

procGOCmd   ; Process the GO command - execute program at address
            ; X points to the start of the command
            LEAX        3,X         ; Skip "GO$" to get to start address
            STX         tempPtr     ; Save pointer for address parsing
            
            ; Parse the target address
            JSR         parseHexValue   ; Get address in D
            LBCC        invalidGO       ; If not valid hex, error
            
            STD         address         ; Store target address
            
            ; Display execute message
            LDX         #msgGOExecute
            JSR         printmsg
            
            LDD         address
            JSR         printWordHex    ; Print address
            
            LDX         #msgLF
            JSR         printmsg
            
            ; Execute program by jumping to target address
            LDX         address         ; Get target address in X
            JSR         0,X             ; Execute program (JSR to preserve return)
            
            ; Program returned, show prompt again
            RTS                         ; Return to main loop
            
invalidGO   LDX         #msgGOError     ; Invalid GO command format
            JSR         printmsg
            RTS

***********************************************************************
* parseHexValue  –  convert up to four hex digits to a 16-bit value
*   entry :  tempByte  → pointer to first digit ('0'–'9', 'A'–'F', 'a'–'f')
*   exit  :  D         = value (0-FFFFh)
*            tempByte  → first char that is not a hex digit
*            C-flag    = 1 success, 0 syntax error / > 4 digits
*   regs  :  A,B,X,Y clobbered
***********************************************************************

parseHexValue
            CLRA            ; D = 0
            CLRB
            STD   tempWord  ; tempWord will hold the running value
            LDY   tempPtr  ; Y traverses the string
            CLR   digCount

phv_loop    LDAA   0,Y            ; get next character
            JSR    isHexDigit
            BCC    phv_done       ; stop on first non-hex char

;------------ convert ASCII digit → 0-15 -------------------------------
            LDAA   0,Y
            JSR    hexCharToVal   ; A = nibble value (0-15)

;------------ value = (value << 4) + nibble ----------------------------
            PSHA                   ; save nibble on stack
            CLC                    ; *** clear carry BEFORE shifting ***

            LDD    tempWord        ; current 16-bit value
            LSLD                   ; ×2
            LSLD                   ; ×4
            LSLD                   ; ×8
            LSLD                   ; ×16
            STD    tempWord        ; store shifted value

            PULA                   ; A = nibble
            TAB                    ; B = nibble, A = 0
            CLRA
            ADDD   tempWord        ; add nibble
            STD    tempWord        ; save new result

            INY                    ; advance source pointer
            INC    digCount        ; count this digit
            LDAA   digCount
            CMPA   #4
            BLS    phv_loop        ; loop while ≤ 4 digits

            BRA    phv_error       ; >4 digits → error



phv_done    TST   digCount
            BEQ   phv_error         ; no digits at all
            STY   tempPtr          ; update caller's pointer
            LDD   tempWord
            SEC                     ; good exit
            RTS

phv_error   CLRA
            CLRB
            CLC
            RTS


***********************************************************************
* parseDecValue: Parse an unsigned decimal number from string
* Input:      tempPtr -> pointer to first potential decimal digit ('0'-'9')
* Output:     D         = Parsed decimal value (0-65535)
* tempPtr -> points to first char *after* parsed digits
* Carry flag = set if valid number parsed, clear if invalid/overflow/no digits
* Registers:  A, B, X, Y modified. Uses tempWord, digCount.
***********************************************************************
parseDecValue:
        CLR     digCount        ; Reset digit counter
        LDD     #0
        STD     tempWord        ; Initialize result = 0
        LDY     tempPtr         ; Y points to first potential char

pdvLoop:
        LDAA    0,Y             ; Get char into A
        JSR     isDecDigit      ; Check if A is '0'-'9'. C=1 if yes.
        BCC     pdvCheckEnd     ; If not a digit, go check if parsing should end

        ; --- It is a valid decimal digit ---
        LDX     tempWord        ; X = current result (for overflow check)
        LDAA    0,Y             ; Reload digit char into A
        SUBA    #'0'            ; A = digit value (0-9)
        PSHA                    ; *** Push digit value onto stack ***

        ; Check for potential overflow BEFORE multiplying/adding.
        ; Max value is 65535. Check if current_result * 10 + next_digit > 65535
        CPX     #6553           ; Compare current result with 6553
        BHI     pdvOverflow_Pop ; If X > 6553, then X*10 will definitely overflow

        ; If X == 6553, need to check if the incoming digit > 5
        BNE     pdvCanMultiply  ; If X < 6553, multiplication is safe
        ; X is exactly 6553. Check the digit.
        PULA                    ; *** Pop digit value to check it ***
        CMPA    #5              ; Compare digit with 5
        PSHA                    ; *** Push digit value back onto stack *** (still needed for add)
        BHI     pdvOverflow_Pop ; If X == 6553 and digit > 5, then 6553*10 + digit >= 65536 -> overflow

pdvCanMultiply:
        ; Digit value (0-9) is currently on the stack. Multiplication won't overflow.
        LDD     tempWord        ; D = current result
        ; Multiply D by 10 (using shifts and adds)
        CPD     #0              ; Check if current result is 0
        BEQ     pdvAddDigit_Pop ; If result is 0, skip multiply, just add digit (which is on stack)

        ; Multiply non-zero result by 10: D = D*10 = (D*8 + D*2)
        XGDX                    ; Save D (current result) in X temporarily
        LSLD                    ; D = D*2
        LSLD                    ; D = D*4
        LSLD                    ; D = D*8
        ADDD    X               ; D = (D*8) + (original D saved in X) = D*10
        ; No BCS check needed here as overflow was pre-checked
        STD     tempWord        ; Store D*10 result temporarily

pdvAddDigit_Pop:
        ; Digit value (0-9) is still on the stack
        PULA                    ; *** Pop digit value from stack into A ***
        TAB                     ; B = digit value
        CLRA                    ; D = 000 : digit_value
        ADDD    tempWord        ; D = (Result*10) + digit_value
        BCS     pdvOverflow     ; If final add overflows (e.g., 65530 + 6), it's an error. (Stack is clean here)
        STD     tempWord        ; Store final new result

        INC     digCount        ; Count this valid digit
        INY                     ; Advance string pointer Y
        BRA     pdvLoop         ; Go process next character

pdvCheckEnd:
        ; Reached here because current char (in A from pdvLoop) is not a decimal digit
        ; Check if it's a valid terminator (NULL or SPACE)
        CMPA    #NULL
        BEQ     pdvFinalCheck
        CMPA    #SPACE
        BEQ     pdvFinalCheck
        ; If it's neither NULL nor SPACE, it's an invalid character mid-number
        BRA     pdvError        ; Go to error exit

pdvFinalCheck:
        ; Reached end (NULL or SPACE) after parsing potentially valid digits
        TST     digCount        ; Were any digits actually parsed?
        BEQ     pdvError        ; If count is 0 (no digits found), it's an error
        ; Valid decimal number parsed (1 or more digits)
        STY     tempPtr         ; Update caller's pointer to point after the parsed digits
        LDD     tempWord        ; Load the final result into D
        SEC                     ; Set Carry flag for success
        RTS

pdvOverflow_Pop:
        PULA                    ; *** Pop the digit value off stack before error exit ***
pdvOverflow:
        ; Overflow detected during multiplication or final add
pdvError:
        ; Common error exit (invalid char, no digits, overflow)
        CLC                     ; Clear Carry flag for error
        LDD     #0              ; Return 0 in D (optional)
        RTS
        
***********************************************************************
* isHexDigit: Check if A contains a valid hex digit
* Input:      A - ASCII character to check
* Output:     Carry flag - set if valid hex digit, clear if not
* Registers:  A preserved
***********************************************************************
isHexDigit  PSHA                    ; Save A
            
            CMPA        #'0'
            BLO         notHexDigit
            CMPA        #'9'
            BLS         validHexDigit
            CMPA        #'A'
            BLO         notHexDigit
            CMPA        #'F'
            BLS         validHexDigit
            CMPA        #'a'
            BLO         notHexDigit
            CMPA        #'f'
            BLS         validHexDigit
            
notHexDigit CLC                     ; Clear carry - not a hex digit
            PULA                    ; Restore A
            RTS
            
validHexDigit
            SEC                     ; Set carry - valid hex digit
            PULA                    ; Restore A
            RTS

***********************************************************************
* showMemory: Display memory contents for S command
* Input:      address - Memory address to display
* Output:     Terminal display
* Registers:  All modified
***********************************************************************
showMemory  
            ; Display memory at address in the format:
            ; $3000 => %0001001001101010 $126A 4714
            
            ; Print space at beginning of line for better alignment
            LDAA        #SPACE
            JSR         putchar
            
            ; Print the address with $ prefix
            LDAA        #DOLLAR
            JSR         putchar
            
            ; Debug: print the actual address we're about to use (not the one from the command)
            LDD         address
            JSR         printWordHex
            
            ; Print " => "
            LDX         #spaceArrow
            JSR         printmsg
            
            ; Read memory from the address
            LDX         address      ; Load address into X register
            LDD         0,X          ; Read word from memory at X
            STD         dataValue    ; Store for display
            
            ; Print binary format with % prefix
            LDAA        #'%'
            JSR         putchar
            
            ; Print high byte in binary
            LDAA        dataValue    ; Get high byte
            JSR         printByteBin
            
            ; Print low byte in binary
            LDAA        dataValue+1  ; Get low byte
            JSR         printByteBin
            
            ; Print spaces (exactly 4 spaces)
            LDAA        #SPACE
            JSR         putchar
            JSR         putchar
            JSR         putchar
            JSR         putchar
            
            ; Print hex format with $ prefix
            LDAA        #DOLLAR
            JSR         putchar
            
            ; Print data in hex
            LDD         dataValue    ; Load data value
            JSR         printWordHex
            
            ; Print spaces (exactly 4 spaces)
            LDAA        #SPACE
            JSR         putchar
            JSR         putchar
            JSR         putchar
            JSR         putchar
            
            ; Print decimal value
            LDD         dataValue    ; Load data value
            JSR         printWordDec
            
            ; Print newline
            LDX         #msgLF
            JSR         printmsg
            
            RTS

***********************************************************************
* writeMemory: Write to memory for W command
* Input:      address - Memory address to write to
*             dataValue - Data value to write
* Output:     Terminal display showing written data
* Registers:  All modified
***********************************************************************
writeMemory
            ; Write the data value to memory
            LDX         address      ; Load address into X register
            LDD         dataValue    ; Get data to write
            STD         0,X          ; Store to memory at X
            
            ; Now display the result 
            JSR         showMemory
            
            RTS

***********************************************************************
* printByteBin: Print a byte in binary format (8 bits) - CORRECTED
* Input:      A - byte to print
* Output:     Prints 8 '0' or '1' characters
* Registers:  A, B modified
***********************************************************************
printByteBin:
            PSHA                    ; Save original byte A
            LDAB        #8          ; B = loop counter (8 bits)
            ; A holds the byte whose bits we want to print, MSB first
pBinLoop_Fixed:
            ASLA                    ; Shift MSB of A into Carry. A is modified (shifted left).
            PSHA                    ; Save modified A (because putchar clobbers A)
            LDAA        #'0'        ; Assume bit was 0
            BCC         pBinZero_Fixed ; If Carry Clear, bit was 0
            LDAA        #'1'        ; If Carry Set, bit was 1
pBinZero_Fixed:
            JSR         putchar     ; Print '0' or '1'
            PULA                    ; Restore modified A (shifted value)
            DECB                    ; Decrement bit counter
            BNE         pBinLoop_Fixed; Loop for all 8 bits

            PULA                    ; Restore original A from the start
            RTS
***********************************************************************
* printByteHex: Print a byte in hexadecimal format
* Input:      A - byte to print
* Output:     Terminal display
* Registers:  A, B modified
***********************************************************************
printByteHex
            PSHA                    ; Save original value
            
            ; Print high nibble
            TAB                     ; Copy to B
            LSRB                    ; Shift right four times
            LSRB
            LSRB
            LSRB
            ANDB        #$0F        ; Mask to 4 bits
            ADDB        #'0'        ; Convert to ASCII
            CMPB        #'9'+1
            BLO         pHex1
            ADDB        #7          ; Adjust for A-F
pHex1       TBA                     ; Transfer B to A
            JSR         putchar
            
            ; Print low nibble
            PULA                    ; Restore value
            ANDA        #$0F        ; Mask to low 4 bits
            ADDA        #'0'        ; Convert to ASCII
            CMPA        #'9'+1
            BLO         pHex2
            ADDA        #7          ; Adjust for A-F
pHex2       JSR         putchar
            
            RTS

***********************************************************************
* printWordHex: Print a 16-bit word in hexadecimal format
* Input:      D - word to print (A:B)
* Output:     Terminal display
* Registers:  A, B modified (uses PSHB/PULB internally)
***********************************************************************
printWordHex
        PSHB            ; Save original Low Byte (B) from D register onto stack
        ; A still holds the original High Byte from D register
        JSR printByteHex ; Print High Byte (using A). This call modifies A and B.
        PULB            ; Restore original Low Byte from stack into B.
        TBA             ; Transfer original Low Byte (now in B) into A.
        JSR printByteHex ; Print original Low Byte (now in A). Modifies A, B again.
        RTS             ; Return. Stack is balanced.
***********************************************************************
* printWordDec: Print a 16-bit word in decimal format
* Input:      D - word to print
* Output:     Terminal display
* Registers:  A, B, X, Y modified (PSHX/Y, PULX/Y used)
***********************************************************************
printWordDec
        PSHX                    ; Save X
        PSHY                    ; Save Y
        
        CLR     digCount        ; Use memory variable for count, clear it first

        ; Special case for zero
        CPD     #0
        BNE     pwdNZ_v9
        LDAA    #'0'
        JSR     putchar
        BRA     pwdDone_v9      ; Go directly to cleanup/RTS

pwdNZ_v9
        ; --- Division loop ---
pwdDivLoop_v9
        LDX     #10             ; X = Divisor = 10
        ; D = number to divide
        IDIV                    ; D / X => X = Quotient, D = Remainder
        ; Remainder (0-9) is now in D (specifically B)
        PSHB                    ; Push Remainder (B) onto stack
        INC     digCount        ; Increment counter in memory
        TFR     X,D             ; D = Quotient
        CPD     #0
        BNE     pwdDivLoop_v9   ; Loop if quotient != 0

        ; --- Print loop ---
        ; digCount holds the count of digits pushed.
pwdPrintLoop_v9
        LDAA    digCount        ; Load count into A
        BEQ     pwdDone_v9      ; Branch if count is zero (finished)
        DEC     digCount        ; Decrement count in memory *before* popping/printing
        PULB                    ; Pop digit (Remainder 0-9) into B
        ADDB    #'0'            ; Convert popped digit to ASCII IN B
        TBA                     ; Transfer ASCII char from B to A
        JSR     putchar         ; Print the digit
        BRA     pwdPrintLoop_v9 ; Loop back to check count again

pwdDone_v9
        PULY                    ; Restore original Y
        PULX                    ; Restore original X
        RTS

***********************************************************************
* typewriter: Simple typewriter program
* Input:      None
* Output:     Echo input characters until reset
* Registers:  A modified
***********************************************************************
typewriter  JSR         getchar     ; Get a character
            JSR         putchar     ; Echo the character
            BRA         typewriter  ; Loop forever

***********************************************************************
* Utility Subroutines
***********************************************************************

***********************************************************************
* printmsg: Print a null-terminated string
* Input:      X - pointer to string
* Output:     Terminal display
* Registers:  A modified, X preserved
***********************************************************************
printmsg    PSHX                    ; Save X
pmsgLoop    LDAA        0,X         ; Get character
            BEQ         pmsgDone    ; If null, done
            JSR         putchar     ; Print it
            INX                     ; Next character
            BRA         pmsgLoop    ; Continue
pmsgDone    PULX                    ; Restore X
            RTS

***********************************************************************
* putchar: Send one character to the terminal
* Input:      A - character to send
* Output:     Terminal display
* Registers:  A preserved
***********************************************************************
putchar     PSHA                    ; Save A
pcharLoop   LDAA        SCISR1      ; Get status
            ANDA        #$80        ; Check TDRE bit
            BEQ         pcharLoop   ; Wait until transmitter ready
            PULA                    ; Restore A
            STAA        SCIDRL      ; Send character
            RTS

***********************************************************************
* getchar: Get one character from the terminal
* Input:      None
* Output:     A - received character
* Registers:  A modified
***********************************************************************
getchar     LDAA        SCISR1      ; Get status
            ANDA        #$20        ; Check RDRF bit
            BEQ         getchar     ; Wait until receiver has data
            LDAA        SCIDRL      ; Get character
            RTS

***********************************************************************
* hexCharToVal: Convert hex character to its value
* Input:      A - ASCII hex character ('0'-'9', 'A'-'F', 'a'-'f')
* Output:     A - Value (0-15) or $FF if invalid
* Registers:  A modified
***********************************************************************
hexCharToVal
            ; Check if digit 0-9
            CMPA        #'0'
            BLO         hctvInvalid  ; Below '0'
            CMPA        #'9'
            BHI         hctvNotDigit ; Above '9'
            
            ; It's a digit 0-9
            SUBA        #'0'         ; Convert to value 0-9
            RTS
            
hctvNotDigit
            ; Check if uppercase A-F
            CMPA        #'A'
            BLO         hctvInvalid  ; Below 'A'
            CMPA        #'F'
            BHI         hctvNotUpper ; Above 'F'
            
            ; It's uppercase A-F
            SUBA        #'A'         ; Subtract 'A'
            ADDA        #10          ; Add 10 for value 10-15
            RTS
            
hctvNotUpper
            ; Check if lowercase a-f
            CMPA        #'a'
            BLO         hctvInvalid  ; Below 'a'
            CMPA        #'f'
            BHI         hctvInvalid  ; Above 'f'
            
            ; It's lowercase a-f
            SUBA        #'a'         ; Subtract 'a'
            ADDA        #10          ; Add 10 for value 10-15
            RTS
            
hctvInvalid  
            LDAA        #$FF         ; Invalid character
            RTS

***********************************************************************
* isDecDigit: Check if A contains a valid decimal digit
* Input:      A - ASCII character to check
* Output:     Carry flag - set if valid decimal digit, clear if not
* Registers:  A preserved
***********************************************************************
isDecDigit  PSHA                    ; Save A
            
            CMPA        #'0'
            BLO         notDecDigit
            CMPA        #'9'
            BLS         validDecDigit
            
notDecDigit CLC                     ; Clear carry - not a decimal digit
            PULA                    ; Restore A
            RTS
            
validDecDigit
            SEC                     ; Set carry - valid decimal digit
            PULA                    ; Restore A
            RTS

***********************************************************************
* displayMemoryBlock: Display a block of memory in 16-byte rows
* Input:      address - starting address
*             dataValue - number of bytes to display
*             tempWord - ending address
* Output:     Terminal display
* Registers:  All modified
***********************************************************************
displayMemoryBlock
            ; Calculate number of rows to display
            LDD         dataValue
            ADDD        #15            ; Round up to include partial row
            LSRD                       ; Divide by 16 (shift right 4 times)
            LSRD
            LSRD
            LSRD
            STD         digCount       ; Store row count in digCount
            
            ; Ensure at least one row
            LDD         digCount
            CPD         #0
            LBNE        startDisplay   ; If not zero, continue
            LDD         #1             ; Otherwise set to 1 row
            STD         digCount
            
startDisplay
            ; Calculate end address for display
            LDD         address        ; Start address
            ADDD        dataValue      ; Add count
            SUBD        #1             ; Subtract 1 for end address
            STD         tempWord       ; Store end address
            
            ; Start with the memory address aligned to 16-byte boundary
            LDD         address        ; Start address
            ANDB        #$F0           ; Clear low 4 bits (16-byte alignment)
            STD         tempPtr        ; Store aligned address
            
displayRowLoop
            ; Print row address
            LDAA        #'0'           ; Add leading zero for aesthetics
            JSR         putchar
            
            LDD         tempPtr
            JSR         printWordHex   ; Print current row address
            LDAA        #SPACE
            JSR         putchar
            
            ; Print 16 bytes in hex
            LDY         #16            ; Count 16 bytes per row
            LDX         tempPtr        ; X points to current byte
            
displayByteLoop
            ; Get and display the byte
            LDAA        0,X            ; Get byte at address X
            JSR         printByteHex   ; Print in hex
            
            ; Print a space after each byte
            LDAA        #SPACE
            JSR         putchar
            
            ; Move to next byte
            INX                      ; Next byte in memory
            DEY                      ; Decrement counter
            LBNE        displayByteLoop ; Continue until row done
            
            ; Print dots and command indicator at end of row
            LDAA        #'.'
            LDAB        #5
dotLoop     JSR         putchar
            DECB
            LBNE        dotLoop
            
            ; Check if in first row to show command
            LDD         digCount
            CPD         #1
            LBNE        skipCmd
            
            ; Show command on first row only
            LDAA        #'M'
            JSR         putchar
            LDAA        #'D'
            JSR         putchar
            LDAA        #'$'
            JSR         putchar
            
            ; Show the starting address
            LDD         address
            JSR         printWordHex
            
            LDAA        #','
            JSR         putchar
            LDAA        #'$'
            JSR         putchar
            
            ; Show byte count
            LDD         dataValue
            JSR         printWordHex
            
skipCmd     ; End of row, print newline
            LDX         #msgLF
            JSR         printmsg
            
            ; Move to next row
            LDD         tempPtr
            ADDD        #16            ; Add 16 to move to next row
            STD         tempPtr
            
            ; Decrement row counter
            LDD         digCount
            SUBD        #1
            STD         digCount
            
            ; Continue if not done
            LDD         digCount
            CPD         #0
            LBNE        displayRowLoop
            
            RTS

***********************************************************************
* loadMemoryBlock: Load data from serial input to memory
* Input:      address - starting address for data
* Output:     dataValue - number of bytes loaded
* Registers:  All modified
***********************************************************************
loadMemoryBlock
            ; Set up memory pointer
            LDD         address     ; Get target address
            STD         tempWord    ; Save memory pointer in tempWord
            
            ; Initialize byte counter to 0
            LDD         #0
            STD         dataValue
            
            ; Set LD mode flag to indicate we're in LD mode
            LDAA        #1
            STAA        inLDMode
            
            ; Start the main loop for loading data
ldNextLine
            ; Show prompt for next line
            LDX         #msgPrompt
            JSR         printmsg
            
            ; Clear command buffer before getting input
            LDX         #cmdBuffer
            LDY         #MAX_CMD_LEN
            
ldClearLoop CLR         0,X
            INX
            DEY
            BNE         ldClearLoop
            
            ; Get input line
            JSR         getCommand
            
            ; Check if empty line (just Enter pressed)
            LDAA        cmdLength  
            LBEQ         ldDone     ; If empty, done with loading
            
            ; Check if line starts with a command letter
            LDX         #cmdBuffer
            LDAA        0,X
            
            ; Check against common command letters: S, W, M, G, Q, L
            CMPA        #'S'
            BEQ         ldProcCmd
            CMPA        #'s'
            BEQ         ldProcCmd
            CMPA        #'W'
            BEQ         ldProcCmd
            CMPA        #'w'
            BEQ         ldProcCmd
            CMPA        #'M'
            BEQ         ldProcCmd
            CMPA        #'m'
            BEQ         ldProcCmd
            CMPA        #'G'
            BEQ         ldProcCmd
            CMPA        #'g'
            BEQ         ldProcCmd
            CMPA        #'Q'
            BEQ         ldProcCmd
            CMPA        #'q'
            BEQ         ldProcCmd
            CMPA        #'L'
            BEQ         ldProcCmd
            CMPA        #'l'
            BEQ         ldProcCmd
            
            ; Not a command, check for valid hex data
            LDAA        cmdLength
            CMPA        #32
            BNE         ldInvalid   ; Must be exactly 32 characters
            
            ; Process the valid 32-character hex data
            LDX         #cmdBuffer   ; Input buffer
            LDY         tempWord     ; Current memory location
            LDAB        #16          ; Process 16 bytes
            
ldByteLoop  ; Process two hex chars into one byte
            ; First hex character
            LDAA        0,X
            JSR         hexCharToVal
            CMPA        #$FF
            BEQ         ldInvalid
            
            ; Shift to high nibble
            ASLA
            ASLA
            ASLA
            ASLA
            STAA        hexValid
            
            ; Second hex character
            LDAA        1,X
            JSR         hexCharToVal
            CMPA        #$FF
            BEQ         ldInvalid
            
            ; Combine with high nibble
            ORAA        hexValid
            
            ; Store byte to memory
            STAA        0,Y
            INY
            
            ; Move to next pair of hex chars
            INX
            INX
            
            ; Decrement byte counter and loop
            DECB
            BNE         ldByteLoop
            
            ; Successfully processed line - update status
            STY         tempWord     ; Save updated memory pointer
            
            ; Update total byte counter
            LDD         dataValue
            ADDD        #16
            STD         dataValue
            
            ; Print success message
            LDX         #msgLDLineOK
            JSR         printmsg
            
            ; Go directly to completion after one line
            LBRA        ldDone
            
ldProcCmd   ; Process a command while in LD mode
            ; First, exit LD mode temporarily
            CLR         inLDMode
            
            ; Show message indicating command processing
            LDX         #msgLDCommand
            JSR         printmsg
            
            ; Save ALL registers that might be modified
            PSHX                    ; X register
            PSHY                    ; Y register
            PSHB                    ; B register
            PSHA                    ; A register
            
            ; Also save the important variables before calling command
            LDD         tempWord    ; Memory pointer for LD
            PSHD
            LDD         dataValue   ; Byte counter
            PSHD
            
            ; Process the command - let it modify registers freely
            JSR         processCmd
            
            ; Restore the important variables
            PULD                    ; Restore byte counter
            STD         dataValue
            PULD                    ; Restore memory pointer
            STD         tempWord
            
            ; Restore all registers
            PULA                    ; A register
            PULB                    ; B register
            PULY                    ; Y register
            PULX                    ; X register
            
            ; Return to LD mode
            LDAA        #1
            STAA        inLDMode
            
            ; Show a reminder about being in LD mode
            LDX         #msgLDPrompt
            JSR         printmsg
            
            ; Continue with next line - make sure to use LBRA for long branch
            LBRA        ldNextLine
            
ldInvalid   ; Handle invalid hex data
            LDX         #msgLDInvalid
            JSR         printmsg
            
            ; Continue with next line
            LBRA         ldNextLine
            
ldDone      ; Data loading complete
            ; First, reset LD mode flag
            CLR         inLDMode
            
            ; Show completion message
            LDX         #msgLDComplete
            JSR         printmsg
            
            ; Show total bytes loaded - with clear steps
            LDX         #msgLDSuccess
            JSR         printmsg
            
            ; Get and display the byte count 
            LDD         dataValue    ; Load byte count into D
            JSR         printWordDec ; Print byte count as decimal
            
            ; Show completion message suffix
            LDX         #msgLDSuccess2
            JSR         printmsg
            
            ; Return to main command processing
            RTS

            END                     ; End of program