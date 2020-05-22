*------------------------------------------------------------------------------------------
* Program    :  Bitmap Drawing Subroutines
* Written by :  Logan Harvell
* Date       :  9/22/2019
* Description:  Subroutines for displaying bitmap sections.
*               
*               The main goal of this program is to support
*               processing a bitmap (bmp) in memory, reading
*               the bmp file header, and reading pixel data to
*               draw the pixels to the screen.
*               
*               Parameters can be set to specifying a specific 
*               section of the bitmap to be displayed at 
*               specified offset from the top left corner of 
*               the screen.
* Dependencies: Utility.X68
*------------------------------------------------------------------------------------------

;Trap Codes
BMP_PRINT_STRING_TRAP_CODE      EQU     0
BMP_PEN_COLOR_TRAP_CODE         EQU     80
BMP_DRAW_PIXEL_TRAP_CODE        EQU     82

;Bitmap Values
BMP_SIGNATURE                   EQU     'BM'    ;values expected in first two bytes of bmp
BMP_PXL_BITSIZE_OFFSET          EQU     $1C     ;header offset for pixel bitsize (bpp)
BMP_PXL_DATA_ADDRESS_OFFSET     EQU     $0A     ;header offset for start address of pixel data
BMP_WIDTH_OFFSET                EQU     $12     ;header offset for image width
BMP_HEIGHT_OFFSET               EQU     $16     ;header offset for image height
BMP_IMAGE_SIZE_OFFSET           EQU     $22     ;header offset for image size
BMP_Bits_Per_Pixel              EQU     $20     ;number of bytes per pixel
BMP_Bytes_Per_Pixel             EQU     $04     ;number of bytes per pixel

SignatureErrorMessage dc.b 'File is missing the bitmap signature.',0
SignatureErrorMessageEnd

BitsizeErrorMessage dc.b 'Must be a 32bpp bitmap.',0
BitsizeErrorMessageEnd

    
*------------------------------------------------------------------------------------------
* Description:  Verifies address as a bitmap file.
* Parameters:   a0 = address of the bitmap in memory
* Return:       d7 = error status (0 for none, 1 for errors)
VerifyBitmap:
        move.l  d0,-(sp)                ;saves off value in d0
        
.CheckSignature:
        move.w  (a0),d0                 ;sets d0 with first word of file for comparing
        cmp.w   #BMP_SIGNATURE,d0       ;checks first word against bmp signature
        bne     .SignatureError         ;report error if word does not match signature

.CheckPixelBitsize:
        add.l   #BMP_PXL_BITSIZE_OFFSET,a0      ;adds bitsize offset to bitmap start address
        move.w  (a0),d0                         ;moves little endian bitsize offset into d0
        bsr     SwapByteOrderWord               ;converts bitsize offset to big endian       
        sub.l   #BMP_PXL_BITSIZE_OFFSET,a0      ;moves a0 back to bitmap address start

        cmp.l   #BMP_BITS_PER_PIXEL,d0          ;checks if bitmap is 32bpp
        bne     .BitsizeError                   ;else print a bitsize error message
        
        move.l  (sp)+,d0                ;moves saved value back to d0
        
        clr.l   d7                      ;sets status flag for no error
        rts
        
.SignatureError:
        ;loads error message and length for printing
        lea     SignatureErrorMessage,a1                                ;error string
        move.l  #(SignatureErrorMessageEnd-SignatureErrorMessage),d1    ;string length
        bra     .PrintErrorAndReturn

.BitsizeError:
        ;loads error message and length for printing
        lea     BitsizeErrorMessage,a1                                  ;error string
        move.l  #(BitsizeErrorMessageEnd-BitsizeErrorMessage),d1        ;string length
        bra     .PrintErrorAndReturn
      
.PrintErrorAndReturn:
        move.l  #BMP_PRINT_STRING_TRAP_CODE,d0
        trap    #15             ;prints error string to screen

        move.l  (sp)+,d0        ;moves saved value back to d0

        move.l  #1,d7           ;sets status flag for error
        rts
        

