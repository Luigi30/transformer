         REL
         LST   OFF
         DSK   LINES.L

         USE   4/DOS.16.MACS ;merlin16 macros
         USE   4/INT.MACS
         USE   4/LOCATOR.MACS
         USE   4/MACROS
         USE   4/MEM.MACS
         USE   4/UTIL.MACS

         USE   GRAF.MACROS ; My macros
         USE   FIXED.MACROS
         USE   DP.TABLE    ; Direct Page variables

         PUT   VIDEO.EQUATES
         M65816 1

M_PlotPixel MAC
         LDA   ]1
         STA   plotX
         LDA   ]2
         STA   plotY
         JSR   PlotPixel
         <<<

**************************************************
* Data...
mmID     ds    2

old_DP   ds    2          ;store the DP so we can restore it on exit
old_SP   ds    2          ;store the SP so we can restore it on exit

DP_ptr   ds    2          ;pointer to direct-page bank
DP_hndl  ds    4
ScratchPtr ds  4          ;a scratch memory pointer

*************************************************
DrawRectangle ENT
* Draw from (X1,Y1) to (X2,Y1)
         LDA   rX1
         STA   lnX1
         LDA   rX2
         STA   lnX2
         LDA   rY1
         STA   lnY1
         JSR   DrawHorizontalLine

* Draw from (X1,Y2) to (X2,Y2)
         LDA   rY2
         STA   lnY1
         JSR   DrawHorizontalLine

* Draw from (X1,Y1) to (X1,Y2)
         LDA   rX1
         STA   lnX1
         LDA   rX2
         STA   lnX2
         LDA   rY1
         STA   lnY1
         LDA   rY2
         STA   lnY2
         JSR   DrawVerticalLine

* Draw from (X2,Y1) to (X2,Y2)
         LDA   rX2
         STA   lnX1
         LDA   rX2
         STA   lnX2
         LDA   rY1
         STA   lnY1
         LDA   rY2
         STA   lnY2
         JSR   DrawVerticalLine

         RTS

**************************************************
BresenhamNegSlope ENT

Bresenham ENT             ;Bresenham's line thingy.
* Only works for positive slopes...

b_dX     =     $1,S
b_dY     =     $3,S
b_D      =     $5,S

b_x      =     $7,S
b_y      =     $9,S

b_yIncrement = $B,S

         PHA
         PHA
         PHA
         PHA
         PHA              ;5 16-bit variables
         PHA

* Swap the points if X2 is bigger than X1.
         LDA   lnX2
         CMP   lnX1
         BGE   :getSlopeSign

:swap
         LDA   lnX1
         LDX   lnX2
         STA   lnX2
         STX   lnX1

         LDA   lnY1
         LDX   lnY2
         STA   lnY2
         STX   lnY1

:getSlopeSign
         LDA   #1
         STA   $B,S       ;b_yIncrement

         LDA   lnY2
         CMP   lnY1
         BGE   :plotEndpoints ;slope is positive

* Slope is negative.
         LDA   #-1
         STA   $B,S       ;b_yIncrement

:plotEndpoints
         M_PlotPixel lnX1;lnY1
         M_PlotPixel lnX2;lnY2

* dX = abs(x1-x0)
         LDA   lnX2
         SEC
         SBC   lnX1

         BIT   #$8000     ; is the result negative?
         BEQ   :posDX
:negDX
         EOR   #$FFFF     ; flip sign
         CLC
         ADC   #1
:posDX
         STA   $1,S       ;b_dX

* dY = abs(y1-y0)
         LDA   lnY2
         SEC
         SBC   lnY1

         BIT   #$8000     ; is the result negative?
         BEQ   :posDY
:negDY
         EOR   #$FFFF     ; flip sign
         CLC
         ADC   #1
:posDY
         STA   $3,S       ;b_dY

* if(dx > dy)
         LDA   $1,S       ;b_dX
         CMP   $3,S       ;b_dY
         BLT   BresStepY

:bresStepX
* D = 2*dY - dX
         LDA   $3,S       ;b_dY
         ASL              ;multiply by 2
         SEC
         SBC   $1,S       ;b_dX
         STA   $5,S       ;b_D

* y = y0
         LDA   lnY1
         STA   $9,S       ;b_y

* for x from x0 to x1
         LDA   lnX1
         STA   $7,S       ;b_x
