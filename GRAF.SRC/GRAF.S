         REL
         DSK   GRAF.L

         JMP   INIT

         LST   OFF
         USE   4/DOS.16.MACS
         USE   4/EVENT.MACS
         USE   4/INT.MACS
         USE   4/LOCATOR.MACS
         USE   4/MACROS
         USE   4/MEM.MACS
         USE   4/SANE.MACS
         USE   4/UTIL.MACS

         USE   GRAF.MACROS
         USE   FIXED.MACROS
         USE   DP.TABLE

         PUT   VIDEO.EQUATES

**************************************************
         EXT   DrawRectangle
         EXT   PaletteTable
         EXT   Bresenham
         EXT   DrawShape
         EXT   DrawShape2
         EXT   RotateVertex
         EXT   ClearScreen
**************************************************

* Data...
mmID     ds    2

old_DP   ds    2          ;store the DP so we can restore it on exit
old_SP   ds    2          ;store the SP so we can restore it on exit

DP_ptr   ds    2          ;pointer to direct-page bank
DP_hndl  ds    4

ScratchPtr ds  4          ;a scratch memory pointer

fixed_test_1 ds 4
fixed_test_2 ds 4
fixed_test_3 ds 4
fixed_HALF adrl $00008000 ; 0.5000

INT_scratch_1 ds 2
INT_scratch_2 ds 2
INT_scratch_3 ds 3

INT_65535 =    $FFFF

degrees_to_rotate ds 2

**************************************************
* Tool Startup structures
StartStopRef ds 4         ; reference to StartStopRec

StartStopRec
         dw    0          ; must be 0
         dw    $0         ; QD 320px
         ds    2          ; resFileID
         ds    4          ; dPageHandle
         dw    4          ; Number of tools to start

ToolsList
         dw    3,$0100    ; Misc Tools
         dw    6,$0100    ; Event Manager
         dw    10,$0100   ; SANE
         dw    11,$0100   ; Integer Math

evtMouseDown = 1
evtKeyDown =   3

**************************************************
* Event Manager record
EventRecord
evtWhat  ds    2
evtMsg   ds    4
evtWhen  ds    4
evtWhere ds    4
evtMods  ds    2          ; Modifiers

**************************************************
* Strings                                        *
str_Title ASC  "THE VALUE OF 100 * COS(45) IS: ",00
str_lol  ASC   "PLUS A BUNCH OF FRACTIONAL JUNK",00

                          ; Room for 16 characters
str_IntMath db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00

* Decimal and fractional strings for printing a FIXED value.
str_fx1  db    00,00,00,00,00,00,00,00,00
str_fx2  db    00,00,00,00,00,00,00,00,00
**************************************************
INIT     MX    %00        ;16-bit mode

         PHK
         PLB              ;data bank = program bank

         TDC
         STA   old_DP     ;store the DP as of the start of program
         TSC
         STA   old_SP     ;store the SP as of the start of program

TOOLS    _TLStartUp
         ~MMStartUp       ; Memory Manager
* _IMStartUp ; Integer Tools

         PLA
         STA   mmID       ;get our Memory Manager ID

* Start up the remaining tools.
         PushLong #0
         PushWord mmID
         PEA   #0
         PushLong #StartStopRec
         _StartupTools
         PullLong StartStopRef

* Allocate some direct page memory
         PushLong #0
         PushLong #$300   ;3 pages
         PushWord mmID
         PushWord #$C001  ;Locked, fixed, fixed bank
         PushLong #0
         _NewHandle

* Dereference the handle.
         PLX              ; X = low 16 bits of handle
         PLA              ; A = high 16 bits of handle
         PHD              ;save caller's direct page register
         PHA              ; push high word
         PHX              ;push low word
         TSC              ;get stack pointer in A
         TCD              ;and put it in D
         LDA   [1]        ;get low word of master pointer
         TAX              ;and put it in X
         LDY   #$0002     ;offset to high word of master pointer
         LDA   [1],Y      ;get high word
         PLY              ;remove low word of handle
         PLY              ;and high word
         PLD              ;restore caller's direct page register

* A,X is now nnHHMMLL. Since this is a direct page pointer,
* all we care about is MMLL.
         STX   DP_ptr
         TXA
         TCD              ;and now we have our own direct page

         CLC
         ADC   #$200
         PHA              ;push address of direct-page bank
         _SANEStartUp     ;start SANE

         LDA   #GS_PixelData
         STA   $00        ;$00 = ptr to current pixel

