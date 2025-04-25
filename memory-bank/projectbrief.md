# Project Brief: CMPEN 472 Homework 12

## Overview
This project is part of CMPEN 472, an embedded systems course at The Pennsylvania State University. The project builds upon Homework 6, which implemented a Simple Memory Access Program for the HCS12 microcontroller.

## Core Requirements
- Build upon the Simple Memory Access Program from Homework 6
- Implement memory access and manipulation functionality
- Support command-line interface via SCI serial port
- Handle memory safety and validation
- Maintain code documentation and organization standards

## Goals
- Successfully extend the Homework 6 memory access program
- Implement robust memory access and modification features
- Create well-documented and maintainable code
- Follow proper embedded systems programming practices

## Project Structure
- Previous_Project_Code/ - Contains previous homework implementations including:
  - cmpen472hw1_mbatia.asm - StarFill program
  - cmpen472hw2_Mbatia.asm - LED Light Blinking program
  - cmpen472hw6_Mbatia-1.asm - Original Memory Access Program
  - cmpen472hw8_Mbatia.asm - Additional functionality
  - cmpen472hw11_mbatia.asm - Recent work
- Project/ - Main directory for current implementation
  - Sources/main.asm - Main program file
  - bin/ - Binary and debug files

## Core Functionality
Based on Homework 6 implementation:
1. Command-line interface via SCI serial port
2. Memory access commands:
   - S$xxxx - Show contents of memory location in word format
   - W$xxxx yyyy - Write data word to memory location
   - QUIT - Exit to typewriter program
3. Memory safety features:
   - Address validation
   - Safe memory range checks
   - Error handling

## Resources
- Homework12_Instructions.pdf - Main instructions for the assignment
- Homework12_Grading_Sheet.pdf - Grading criteria
- Homework6_Instructions.pdf - Base implementation reference
- HW6aid1etc (1).pdf - Supplementary material
- HW6aid2etc (1).pdf - Additional supplementary material

## Timeline
- Due date to be determined from assignment instructions

*Note: This document will be updated with additional details as needed.* 