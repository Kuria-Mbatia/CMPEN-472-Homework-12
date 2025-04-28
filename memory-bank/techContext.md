# Technical Context

## Technologies Used
This project is implemented for the HCS12 microcontroller platform using assembly language. It builds upon previous homework assignments in the CMPEN 472 course, extending the memory access functionality from Homework 6 into a comprehensive MONITOR program.

## Development Environment
- CodeWarrior development software
- HCS12 assembly language
- Axiom Manufacturing's CSM-12C128 board (24MHz)
- Terminal emulator for SCI communication

## Hardware
1. HCS12 Microcontroller
   - Port B for I/O operations
   - SCI interface for serial communication
   - Memory-mapped I/O registers

2. Port Configurations
   - PORTB ($0001): Data register
   - DDRB ($0003): Data direction register
   - SCI registers:
     - SCIBDH ($00C8): Baud Rate Register High
     - SCIBDL ($00C9): Baud Rate Register Low
     - SCICR2 ($00CB): Control Register 2
     - SCISR1 ($00CC): Status Register 1
     - SCIDRL ($00CF): Data Register Low

## Software Components
1. Core Program Files:
   - main.asm: Main program implementation
   - Previous homework implementations for reference

2. Memory Organization:
   - Variables: $3000-$30FF
   - Program code: $3100-$xxxx
   - Safe memory range: entire addressable range
   - Memory display: 16-byte aligned boundaries

3. Register Usage:
   - A: Command processing, calculations
   - B: Bit manipulation, counters
   - X,Y: Memory pointers and access
   - Z: Not used

4. Command Structure:
   - S$xxxx: Show memory word in multiple formats
   - W$xxxx yyyy: Write data to memory
   - MD$xxxx $yyyy: Display memory block
   - LD$xxxx $yyyy: Load data block to memory
   - GO$xxxx: Execute program
   - QUIT: Exit program

## Dependencies
1. Previous Project Code:
   - cmpen472hw6_Mbatia-1.asm: Base memory access implementation
   - Other homework implementations for reference

2. System Dependencies:
   - HCS12 instruction set
   - SCI communication protocol
   - Terminal I/O capabilities

## Technical Implementation Requirements
1. Memory Display (MD command):
   - Display memory in 16-byte rows
   - Format: Address followed by 16 byte values in hex
   - Always start at 16-byte boundary that occurs before specified address
   - Always end at 16-byte boundary that occurs after specified end address

2. Data Loading (LD command):
   - Accept address and block size
   - Process 16-byte lines of hex data
   - Store in specified memory locations
   - Support multiple lines of input

3. Binary/Decimal/Hex Conversions:
   - Convert values between formats
   - Display memory word as:
     - Binary: %xxxxxxxxxxxxxxxx
     - Hex: $xxxx
     - Decimal: xxxxx

4. Program Execution (GO command):
   - Validate address
   - Transfer program control to specified address
   - Ensure safe execution

## Build Process
1. Assembly:
   - Use CodeWarrior for assembly and linking
   - Absolute assembly with entry point 'pstart'

2. Deployment:
   - Program loaded to specific memory locations
   - Variables initialized in data section
   - Program execution from $3100

## Debugging & Testing
1. Debug Features:
   - Serial output for status messages
   - Error reporting via terminal
   - Memory content verification
   - Block memory display for inspection

2. Testing Methods:
   - Command syntax validation
   - Memory access verification
   - Error handling checks
   - Boundary condition testing
   - Block memory operations validation
   - Test program execution (Choi example)

## Technical Constraints
1. Memory Organization:
   - Program must start at $3100
   - Data must start at $3000
   - Support memory operations across entire addressable range
   - Memory display aligned to 16-byte boundaries

2. Hardware Constraints:
   - HCS12 processor capabilities
   - Serial communication timing
   - Register availability

3. Performance Requirements:
   - Efficient memory access
   - Responsive command processing
   - Reliable error handling
   - Efficient block memory operations

4. Display Format Requirements:
   - Binary: %xxxxxxxxxxxxxxxx (16 bits)
   - Hex: $xxxx (4 digits)
   - Decimal: xxxxx (no leading zeros)
   - Memory display: rows of 16 bytes

## Submission Requirements
- Copy 'main.asm' to 'cmpen472hw12_mbatia.asm'
- Submit the .asm file (not zipped) via CANVAS
- Due date: April 25, 2025 at 11:30pm 