:xLoop
         LDA   $7,S       ;b_x
         CMP   lnX2
         BEQ   :done

* plot(x,y)
         M_PlotPixel $7,S;$9,S ;b_x;b_y
* if D > 0
         LDA   $5,S       ;b_D
         BIT   #$8000     ; check sign bit
         BNE   :endIf

* y = y + y_increment
         LDA   $9,S       ;b_y
         CLC
         ADC   $B,S       ;b_yIncrement
         STA   $9,S       ;b_y

* D = D - 2*dx
         LDA   $5,S       ;b_D
         SEC
         SBC   $1,S       ;b_dX
         SEC
         SBC   $1,S       ;b_dX
         STA   $5,S       ;b_D

:endIf
         LDA   $3,S       ;b_dY
         ASL              ;multiply by 2
         CLC
         ADC   $5,S       ;b_D
         STA   $5,S       ;b_D

:xLoopNext
         LDA   $7,S
         INC
         STA   $7,S       ;b_x
         BRA   :xLoop

:done
         PLA
         PLA
         PLA
         PLA
         PLA
         PLA
         RTS

**************************************************
BresStepY
* Bresenham where we step using Y instead of X.
* Swap the points if Y2 is bigger than Y1.
         LDA   lnY2
         CMP   lnY1
         BGE   :go

:swap
         LDA   lnX1
         LDX   lnX2
         STA   lnX2
         STX   lnX1

         LDA   lnY1
         LDX   lnY2
         STA   lnY2
         STX   lnY1

:go
* D = 2*dX - dY
         LDA   $1,S       ;b_dX
         ASL              ;multiply by 2
         SEC
         SBC   $3,S       ;b_dY
         STA   $5,S       ;b_D

* x = x0
         LDA   lnX1
         STA   $7,S       ;b_x

* for y from y0 to y1
         LDA   lnY1
         STA   $9,S       ;b_y
:yLoop
         LDA   $9,S       ;b_y
         CMP   lnY2
         BEQ   :done

* plot(x,y)
         M_PlotPixel $7,S;$9,S ;b_x;b_y

* if D > 0
         LDA   $5,S       ;b_D
         BIT   #$8000     ; check sign bit
         BNE   :endIf

* x = x + x_increment
         LDA   $7,S       ;b_x
         CLC
         ADC   $B,S       ;b_xIncrement
         STA   $7,S       ;b_x

* D = D - 2*dy
         LDA   $5,S       ;b_D
         SEC
         SBC   $3,S       ;b_dy
         SEC
         SBC   $3,S       ;b_dy
         STA   $5,S       ;b_D

:endIf
         LDA   $1,S       ;b_dx
         ASL              ;multiply by 2
         CLC
         ADC   $5,S       ;b_D
         STA   $5,S       ;b_D

:yLoopNext
         LDA   $9,S
         INC
         STA   $9,S       ;b_y
         BRA   :yLoop

:done
         PLA
         PLA
         PLA
         PLA
         PLA
         PLA
         RTS

**************************************************
PlotPixel
* Clip to the 320x200 screen.
         LDA   plotX
         CMP   #320
         BGE   :abort

         LDA   plotY
         CMP   #200
         BGE   :abort

         BRA   :doPlot

:abort
         RTS

:doPlot
         LDA   plotY
         ASL              ;multiply by 2
         TAY

         LDA   plotX
         LSR              ; divide by 2 to get pixel address

         CLC
         ADC   VRAMRows,Y ; now find the right row
         TAY

         PHB              ; we need to preserve all 16 bits of Y
         PHY

:plot                     ; and plot the pixel
         SetDBR #$E1      ; clobbers high byte of Y

         PLY              ; and retrieves Y

         LDA   plotX
         AND   #$1
         BEQ   :plotOdd
         BRA   :plotEven

:plotOdd
         LDA   penColor
         AND   #$00FF
         ORA   $0000,Y
         STA   $0000,Y

         PLB              ;restore the old DBR
         RTS

:plotEven
         LDA   penColor
         AND   #$FF00
         ORA   $0000,Y
         STA   $0000,Y

         PLB              ;restore the old DBR
         RTS

**************************************************
DrawHorizontalLine
* Draw a horizontal line from (lnX1,lnY1) to (lnX2,lnY1)
         PHB
         SetDBR #$E1

         SUB   lnX2;lnX1;lnXSize ;calculate line length

