         EXT   FX_INIT
         EXT   FX_SET
         EXT   FX_ADD
         EXT   FX_SUB

**************************************************
* Required definitions
fixed_10000 adrl $27100000
**************************************************

M_FX_VERTEX MAC
         dw    $0000,]1,$0000,]2
         <<<

* Multiply a FIXED by 10000 to produce a FIXED with the fraction now
* in the decimal word.
M_FX_TO_DECIMAL MAC
         LDA   ]1
         STA   fx_Scratch
         LDA   #0
         STA   fx_Scratch+2
         ~FixMul fx_Scratch;fixed_10000
         PullLong ]2
         <<<

**************************************************
M_FX_INIT MAC
         LDA   ]1         ; param 1 is a WORD pointer
         PHA
         JSR   FX_INIT
         PLA
         <<<

M_FX_SET MAC
         LDA   ]1         ; destination
         PHA
         LDA   ]2         ; integer
         PHA
         LDA   ]3         ; decimal
         PHA
         JSR   FX_SET
         PLA
         PLA
         PLA
         <<<

M_FX_ADD MAC
         LDA   ]1         ; WORD ptr to operand 1
         PHA
         LDA   ]2         ; WORD ptr to operand 2
         PHA
         LDA   ]3         ; WORD ptr to result
         PHA
         JSR   FX_ADD
         PLA
         PLA
         PLA
         <<<

M_FX_SUB MAC
         LDA   ]1         ; WORD ptr to operand 1
         PHA
         LDA   ]2         ; WORD ptr to operand 2
         PHA
         LDA   ]3         ; WORD ptr to result
         PHA
         JSR   FX_SUB
         PLA
         PLA
         PLA
         <<<


M_FX_PULL_HEXSTR MAC
         PLA   ]1
         STA   ]1
         PLA   ]1+2
         STA   ]1+2
         <<<