*------------------------------------------------------------------------------------------
* Description:  Verifies address as a bitmap file.
* Parameters:   a0 = address of the bitmap in memory
PreProcessBitmap:
        ;save offs registers
        move.l  a0,-(sp)
        move.l  d0,-(sp)
        move.l  d1,-(sp)
        
        move.l  #BMP_IMAGE_SIZE_OFFSET,d0       ;adds image size offset to bitmap start address
        move.l  (a0,d0),d0                      ;moves little endian image size into d0        
        bsr     SwapByteOrderLong               ;converts image size to big endian
        asr.l   #2,d0                           ;divides image size by bytes per pixel (4 bytes)
        move.l  d0,d1                           ;d1 = true image size in pixels
        sub.l   #1,d1                           ;minus 1 for dbra use

        move.l  #BMP_PXL_DATA_ADDRESS_OFFSET,d0 ;d0 = pixel data start address header offset
        move.l  (a0,d0),d0                      ;moves little endian pixel data address offset       
        bsr     SwapByteOrderLong               ;converts pixel data address offset to big endian
        add.l   d0,a0                           ;a0 = actual pixel data start address

.Loop:
        move.l  (a0),d0         ;gets pixel data
        lsr.l   #8,d0           ;shifts BBGGRRxx => 00BBGGRR
        move.l  d0,(a0)+        ;puts newly formatted value into memory
        dbra    d1,.Loop        ;loop through all pixels
        
.Done:
        ;move back saved register values
        move.l  (sp)+,d1
        move.l  (sp)+,d0
        move.l  (sp)+,a0

        rts

*------------------------------------------------------------------------------------------
* Description:  Retrieves the bitmap dimensions.
* Parameters:   a0 = address of the bitmap in memory
* Return:       d0 = bitmap size (top word = width, bottom word = height)
GetBitmapSize:
        move.l  d1,-(sp)                        ;saves off d1 value

        move.l  #BMP_HEIGHT_OFFSET,d0
        move.l  (a0,d0),d0                      ;gets little endian height from bitmap
        bsr     SwapByteOrderLong               ;converts height to big endian
        move.l  d0,d1                           ;moves height to d1, d0 needed free

        move.l  #BMP_WIDTH_OFFSET,d0
        move.l  (a0,d0),d0                      ;gets little endian width from bitmap
        bsr     SwapByteOrderLong               ;converts width to big endian
        swap.w  d0                              ;swaps width to top word
        move.w  d1,d0                           ;puts height into botttom word

        move.l  (sp)+,d1                        ;recovers d1 previous value from stack
        rts

*------------------------------------------------------------------------------------------
* Description:  Draws specified section of a bitmap to the screen
* Parameters:   a0 = address of the bitmap in memory
*               d0 = top left corner (x,y) of bitmap section to display,
*                    X is top word, Y is bottom word
*               d1 = widths/height of the bitmap section to display
*                    Width is top word, Height is bottom word
*               d2 = top left offset (x,y) of screen to draw
*                    X is top word, Y is bottom word
DrawBitmapSection:
        cmp.w   #0,d1           ;checks if draw size height is zero 
        beq     .Return         ;if zero, nothing needs to be drawn so return
        swap.w  d1  
        
        cmp.w   #0,d1           ;checks if draw size width is zero  
        beq     .Return         ;if zero, nothing needs to be drawn so return
        swap.w  d1

        movem.l d0-d7/a0-a6,-(sp)