* LDA lnX2 ;A = x2
* ADC lnX1 ;A = x1+x2
* LSR  ;A = (x1+x2)/2

         LDA   #0
         ADC   lnX2
         LSR              ;A = x2 / 2 since we draw right to left

* Now calculate pixel offset using y1. 160 per y1
         LDY   lnY1
:yCalcLoop
         CPY   #0
         BEQ   :prepDrawing
         CLC
         ADC   #160       ;each #160 added moves down one scanline
         DEY
         BRA   :yCalcLoop

:prepDrawing
         TAY              ;Y = pixel offset

         LDA   lnXSize
         LSR
         TAX              ;X = pixels to draw

         LDA   penColor

:drawLoop                 ;draw rXSize pixels.
         CPX   #0
         BEQ   :horizontalDone
         DEX
         DEY
         STA   $2000,Y
         BRA   :drawLoop

:horizontalDone
         PLB              ;restore the old DBR
         RTS

**************************************************
DrawVerticalLine
* Draw a vertical line from (lnX1,lnY1) to (lnX1,lnY2)
         PHB
         SetDBR #$E1

         SUB   lnY2;lnY1;lnYSize ;calculate line length

:calcStartY
         LDA   #0         ;A = 0
         ADC   lnX1       ;A = x1
         LSR              ;A = x1/2

         LDX   lnY1
:calcLoop
         CPX   #0
         BEQ   :prepDrawing
         CLC
         ADC   #160       ;Add 160 per scanline we start on
         DEX
         BRA   :calcLoop

:prepDrawing
         LDX   lnYSize    ;X = pixels to draw
         TAY              ;Y = pixel address offset
         LDA   penColor   ;A = pen color
* TODO: Check if we draw $00FF or $FF00 (even or odd pixel)
         BIT   #$01       ;Is this an odd pixel?
         BEQ   :drawOdd
         BNE   :drawEven

:drawEven
         AND   #$00FF
         BRA   :drawLoop

:drawOdd
         AND   #$FF00
         BRA   :drawLoop

:drawLoop
         CPX   #0
         BEQ   :verticalDone
         PHA
         ORA   $2000,Y
         STA   $2000,Y
         PLA
         DEX              ;subtract one pixel

         PHA
         TYA
         CLC
         ADC   #160       ;go to next scanline
         TAY
         PLA

         BRA   :drawLoop

:verticalDone
         PLB
         RTS

**************************************************
RoundFixedVertex MAC
         PHY              ; preserve Y
         PHA              ; make room for the result
         INY
         INY
         LDA   (ptr_Shape),Y
         PHA              ; push the low word of the FIXED
         DEY
         DEY
         LDA   (ptr_Shape),Y
         PHA              ; and the high word
         _FixRound        ; round it
         PLA              ; and pull the result
         PLY              ; and grab Y
         <<<

**************************************************
DrawShape2 ENT            ; draw a shape. pointer is at $FC
         PHA              ; $1,S = current vertex
         PHA              ; $3,S = number of vertices
                          ; $5,S = return address
                          ; $7,S = origin X
                          ; $9,S = origin Y
                          ; $B,S = pointer to shape data

         LDA   $B,S
         STA   ptr_Shape  ; save pointer to $FC

         LDA   #0
         STA   $1,S       ; initialize current vertex to 0

         SHORT
         LDA   (ptr_Shape) ; A = vertex count in shape
         LONG

         DEC
         STA   $3,S       ; set shape vertex count

         INC   ptr_Shape  ; ptr_Shape now points to the start of the
                          ; vertex data

         LDA   $3,S       ; but we need to advance it to the transformed
         INC              ; vertices
         ASL
         ASL
         ASL              ; so multiply vertex count by sizeof(vertex)
         CLC
         ADC   ptr_Shape  ; add it to the pointer address
         STA   ptr_Shape  ; magic.

:getNextVertex
* Grab the first two vertices and load them into lnX1 and lnY1

         LDA   $1,S       ; get current vertex
         ASL
         ASL              ; multiply by 8 to get offset
         ASL
         TAY              ; and now the offset is in Y

* X coordinate
         RoundFixedVertex  ; round off the X value
         CLC
         ADC   $7,S       ; add the origin
         STA   lnX1       ; grab and store vertex 0 X coord

