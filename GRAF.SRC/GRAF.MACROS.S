**************************************************
* Macros for use with GRAF.                      *
**************************************************

**************************************************
* Externals                                      *
**************************************************

SetDBR   MAC
         SEP   #$30
         LDA   ]1
         PHA              ;data bank = $E1
         PLB
         REP   #$30
         <<<

M_ADD    MAC
         CLC
         ADC   ]1
         <<<

M_DrawRectangle MAC
         LDA   ]1
         STA   rX1
         LDA   ]2
         STA   rY1
         LDA   ]3
         STA   rX2
         LDA   ]4
         STA   rY2
         JSR   DrawRectangle
         <<<

M_DrawGlyph MAC
         LDA   ]1
         AND   #$00FF
         PHA
         LDA   ]2
         STA   dest_X
         LDA   ]3
         STA   dest_Y
         JSR   DrawGlyph
         PLA              ;pull our value off the stack
         <<<

M_DrawString MAC
         LDA   ]1
         PHA
         LDA   ]2
         STA   dest_X
         LDA   ]3
         STA   dest_Y
         JSR   DrawString
         PLA              ;pull our value off the stack
         <<<

M_Bresenham MAC
         LDA   ]1
         STA   lnX1
         LDA   ]2
         STA   lnY1
         LDA   ]3
         STA   lnX2
         LDA   ]4
         STA   lnY2
         JSR   Bresenham
         <<<

M_DrawShape MAC
         LDA   ]1         ; pointer to shape
         PHA
         LDA   ]2         ; origin X
         PHA
         LDA   ]3         ; origin Y
         PHA
         JSR   DrawShape
         <<<

M_DrawShape2 MAC
         LDA   ]1         ; pointer to shape
         PHA
         LDA   ]2         ; origin X
         PHA
         LDA   ]3         ; origin Y
         PHA
         JSR   DrawShape2
         <<<

M_RotateShape MAC
         LDA   ]1         ; pointer to shape
         PHA
         LDA   ]2         ; pointer to fixed radians
         PHA
         JSR   RotateShape
         PLA
         PLA
         RTS
         <<<

M_MoveLongFromPtr MAC
         LDY   #0
         LDA   ]1,Y
         STA   ]2
         LDY   #2
         LDA   ]1,Y
         STA   ]2+2
         <<<

M_MoveLongToPtr MAC
         LDY   #0
         LDA   ]1
         STA   ]2,Y
         LDY   #2
         LDA   ]1+2
         STA   ]2,Y
         <<<