.Setup:
        move.w  d1,d7   ;stores section height as Y iteration counter
        sub.w   #1,d7   ;minus one for dbra use

        add.w   d1,d2   ;d2 = bitmap section height + Y offset = initial Y draw position
        
        move.l  d0,d5   ;copies bitmap origin to d5 so d0 is free for subroutines

        ;this block gets the inverted Y origin, matching the pixel data order
        move.l  #BMP_HEIGHT_OFFSET,d0
        move.l  (a0,d0),d0              ;gets little endian height from bitmap        
        bsr     SwapByteOrderLong       ;converts bitmap height to big endian
        sub.w   d1,d0                   ;d0 = full height - section height
        sub.w   d5,d0                   ;d0 = height difference - section Y origin
        
        swap.w  d1      ;swaps bitmap section width to bottom word of d1

        move.w  d1,d6   ;stores width as X iteration counter
        sub.w   #1,d6   ;minus one for dbra use

        swap.w  d2      ;swaps top left X offset to bottom word of d2

        move.w  d2,d3   ;moves X offset as initial X draw position into d3
        move.w  d3,d4   ;copies initial X draw position for resetting X in DrawLoop
        add.w   d1,d2   ;d1 = section width + X offset = final X draw position

        swap.w  d2      ;swap back initial Y draw position to bottom word of d2                               
        swap.w  d5      ;swaps X origin of bitmap section to bottom word of d0
        
        move.w  d5,a3   ;copy X origin to a3, d5 is needed for a draw loop variable
        move.w  d0,a4   ;copy Y origin to free d0 for subroutine

        move.l  #BMP_WIDTH_OFFSET,d0
        move.l  (a0,d0),d0              ;gets little endian width from bitmap
        bsr     SwapByteOrderLong       ;converts bitmap width to big endian
        move.l  d0,d5                   ;d5 = full width
        sub.w   d1,d5                   ;d5 = full width - section width = pixels to skip per row
        mulu    #BMP_BYTES_PER_PIXEL,d5 ;multiply by bytes per pixel (4 bytes for 32bpp)
        
        move.l  a4,d1                       ;move inverted Y origin to d1 for multiplication
        mulu    #BMP_BYTES_PER_PIXEL,d1     ;multiply by bytes per pixel (4 bytes for 32bpp)
        mulu    d1,d0   ;d0 = full width * inverted Y origin
        move.l  a3,d1   ;move X origin to d1 for multiplication
        mulu    #4,d1   ;multiply by bytes per pixel (4 bytes for 32bpp)
        add.l   d1,d0   ;d0 = X origin + (full width * inverted Y) = first pixel index
        
        move.l  d0,a1   ;moves bitmap section pixel data start address offset to a1
        add.l   a0,a1   ;a1 = bitmap section pixel data offset + bitmap start address
        
        move.l  #BMP_PXL_DATA_ADDRESS_OFFSET,d0
        move.l  (a0,d0),d0              ;moves little endian pixel data start address offset into d0        
        bsr     SwapByteOrderLong       ;converts pixel data header offset to big endian
        add.l   d0,a1                   ;adds pixel data header offset to a1
                                        ;a1 now holds bmp section pixel data address 
        
        move.w  d6,a0   ;copy X iterator counter into a0 for resetting on a new row

.Loop:
        move.l  (a1)+,d1        ;moves current pixel value into d1
        
        ;unnecessary if bitmap pixel data is in 00BBGGRR format
        ;lsr.l   #8,d1           ;converts BBGGRRAA => 00BBGGRR
        
        move.l  #BMP_PEN_COLOR_TRAP_CODE,d0
        trap    #15             ;sets pen color
                     
        move.w  d3,d1           ;moves current X draw position into d1
        
        move.l  #BMP_DRAW_PIXEL_TRAP_CODE,d0
        trap    #15             ;draws pixel to screen at (d1,d2)
        
        add.w   #1,d3           ;increments X draw position
        dbra    d6,.Loop        ;if X draw position < final draw position, then loop 
        
        move.w  d4,d3           ;reset X draw position to initial X draw position
        move.w  a0,d6           ;reset X iteration counter

        add.l   d5,a1           ;skip past the rest of the row    
        sub.w   #1,d2           ;decrement Y draw position
        dbra    d7,.Loop        ;loop until all rows drawn

.Return:
        movem.l (sp)+,d0-d7/a0-a6
        rts





*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
