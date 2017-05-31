**************************************************
* Fixed-Point Math Routines                      *
* A fixed-point variable consists of two parts.  *
*                                                *
* The high word is the binary INTEGER component. *
* The low word is the  binary FRACTION component.*
**************************************************
         REL

         LST   OFF
         DSK   FIXED.MATH.L

         USE   4/MACROS
         USE   4/UTIL.MACS

         USE   DP.TABLE

* Macros are defined in FIXED.MACROS

         M65816 1

         NOP
         NOP

**************************************************
* FX_INIT
* Initializes a fixed-point value to 0.
* Input: $3,S = ptr to the variable to initialize.

FX_INIT  ENT

         LDY   #0
         LDA   $3,S
         STA   fx_Scratch

         LDA   #0
         STA   (fx_Scratch),Y

         LDY   #2
         STA   (fx_Scratch),Y

         RTS

**************************************************
* FX_SET
* Sets a fixed point number.
* Input: $3,S = 16-bit binary integer
* ...... $5,S = 16-bit binary fraction
* ...... $7,S = pointer to destination

FX_SET   ENT
         LDY   #0

         LDA   $3,S
         STA   ($7,S),Y   ; copy the integer

         LDA   $7,S
         INC
         INC
         STA   $7,S

         LDA   $5,S
         STA   ($7,S),Y

         RTS

**************************************************
* FX_ADD
* Adds two fixed point operands together, storing the result elsewhere.
* Input: $B,S = LONG result space
* ...... $7,S = LONG operand 2
* ...... $3,S = LONG operand 1

FX_ADD   ENT

         LDA   $1,S
         STA   RETURN_ADDRESS

         LDA   #0
         STA   $B,S

* Add the fractional component: fx_Operand1 + fx_Operand2
         LDA   $3,S

         CLC
         ADC   $7,S

         STA   $B,S

* Is the Carry flag set?
         BCC   :addIntegers

* Yes, the result overflowed.
         LDA   #1
         STA   $D,S       ; C = 1

:addIntegers
         LDA   $5,S       ; R = A
         CLC
         ADC   $9,S       ; R = A+B
         CLC
         ADC   $D,S       ; R = A+B+C
         STA   $D,S       ; store R

         PLA
         PLA
         PLA
         PLA              ;discard two longs, leaving Result on the stack

         LDA   RETURN_ADDRESS
         STA   $1,S

         RTS

**************************************************
* FX_SUB
* Subtracts two fixed point operands, storing the result elsewhere.
* Input: $B,S = LONG result space
* ...... $7,S = LONG operand 2
* ...... $3,S = LONG operand 1

FX_SUB   ENT

         LDA   $1,S
         STA   RETURN_ADDRESS

         LDA   #0
         STA   $D,S

* Subtract the fractional component: fx_Operand1 - fx_Operand2
* If we overflow, subtract 1 from the integer result.
         LDA   $3,S

         SEC
         SBC   $7,S

         STA   $B,S

* Is the Negative flag set?
         BPL   :subIntegers

* Yes, the result is negative.
         LDA   #-1
         STA   $D,S       ; C = 1

:subIntegers
         LDA   $5,S       ; R = A
         SEC
         SBC   $9,S       ; R = A-B
         SEC
         SBC   $D,S       ; R = A-B-C
         STA   $D,S       ; store R

         PLA
         PLA
         PLA
         PLA              ;discard two longs, leaving Result on the stack

         LDA   RETURN_ADDRESS
         STA   $1,S

         RTS