START    LDA   #0
         JSR   SetSCBs
         LDA   #0
         JSR   ClearToColor
         JSR   EnableSHR

         LDA   #$FFFF
         STA   penColor

         LDA   #0
         M_FX_INIT #fixed_test_1
         M_FX_INIT #fixed_test_2
         M_FX_INIT #fixed_test_3

         LDA   #45
         STA   degrees_to_rotate

**************************************************
EventLoop
* Let's play with the Integer tools!
         PushWord degrees_to_rotate
         PushLong #shape_Square
         JSR   RotateShape2
         PullLong
         PullWord         ;clean stack

         JSR   ClearScreen
         M_DrawShape2 #shape_Square;#100;#100

* Are there any events waiting for us?
         PushWord #0      ;result
         PushWord #$000A  ;event mask
         PushLong #EventRecord
         _EventAvail      ; nulls out EventRecord if there's no event

:eventAvailable
* Look for keydown and mouse button 0 down
         PushWord #0
         PushWord #$000A
         PushLong #EventRecord
         _GetNextEvent

:isThisOurEvent
         PLA              ; A = 0 if not our event
         CMP   #0
         BEQ   :done

:checkEventDetails
         LDA   evtWhat
         CMP   #evtMouseDown ; is this a mouse button 0 event?
         BEQ   EXIT

         CMP   #evtKeyDown ; is this a key event?
         BNE   :done

* This is a key event.
* TODO: uh, something

* Finally...
:done
         INC   degrees_to_rotate

* Uncomment this line to loop
         JMP   EventLoop

Waiting
         JSR   WaitKey
         JMP   EXIT

**************************************************
* Stuff to do when we exit.
EXIT
         PEA   #0
         PushLong #StartStopRef
         _ShutdownTools   ; orderly shutdown of our opened tools
         _DisposeAll      ; release all owned memory handles
         _MMShutDown
         _TLShutDown

         JSL   $E100A8    ; and exit the application
         DW    $2029
         ADRL  #QuitParms

QuitParms ADRL $00000000
         DW    $0000


**************************************************
CalculatePixelOffset
* Input coordinates in dp addrs dest_X and dest_Y
* Outputs to dest_Offset
         LDY   dest_Y
         LDA   dest_X
         LSR

:loop
         CPY   #0         ;each Y = 160 bytes added to A
         BEQ   :done
         CLC
         ADC   #BYTES_PER_LINE
         DEY
         BRA   :loop

:done
         STA   dest_Offset ;store the destination
         RTS

**************************************************
RotateShape2
* B,S = WORD number of degrees to rotate
* 7,S = LONG pointer to shape data structure
* 5,S = return address
* 3,S = WORD number of vertices in shape
* 1,S = vertex we're on

         LDA   #0
         PHA
         PHA

* How many vertices are there in this shape?
         LDA   #0
         LDY   #0
         SHORT
         LDA   ($7,S),Y
         LONG
         STA   $3,S

         LDA   $7,S
         STA   ptr_Long_Shape
         LDA   $9,S
         STA   ptr_Long_Shape+2

         INC   ptr_Long_Shape

* ptr_Long_Shape is the source.
* Calculate ptr_RotatedVertices with the following formula:
* ptr_RotatedVertices = ptr_Long_Shape + (8 * vertex_count)
         LDA   $3,S
         ASL
         ASL
         ASL              ; multiply vertex count by 8
         CLC
         ADC   ptr_Long_Shape
         STA   ptr_RotatedVertices ; and construct the pointer with it
         LDA   ptr_Long_Shape+2
         STA   ptr_RotatedVertices+2

:nextVertex
* Vertex 1
         PushWord $B,S
         PushLong ptr_Long_Shape
         JSR   RotateVertex

* Store the X vertex
         M_MoveLongToPtr fx_RotatedX;(ptr_RotatedVertices)

         LDA   ptr_Long_Shape
         CLC
         ADC   #4
         STA   ptr_Long_Shape

         LDA   ptr_RotatedVertices
         CLC
         ADC   #4
         STA   ptr_RotatedVertices

* And store the Y vertex
         M_MoveLongToPtr fx_RotatedY;(ptr_RotatedVertices)

         LDA   ptr_Long_Shape
         CLC
         ADC   #4
         STA   ptr_Long_Shape

         LDA   ptr_RotatedVertices
         CLC
         ADC   #4
         STA   ptr_RotatedVertices

         LDA   $1,S
         INC
         STA   $1,S

         CMP   $3,S
         BNE   :nextVertex
         BRA   :done

