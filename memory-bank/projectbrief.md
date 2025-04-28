# Project Brief: CMPEN 472 Homework 12

## Overview
This project is part of CMPEN 472, an embedded systems course at The Pennsylvania State University. The assignment implements a serial port-based MONITOR program for the HCS12 microcontroller, building upon the memory access functionality from Homework 6.

## Core Requirements
- Implement a user-friendly MONITOR program with six commands
- Support comprehensive memory access and manipulation functionality
- Provide continuous memory display and data loading features
- Enable program execution from specified memory locations
- Support command-line interface via SCI serial port
- Handle memory safety and validation for all operations
- Maintain code documentation and organization standards

## Goals
- Successfully implement all six required commands
- Create a robust memory monitoring and manipulation system
- Implement comprehensive error handling
- Create well-documented and maintainable code
- Follow proper embedded systems programming practices

## Command Set
1. S$xxxx - Show memory content in word format (binary, hex, decimal)
2. W$xxxx yyyy - Write word to memory (accepts decimal or hex input)
3. MD$xxxx $yyyy - Display contents of continuous memory locations
4. LD$xxxx $yyyy - Load block of data to continuous memory locations
5. GO$xxxx - Run program at specified memory location
6. QUIT - Exit to typewriter program

## Project Structure
- Previous_Project_Code/ - Contains previous homework implementations including:
  - cmpen472hw1_mbatia.asm - StarFill program
  - cmpen472hw2_Mbatia.asm - LED Light Blinking program
  - cmpen472hw6_Mbatia-1.asm - Original Memory Access Program
  - cmpen472hw8_Mbatia.asm - Additional functionality
  - cmpen472hw11_mbatia.asm - Recent work
- Project/ - Main directory for current implementation
  - Sources/main.asm - Main program file (to be copied as cmpen472hw12_mbatia.asm for submission)
  - bin/ - Binary and debug files

## Memory Organization
- Program starts at $3100
- Data section starts at $3000
- Support for memory operations across entire addressable range
- Memory display aligned to 16-byte boundaries

## Error Handling Requirements
- Comprehensive input validation for all commands
- Clear error messages for invalid inputs
- Command usage examples provided for incorrect use
- Program must not crash or hang on invalid input

## Resources
- Homework12_Instructions.pdf - Main instructions for the assignment
- Homework12_Grading_Sheet.pdf - Grading criteria
- Homework6_Instructions.pdf - Base implementation reference
- HW6aid1etc (1).pdf - Supplementary material for numerical input/output
- HW6aid2etc (1).pdf - Visual debugging guide

## Timeline
- Due date: April 25, 2025 at 11:30pm

## Submission Requirements
- Copy 'main.asm' to 'cmpen472hw12_mbatia.asm'
- Submit the .asm file (not zipped) via Penn State CANVAS

*Note: This document will be updated with additional details as needed.* 