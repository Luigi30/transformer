**************************************************
* GRAF LINKER SCRIPT                             *
**************************************************

         ASM   GRAF.S     ;Assemble if needed
         ASM   LINES.S    ;Assemble if needed
         ASM   FIXED.MATH.S ;Assemble if needed

         LNK   GRAF.L
         LNK   LINES.L
         LNK   FIXED.MATH.L

         TYP   S16
         SAV   GRAF
