* Direct Page addresses.
PixelPtr = $00

rectData ; A rectangle data structure.
rX1 = $04 ;DP
rX2 = $06 ;DP
rY1 = $08 ;DP
rY2 = $0A ;DP

* Private data for graphics routines
rXSize = $0C
rYSize = $0E

penColor = $10 ; Color we're using to draw.

* General line drawing from (x1,y1) to (x2,y2)
lnX1 = $12
lnY1 = $14

lnX2 = $16
lnY2 = $18

lnXSize = $1A ;for horizontal drawing
lnYSize = $1C ;for vertical drawing

* Glyph drawing
ptr_Glyph = $30 ;Pointer to current glyph.
glyph_sl_drawn = $34 ;How many drawn scanlines of the current glyph?

dest_X = $36 ;Destination of drawing
dest_Y = $38
dest_Offset = $3A
glyph_ASCII = $3C ;ASCII code of next glyph to draw.

* Pixel plotting
p_PixelLocation = $40 ;2 bytes: $E1BBAA

plotX = $80
plotY = $82

* Fixed-Point Math
fx_Scratch = $90 ; 4 bytes - scratch area
fx_Operand1 = $94 ; 4 bytes - Operand 1
fx_Operand2 = $98 ; 4 bytes - Operand 2
fx_Result = $9C ; 4 bytes - Result
fx_RotatedX = $A0
fx_RotatedY = $A4

Radians = $B0

* Shape data
ptr_RotatedVertices = $F4 ; Pointer to rotated vertices for Rotate functions.
ptr_Long_Shape = $F8 ; A long pointer to shape data.
ptr_Shape = $FC ; Pointer to shape data.

RETURN_ADDRESS = $FE ; store the return address here
