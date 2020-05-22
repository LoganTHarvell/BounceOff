*------------------------------------------------------------------------------------------
* Program    :  Utility Functions for General Purpose
* Written by :  Logan Harvell
* Date       :  9/22/2019
* Description:  This file is a container for various general purpose subroutines that
*               aid 68K assembly development.
*
*------------------------------------------------------------------------------------------

*------------------------------------------------------------------------------------------
* Trap Codes

UTILITY_GET_TIME_TRAP_CODE      EQU     8
UTILITY_DRAW_LINE_TRAP_CODE     EQU     84

*------------------------------------------------------------------------------------------
* 7-Segment Display Variables

SegmentDisplayDigits:
        dc.b    $3F
        dc.b    $06
        dc.b    $5B
        dc.b    $4F
        dc.b    $66
        dc.b    $6D
        dc.b    $7D
        dc.b    $07
        dc.b    $7F
        dc.b    $6F

SegmentTable:
        dc.l    0,0,0,0,0,0,0

* ----------------------------------------------------------------------------
* Description:  Swaps the bytes order in a word
* Parameters:   d0 = word to be byte swapped
* Return:       d0 = byte swapped word
SwapByteOrderWord:  
        rol.w   #8,d0       ;b2 b1 => b1 b2
        rts                 ;return


* ----------------------------------------------------------------------------
* Description:  Swaps the byte order in a long
* Parameters:   d0 = long to be byte swapped
* Return:       d0 = byte swapped long
SwapByteOrderLong:          
        rol.w   #8,d0       ;swaps bottom bytes, b4 b3 b2 b1 => b4 b3 b1 b2
        swap.w  d0          ;swaps words, b4 b3 b1 b2 => b1 b2 b4 b3
        rol.w   #8,d0       ;swaps bottom bytes, b1 b2 b4 b3 => b1 b2 b3 b4
        rts

* ----------------------------------------------------------------------------
* Description:  Gets time and returns the current frame time the delta time
* Parameters:   d0 = last frame time
* Return:       d0 = current frame time
*               d1 = delta time
GetDeltaTime:
        move.l  d2,-(sp)                ;saves off pre-existing value in d2
        move.l  d0,d2                   ;copies last frame time to d2
        
        moveq   #UTILITY_GET_TIME_TRAP_CODE,d0 
        trap    #15                     ;d1 = current frame time
        
        move.l  d1,d0                   ;d0 = current frame time
        sub.l   d2,d1                   ;d1 = delta time between frames

        move.l (sp)+,d2                 ;recover d2 from stack
        rts

* ----------------------------------------------------------------------------
* Description:  Gets random number in range
* Parameters:   d0 = min value
*               d1 = max value
*               d2 = seed mask
* Return        d0 = random value
GetRandomNumber:
        movem.l d3-d4,-(sp)

        move.l  d0,d3
        move.l  d1,d4
        
        moveq   #UTILITY_GET_TIME_TRAP_CODE,d0
        trap    #15

        and.l   d2,d1
        divu    d4,d1
        swap.w  d1
        ext.l   d1
        add.w   d3,d1

        move.l  d1,d0

        movem.l (sp)+,d3-d4
        rts


* ----------------------------------------------------------------------------
* Description:  Initializes 7 segment display function table
InitSegmentTable:
        move.l  a0,-(sp)

        lea     SegmentTable,a0
        move.l  #DrawSegmentA,(a0)+
        move.l  #DrawSegmentB,(a0)+
        move.l  #DrawSegmentC,(a0)+
        move.l  #DrawSegmentD,(a0)+
        move.l  #DrawSegmentE,(a0)+
        move.l  #DrawSegmentF,(a0)+
        move.l  #DrawSegmentG,(a0)+
        
        move.l  (sp)+,a0
        rts


* ----------------------------------------------------------------------------
* Description:  Draws a number with a 7 segment display
* Parameters:   d0 = X position
*               d1 = Y position
*               d2 = digit width               
*               d3 = digit
DrawDigit:
        movem.l d0-d7/a0-a1,-(sp)
        
        * copies X and Y position and digit width to d5-d7
        move.l  d0,d5
        move.l  d1,d6
        move.l  d2,d7

        lea     SegmentDisplayDigits,a0
        move.b  (a0,d3),d3              ;gets digit bitmask from table
        
        lea     SegmentTable,a0         ;gets segment drawing function table
        clr.l   d4

.Loop:
        lsr.b   #1,d3           ;checks if segment bit in bitmask is set
        bcc     .Continue       ;skips segment drawing if not set
        
        move.l  (a0,d4),a1      ;gets segment draw function from table

        movem.l  d3-d4,-(sp)
        jsr     (a1)            ;jumps to appropriate drawing subroutine
        movem.l  (sp)+,d3-d4

.Continue:
        add.l   #4,d4           ;increments address counter
        cmp.l   #28,d4          ;checks if all addresses have been visited
        bne     .Loop           

        movem.l  (sp)+,d0-d7/a0-a1
        rts

DrawSegmentA:
        move.l  #UTILITY_DRAW_LINE_TRAP_CODE,d0
        move.l  d5,d1
        move.l  d6,d2
        move.l  d5,d3
        add.l   d7,d3
        move.l  d6,d4
        trap    #15
        rts

DrawSegmentB:
        move.l  #UTILITY_DRAW_LINE_TRAP_CODE,d0
        move.l  d5,d1
        add.l   d7,d1
        move.l  d6,d2
        move.l  d1,d3
        move.l  d6,d4
        add.l   d7,d4
        trap    #15
        rts

DrawSegmentC:
        move.l  #UTILITY_DRAW_LINE_TRAP_CODE,d0
        move.l  d5,d1
        add.l   d7,d1
        move.l  d6,d2
        add.l   d7,d2
        move.l  d1,d3
        move.l  d2,d4
        add.l   d7,d4
        trap    #15
        rts
        
DrawSegmentD:
        move.l  #UTILITY_DRAW_LINE_TRAP_CODE,d0
        move.l  d5,d1
        move.l  d6,d2
        add.l   d7,d2
        add.l   d7,d2
        move.l  d5,d3
        add.l   d7,d3
        move.l  d2,d4
        trap    #15
        rts
        
DrawSegmentE:
        move.l  #UTILITY_DRAW_LINE_TRAP_CODE,d0
        move.l  d5,d1
        move.l  d6,d2
        add.l   d7,d2
        move.l  d5,d3
        move.l  d2,d4
        add.l   d7,d4
        trap    #15
        rts
        
DrawSegmentF:
        move.l  #UTILITY_DRAW_LINE_TRAP_CODE,d0
        move.l  d5,d1
        move.l  d6,d2
        move.l  d5,d3
        move.l  d6,d4
        add.l   d7,d4
        trap    #15
        rts
        
DrawSegmentG:
        move.l  #UTILITY_DRAW_LINE_TRAP_CODE,d0
        move.l  d5,d1
        move.l  d6,d2
        add.l   d7,d2
        move.l  d5,d3
        add.l   d7,d3
        move.l  d2,d4
        trap    #15
        rts


*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