* Y coordinate
         INY
         INY              ; advance offset to v0 Y coord
         INY
         INY

         RoundFixedVertex  ; round off the Y value
         CLC
         ADC   $7,S       ; add the origin
         STA   lnY1       ; grab and store vertex 0 X coord

* Next vertex
         LDA   $1,S
         INC
         STA   $1,S       ; currentVertex += 1

* Grab the next two vertices - this produces one line.
         INY
         INY              ; advance offset to v1 X coord
         INY
         INY

         RoundFixedVertex
         ADC   $7,S
         STA   lnX2       ; save it

         INY
         INY              ; advance offset to v1 Y coord
         INY
         INY

         RoundFixedVertex
         CLC
         ADC   $9,S
         STA   lnY2       ; save it

         JSR   Bresenham  ; draw our line now

* Is this the last vertex?
         LDA   $1,S
         CMP   $3,S
         BEQ   :isLastVertex
         BRL   :getNextVertex

:isLastVertex
* The last vertex, so draw it and wrap back to v0.

         LDA   $1,S       ; get current vertex
         ASL
         ASL
         ASL              ; multiply by 8 to get offset
         TAY              ; and now the offset is in Y

         RoundFixedVertex
         CLC
         ADC   $7,S
         STA   lnX1       ; grab and store vertex 0 X coord

         INY
         INY              ; advance offset to v0 Y coord
         INY
         INY

         RoundFixedVertex
         CLC
         ADC   $9,S
         STA   lnY1       ; store v0 Y coord

         LDA   $1,S
         INC
         STA   $1,S       ; currentVertex += 1

* Go back to vertex 0 to finish the shape.
         LDA   #0
         TAY

         RoundFixedVertex
         CLC
         ADC   $7,S
         STA   lnX2       ; save it

         INY
         INY              ; advance offset to v1 Y coord
         INY
         INY

         RoundFixedVertex
         CLC
         ADC   $9,S
         STA   lnY2       ; save it

         JSR   Bresenham  ; draw our line now

:done
         PLA
         PLA
         RTS


**************************************************
DrawShape ENT             ; draw a shape. pointer is at $FC
         PHA              ; $1,S = current vertex
         PHA              ; $3,S = number of vertices
                          ; $5,S = return address
                          ; $7,S = origin X
                          ; $9,S = origin Y
                          ; $B,S = pointer to shape data

         LDA   $B,S
         STA   ptr_Shape  ; save pointer to $FC

         LDA   #0
         STA   $1,S       ; initialize current vertex to 0

         SHORT
         LDA   (ptr_Shape) ; A = vertex count in shape
         LONG

         DEC
         STA   $3,S       ; set shape vertex count

         INC   ptr_Shape  ; ptr_Shape now points to the start of the
                          ; vertex data

         LDA   $3,S       ; but we need to advance it to the transformed
         INC              ; vertices
         ASL
         ASL
         ASL              ; so multiply vertex count by sizeof(vertex)
         CLC
         ADC   ptr_Shape  ; add it to the pointer address
         INC              ; add 2 bytes
         INC              ; and now it points to the high word of vertices
         STA   ptr_Shape  ; magic.

:getNextVertex
* Grab the first two vertices and load them into lnX1 and lnY1

         LDA   $1,S       ; get current vertex
         ASL
         ASL              ; multiply by 8 to get offset
         ASL
         TAY              ; and now the offset is in Y

         LDA   (ptr_Shape),Y
         CLC
         ADC   $7,S       ; add the origin
         STA   lnX1       ; grab and store vertex 0 X coord

         INY
         INY              ; advance offset to v0 Y coord
         INY
         INY

         LDA   (ptr_Shape),Y
         CLC
         ADC   $7,S       ; add the origin
         STA   lnY1       ; grab and store vertex 0 X coord

         LDA   $1,S
         INC
         STA   $1,S       ; currentVertex += 1

* Grab the next two vertices - this produces one line.
         INY
         INY              ; advance offset to v1 X coord
         INY
         INY

         LDA   (ptr_Shape),Y
         CLC
         ADC   $7,S
         STA   lnX2       ; save it

         INY
         INY              ; advance offset to v1 Y coord
         INY
         INY

         LDA   (ptr_Shape),Y
         CLC
         ADC   $9,S
         STA   lnY2       ; save it

         JSR   Bresenham  ; draw our line now