:done
         PLA
         PLA

         RTS

**************************************************
ResetIntMathString
         LDA   #0
         LDY   #15

:loop    STA   str_IntMath,Y
         CPY   #0
         BEQ   :done
         DEY
         BRA   :loop

:done
         RTS

**************************************************
DrawString                ;keep doing DrawGlyph until we hit a $00

         PHA              ;local variable
this_glyph =   $1,S       ;
ptr_String =   $5,S       ;input, the string pointer

:getNextCharLoop
         LDY   #0
         LDA   ($5,S),Y   ;grab the character we need

         AND   #$007F     ;strip the high bit
         CMP   #0         ;NUL?
         BEQ   :done

* Okay, now draw this character code.
         STA   this_glyph
         M_DrawGlyph this_glyph;dest_X;dest_Y

         LDA   $5,S
         INC
         STA   $5,S       ;next character

         LDA   dest_X
         CLC
         ADC   #8
         STA   dest_X     ;advance a character cell

         BRA   :getNextCharLoop

:done
         PLA              ;destroy local variable
         RTS

**************************************************
DrawGlyph                 ;Just draw the glyph_A for now
                          ;at (X,Y)
:init
         LDA   #0
         STA   glyph_sl_drawn

         JSR   CalculatePixelOffset ;stores this in dest_Offset
         JMP   :makePtr

:makePtr
         LDA   $3,S       ; Get the glyph from the stack
         SEC
         SBC   #$20       ; subtract $20 to get the offset into the table
         ASL              ; multiply the char by 2 to get the offset
         TAY

         LDA   ASCIIGlyphs,Y
         STA   ptr_Glyph
         SHORT
         PHB
         PLA
         LONG
         AND   #$00FF
         STA   ptr_Glyph+2 ;constructed a 24-bit pointer.
:draw
* A glyph is 8x6.
         PHB
         SetDBR #$E1

         LDY   #0
         LDX   dest_Offset

:drawScanline
         LDA   [ptr_Glyph],Y
         STA   $2000,X

         INX
         INX
         INY
         INY
         LDA   [ptr_Glyph],Y
         STA   $2000,X

         DEX              ;Back to byte 0
         DEX
         INY
         INY
* Next scanline.
         TXA
         CLC
         ADC   #BYTES_PER_LINE ;move to next scanline
         TAX

         INC   glyph_sl_drawn
         LDA   glyph_sl_drawn
         CMP   #6
         BEQ   :doneDrawing
         BRA   :drawScanline

:doneDrawing
         PLB
         RTS

**************************************************
* Load the palette
LoadPalette
         LDX   #0

:loop
         LDA   PaletteTable,X
         STAL  GS_Palettes,X ;set palette 0 color 0
         INX
         INX
         CMP   #32
         BNE   :loop

         RTS

* Enable Super Hi-Res graphics
EnableSHR
         SHORT
         LDAL  $00C029
         ORA   #$C0       ; Enable SHR and linear VRAM
         STAL  $00C029    ; New Video Register
         LONG
         RTS

* Clear screen to one solid color in A.
ClearToColor
         LDX   #$7D00     ; Pixel data is $E12000-$E19D00
:clearLoop
         DEX
         DEX
         STAL  $E12000,X  ; pixel location
         BNE   :clearLoop ; loop until X == 0
         RTS

* Sets all Scanline Control Bits to A.
SetSCBs
         LDX   #$0100
:scbLoop
         DEX
         DEX
         STAL  $E19D00,X
         BNE   :scbLoop
         RTS

* Wait for a keypress.
WaitKey
         SEP   #$30       ; 8-bit mode
:wait    LDAL  $00C000    ; Apple II keyboard register
         BPL   :wait
         STAL  $00C010
         REP   #$30       ; 16-bit mode
         RTS

**************************************************
shape_Square
         db    4          ; how many vertices in the shape?

* Each M_FX_VERTEX specifies one vertex.
shape_Square_vertices
         M_FX_VERTEX #-20;#-20
         M_FX_VERTEX #20;#-20
         M_FX_VERTEX #20;#20
         M_FX_VERTEX #-20;#20

* And then leave room at the end for the transformed vertices.
shape_Square_transformed
         ds    8
         ds    8
         ds    8
         ds    8

**************************************************
glyph_data                ; Marks the start of the glyphs.
         PUT   GLYPH
