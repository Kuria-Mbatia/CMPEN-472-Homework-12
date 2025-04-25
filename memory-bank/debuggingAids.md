# Debugging Aids and References

## Overview
This document catalogs the debugging aids provided for the project and explains how each one can be used to assist in development, testing, and troubleshooting. The aids focus on numerical input/output processing and visual debugging techniques.

## Aid Files

1. HW6aid1etc (1).pdf - Algorithmic Guide
   - Purpose: 
     - Provides textual explanations and algorithms for common challenges
     - Focuses on handling numerical input (hex/decimal)
     - Details formatting numerical output for terminal display
   
   - Key debugging features:
     - Hex conversion algorithm: ASCII to number (e.g., 'S$12AB' → $12AB)
     - Binary to decimal conversion via repeated division by 10
     - Binary to hexadecimal conversion via repeated division by 16
     - 'W' command data processing (hex $xx vs decimal xx)
   
   - How to use:
     1. Identify your specific problem area
     2. Locate corresponding Q&A section in PDF
     3. Implement described algorithm in assembly
     4. Test and verify results
   
   - Common issues it helps solve:
     - ASCII hex input ('$12AB') → 16-bit number conversion
     - Memory value → decimal display conversion
     - Memory value → hexadecimal display conversion
     - 'W' command data handling (hex/decimal formats)

2. HW6aid2etc (1).pdf - Visual Debugging Guide
   - Purpose:
     - Visual, step-by-step guide for numerical I/O processing
     - Memory and register state diagrams
     - Input/output buffer visualization
   
   - Key debugging features:
     - Keyboard input processing visualization
       * ASCII → buffer flow
       * Conversion process diagrams
       * Complete address/number formation
     - Data retrieval/printing visualization
       * Memory access diagrams
       * ASCII output buffer preparation
     - Comprehensive ASCII reference table
   
   - How to use:
     1. Run program in simulator
     2. Compare register/memory contents with diagrams
     3. Track discrepancies between actual vs expected
     4. Use ASCII table for character code verification
   
   - Common issues it helps solve:
     - ASCII → numerical conversion errors
     - Multi-byte address/data combination issues
     - Memory address loading problems
     - ASCII output generation errors
     - Special character handling (e.g., Enter key $0D)

## Debugging Strategies

1. Using the Aids:
   - Use HW6aid1etc for algorithm implementation
   - Use HW6aid2etc for visual state verification
   - Combine both for comprehensive debugging
   - Reference ASCII table for character issues

2. Debugging Process:
   - Input Processing:
     1. Verify ASCII input capture
     2. Check conversion algorithms
     3. Validate final number formation
   
   - Memory Operations:
     1. Verify address calculations
     2. Check memory access
     3. Validate data handling
   
   - Output Processing:
     1. Verify number conversion
     2. Check ASCII generation
     3. Validate terminal output

3. Common Issues:
   - Input Problems:
     * Use HW6aid2etc diagrams for buffer checking
     * Apply HW6aid1etc algorithms for conversion
   
   - Processing Issues:
     * Compare register states with diagrams
     * Verify algorithm implementation
   
   - Output Problems:
     * Check conversion process
     * Verify ASCII generation

## Integration with Development

1. Development Phase:
   - Reference algorithms during implementation
   - Use diagrams for state planning
   - Implement verification points
   - Plan for error handling

2. Testing Phase:
   - Compare states with diagrams
   - Verify algorithm outputs
   - Test boundary conditions
   - Validate error handling

3. Troubleshooting Phase:
   - Use visual guides to locate issues
   - Apply algorithmic solutions
   - Verify character handling
   - Check state transitions

## Best Practices

1. Documentation:
   - Note algorithm implementation details
   - Document state comparisons
   - Record error patterns
   - Track resolution steps

2. Efficiency:
   - Keep ASCII table handy
   - Mark key diagram pages
   - Document common solutions
   - Create debug checkpoints

*Note: These aids are complementary - use HW6aid1etc for algorithmic guidance and HW6aid2etc for visual state verification.* 