* Is this the last vertex?
         LDA   $1,S
         CMP   $3,S
         BEQ   :isLastVertex
         BRL   :getNextVertex

:isLastVertex
* The last vertex, so draw it and wrap back to v0.

         LDA   $1,S       ; get current vertex
         ASL
         ASL
         ASL              ; multiply by 8 to get offset
         TAY              ; and now the offset is in Y

         LDA   (ptr_Shape),Y
         CLC
         ADC   $7,S
         STA   lnX1       ; grab and store vertex 0 X coord

         INY
         INY              ; advance offset to v0 Y coord
         INY
         INY

         LDA   (ptr_Shape),Y
         CLC
         ADC   $9,S
         STA   lnY1       ; store v0 Y coord

         LDA   $1,S
         INC
         STA   $1,S       ; currentVertex += 1

* Go back to vertex 0 to finish the shape.
         LDA   #0
         TAY

         LDA   (ptr_Shape),Y
         CLC
         ADC   $7,S
         STA   lnX2       ; save it

         INY
         INY              ; advance offset to v1 Y coord
         INY
         INY

         LDA   (ptr_Shape),Y
         CLC
         ADC   $9,S
         STA   lnY2       ; save it

         JSR   Bresenham  ; draw our line now

:done
         PLA
         PLA
         RTS

**************************************************
RotateVertex ENT
* Rotate a FIXED vertex around (0,0) by theta degrees.
*
* 7,S = WORD number of degrees to rotate
* 3,S = LONG pointer to vertex

* Retrieve FIXED radians from the table.
         LDA   7,S
         ASL
         ASL              ;multiply by 4 to get table offset
         TAY
         LDA   DegreesToRadians,Y
         STA   Radians    ; get low word
         INY
         INY
         LDA   DegreesToRadians,Y
         STA   Radians+2  ; get high word

* Calculate rotation of X component.
         LDA   3,S
         STA   ptr_Shape

         M_MoveLongFromPtr (ptr_Shape);fx_Operand2

         ~FracCos Radians
         PullLong fx_Operand1 ; contains FRAC value cos(45)
         ~Frac2Fix fx_Operand1
         PullLong fx_Operand1 ; contains FIXED value cos(45)

         ~FixMul fx_Operand1;fx_Operand2 ; v.X * cos(45)
         PullLong fx_Result              ; fx_Result = v.X * cos(45)

         LDA   ptr_Shape
         CLC
         ADC   #4         ; advance to Y component of vertex
         STA   ptr_Shape
         M_MoveLongFromPtr (ptr_Shape);fx_Operand2

         ~FracSin Radians
         PullLong fx_Operand1
         ~Frac2Fix fx_Operand1
         PullLong fx_Operand1            ; fx_Operand1 = FIXED sin(45deg)

         ~FixMul fx_Operand1;fx_Operand2 ; SP = fx_Operand1*fx_Operand2
         PullLong fx_Operand2

         MoveLong fx_Result;fx_Operand1
* fx_Operand1 = v.X * cos(45deg) | fx_Operand2 = v.Y * cos(45deg)

* Subtract fx_Operand1 and fx_Operand2
         PushLong #0
         PushLong fx_Operand2
         PushLong fx_Operand1
         JSR   FX_SUB

         PullLong fx_RotatedX

* Calculate rotation of Y component.

* ptr_Shape is still pointing to Y
         M_MoveLongFromPtr (ptr_Shape);fx_Operand2

         ~FracCos Radians
         PullLong fx_Operand1 ; contains FRAC value cos(45)
         ~Frac2Fix fx_Operand1
         PullLong fx_Operand1 ; contains FIXED value cos(45)

         ~FixMul fx_Operand1;fx_Operand2 ; v.Y * cos(45)
         PullLong fx_Result              ; fx_Result = v.Y * cos(45)

         LDA   ptr_Shape
         SEC
         SBC   #4         ; return to X component of vertex
         STA   ptr_Shape
         M_MoveLongFromPtr (ptr_Shape);fx_Operand2

         ~FracSin Radians
         PullLong fx_Operand1
         ~Frac2Fix fx_Operand1
         PullLong fx_Operand1

         ~FixMul fx_Operand1;fx_Operand2
         PullLong fx_Operand2

         MoveLong fx_Result;fx_Operand1

