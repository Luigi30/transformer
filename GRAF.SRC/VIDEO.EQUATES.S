**************************************************
* Video equates.

**************************************************
* Video Constants
PIXEL_WIDTH = 320
PIXEL_HEIGHT = 200
BITS_PER_PIXEL = 4
PIXELS_PER_BYTE = 2
BYTES_PER_LINE = PIXEL_WIDTH/PIXELS_PER_BYTE

**************************************************
* Video memory registers
GS_VBLInt  = $00C019 ; VBlank interrupt? 0 = on, 1 = off
GS_TextColor  = $00C022 ; TTTTBBBB T=text, B=bg color
GS_VGCInt  = $00C023 ; $80 = any interrupt has fired
           ; $40 = 1Hz interrupt
           ; $20 = scanline interrupt
           ; $04 = 1Hz interrupt on/off
           ; $02 = scanline interrupt on/off
GS_SHRRegister =  $00C029 ; MLCXXXXB
           ; M = 0 for Apple II video, 1 for SHR
           ; L = linearize SHR VRAM?
           ; C = 1 for color, 0 for b/w
           ; XXXX = Reserved
           ; B = Bank latch? 1 = aux, 0 = ignored
GS_VGCIntClear =  $00C032 ; $40 = clear 1Hz int, $20 = clr scanline int
GS_BorderColor =  $00C034 ; XXXXCCCC X = DO NOT MODIFY, C = color

* Video memory locations
GS_PixelData  = $E12000 ; $E12000 - $E19CFF
GS_SCBs  = $E19D00 ; $E19D00 - $E19DC7
GS_Palettes  = $E19E00 ; 32 bytes per palette
           ; 16 palettes
           ; $E19E00 - $E19FFF

**************************************************
ROW_0 = 0
ROW_1 = 8
ROW_2 = 16
ROW_3 = 24
ROW_4 = 32
ROW_5 = 40
ROW_6 = 48
ROW_7 = 56
ROW_8 = 64
ROW_9 = 72
ROW_10 = 80
ROW_11 = 88
ROW_12 = 96
ROW_13 = 104
ROW_14 = 112
ROW_15 = 120
ROW_16 = 128
ROW_17 = 136
ROW_18 = 144
ROW_19 = 152
ROW_20 = 160
ROW_21 = 168
ROW_22 = 176
ROW_23 = 184
ROW_24 = 192