* Add fx_Operand1 and fx_Operand2
         PushLong #0
         PushLong fx_Operand2
         PushLong fx_Operand1
         JSR   FX_ADD

         PullLong fx_RotatedY

* Clean up the stack before we return.
         LDA   $1,S
         STA   $7,S
         PullLong
         PullWord

         RTS

**************************************************
ClearScreen ENT
         LDA   #0
         LDX   #$7D00
:clearLoop
         DEX
         DEX
         STAL  $E12000,X
         BNE   :clearLoop
         RTS

**************************************************
PaletteTable   ENT
pltBlack dw    $0000      ;Black
pltDGray dw    $0777      ;Dark Gray
pltBrown dw    $0841      ;Brown
pltPurple dw   $072C      ;Purple
pltBlue  dw    $000F      ;Blue
pltDGreen dw   $0080      ;Dark Green
pltOrange dw   $0F70      ;Orange
pltRed   dw    $0D00      ;Red
pltBeige dw    $0FA9      ;Beige
pltYellow dw   $0FF0      ;Yellow
pltGreen dw    $00E0      ;Green
pltLBlue dw    $04DF      ;Light Blue
pltLilac dw    $0DAF      ;Lilac
pltPeri  dw    $078F      ;Periwinkle
pltLGray dw    $0CCC      ;Light Gray
pltWhite dw    $0FFF      ;White
EndPaletteTable

DegreesToRadians
* Each entry is a 4-byte FIXED value.
         PUT   DEG2RAD.TABLE

**************************************************
VRAMRows
         dw    $A0*0+$2000
         dw    $A0*1+$2000
         dw    $A0*2+$2000
         dw    $A0*3+$2000
         dw    $A0*4+$2000
         dw    $A0*5+$2000
         dw    $A0*6+$2000
         dw    $A0*7+$2000
         dw    $A0*8+$2000
         dw    $A0*9+$2000
         dw    $A0*10+$2000
         dw    $A0*11+$2000
         dw    $A0*12+$2000
         dw    $A0*13+$2000
         dw    $A0*14+$2000
         dw    $A0*15+$2000
         dw    $A0*16+$2000
         dw    $A0*17+$2000
         dw    $A0*18+$2000
         dw    $A0*19+$2000
         dw    $A0*20+$2000
         dw    $A0*21+$2000
         dw    $A0*22+$2000
         dw    $A0*23+$2000
         dw    $A0*24+$2000
         dw    $A0*25+$2000
         dw    $A0*26+$2000
         dw    $A0*27+$2000
         dw    $A0*28+$2000
         dw    $A0*29+$2000
         dw    $A0*30+$2000
         dw    $A0*31+$2000
         dw    $A0*32+$2000
         dw    $A0*33+$2000
         dw    $A0*34+$2000
         dw    $A0*35+$2000
         dw    $A0*36+$2000
         dw    $A0*37+$2000
         dw    $A0*38+$2000
         dw    $A0*39+$2000
         dw    $A0*40+$2000
         dw    $A0*41+$2000
         dw    $A0*42+$2000
         dw    $A0*43+$2000
         dw    $A0*44+$2000
         dw    $A0*45+$2000
         dw    $A0*46+$2000
         dw    $A0*47+$2000
         dw    $A0*48+$2000
         dw    $A0*49+$2000
         dw    $A0*50+$2000
         dw    $A0*51+$2000
         dw    $A0*52+$2000
         dw    $A0*53+$2000
         dw    $A0*54+$2000
         dw    $A0*55+$2000
         dw    $A0*56+$2000
         dw    $A0*57+$2000
         dw    $A0*58+$2000
         dw    $A0*59+$2000
         dw    $A0*60+$2000
         dw    $A0*61+$2000
         dw    $A0*62+$2000
         dw    $A0*63+$2000
         dw    $A0*64+$2000
         dw    $A0*65+$2000
         dw    $A0*66+$2000
         dw    $A0*67+$2000
         dw    $A0*68+$2000
         dw    $A0*69+$2000
         dw    $A0*70+$2000
         dw    $A0*71+$2000
         dw    $A0*72+$2000
         dw    $A0*73+$2000
         dw    $A0*74+$2000
         dw    $A0*75+$2000
         dw    $A0*76+$2000
         dw    $A0*77+$2000
         dw    $A0*78+$2000
         dw    $A0*79+$2000
         dw    $A0*80+$2000
         dw    $A0*81+$2000
         dw    $A0*82+$2000
         dw    $A0*83+$2000
         dw    $A0*84+$2000
         dw    $A0*85+$2000
         dw    $A0*86+$2000
         dw    $A0*87+$2000
         dw    $A0*88+$2000
         dw    $A0*89+$2000
         dw    $A0*90+$2000
         dw    $A0*91+$2000
         dw    $A0*92+$2000
         dw    $A0*93+$2000
         dw    $A0*94+$2000
         dw    $A0*95+$2000
         dw    $A0*96+$2000
         dw    $A0*97+$2000
         dw    $A0*98+$2000
         dw    $A0*99+$2000
         dw    $A0*100+$2000
         dw    $A0*101+$2000
         dw    $A0*102+$2000
         dw    $A0*103+$2000
         dw    $A0*104+$2000
         dw    $A0*105+$2000
         dw    $A0*106+$2000
         dw    $A0*107+$2000
         dw    $A0*108+$2000
         dw    $A0*109+$2000
         dw    $A0*110+$2000
         dw    $A0*111+$2000
         dw    $A0*112+$2000
         dw    $A0*113+$2000
         dw    $A0*114+$2000
         dw    $A0*115+$2000
         dw    $A0*116+$2000
         dw    $A0*117+$2000
         dw    $A0*118+$2000
         dw    $A0*119+$2000
         dw    $A0*120+$2000
         dw    $A0*121+$2000
         dw    $A0*122+$2000
         dw    $A0*123+$2000
         dw    $A0*124+$2000
         dw    $A0*125+$2000
         dw    $A0*126+$2000
         dw    $A0*127+$2000
         dw    $A0*128+$2000
         dw    $A0*129+$2000
         dw    $A0*130+$2000
         dw    $A0*131+$2000
         dw    $A0*132+$2000
         dw    $A0*133+$2000
         dw    $A0*134+$2000
         dw    $A0*135+$2000
         dw    $A0*136+$2000
         dw    $A0*137+$2000
         dw    $A0*138+$2000
         dw    $A0*139+$2000
         dw    $A0*140+$2000
         dw    $A0*141+$2000
         dw    $A0*142+$2000
         dw    $A0*143+$2000
         dw    $A0*144+$2000
         dw    $A0*145+$2000
         dw    $A0*146+$2000
         dw    $A0*147+$2000
         dw    $A0*148+$2000
         dw    $A0*149+$2000
         dw    $A0*150+$2000
         dw    $A0*151+$2000
         dw    $A0*152+$2000
         dw    $A0*153+$2000
         dw    $A0*154+$2000
         dw    $A0*155+$2000
         dw    $A0*156+$2000
         dw    $A0*157+$2000
         dw    $A0*158+$2000
         dw    $A0*159+$2000
         dw    $A0*160+$2000
         dw    $A0*161+$2000
         dw    $A0*162+$2000
         dw    $A0*163+$2000
         dw    $A0*164+$2000
         dw    $A0*165+$2000
         dw    $A0*166+$2000
         dw    $A0*167+$2000
         dw    $A0*168+$2000
         dw    $A0*169+$2000
         dw    $A0*170+$2000
         dw    $A0*171+$2000
         dw    $A0*172+$2000
         dw    $A0*173+$2000
         dw    $A0*174+$2000
         dw    $A0*175+$2000
         dw    $A0*176+$2000
         dw    $A0*177+$2000
         dw    $A0*178+$2000
         dw    $A0*179+$2000
         dw    $A0*180+$2000
         dw    $A0*181+$2000
         dw    $A0*182+$2000
         dw    $A0*183+$2000
         dw    $A0*184+$2000
         dw    $A0*185+$2000
         dw    $A0*186+$2000
         dw    $A0*187+$2000
         dw    $A0*188+$2000
         dw    $A0*189+$2000
         dw    $A0*190+$2000
         dw    $A0*191+$2000
         dw    $A0*192+$2000
         dw    $A0*193+$2000
         dw    $A0*194+$2000
         dw    $A0*195+$2000
         dw    $A0*196+$2000
         dw    $A0*197+$2000
         dw    $A0*198+$2000
         dw    $A0*199+$2000
