*------------------------------------------------------------------------------------------
* Program:      Bounce Off (Render)
* Written by:   Logan Harvell
* Created:      10/5/2019
* Last updated: 
* Description:  File containing rendering subroutines for the Bounce Off assembly game.
* Dependencies: Binary files with the labels StartScreen, GameScreen, and EndScreen.
*------------------------------------------------------------------------------------------

*------------------------------------------------------------------------------------------
* Includes

    INCLUDE "DrawBitmap.X68"

* ----------------------------------------------------------------------------
* Description:  Draws a full size bitmap file to the screen
* Parameters:   a0 = bitmap file to draw to screen
DrawScreen:
        movem.l d0-d2,-(sp)

        bsr     GetBitmapSize
        move.l  d0,d1           ;d1 = bitmap size

        clr.l   d0              ;d0 = origin point at (0,0)
        clr.l   d2              ;d2 = offset of (0,0)
        
        bsr DrawBitmapSection   ;draws whole bitmap
        
        movem.l (sp)+,d0-d2
        rts


* ----------------------------------------------------------------------------
* Description:  Draws a full size bitmap file to the screen
* Parameters:   a0 = bitmap file to draw to screen
DrawPanelInCenter:
        movem.l d0-d2,-(sp)

        bsr     GetBitmapSize
        move.l  d0,d1           ;d1 = bitmap size
        move.l  d0,d2           ;d2 = bitmap size

        clr.l   d0              ;d0 = bitmap origin at (0,0)

        asr.w   #1,d2                           ;d2 = bitmap height / 2
        neg.w   d2                              ;d2 = negative bitmap height / 2
        add.l   #GAME_SCREEN_HEIGHT>>1,d2       ;d2 = Y position for center drawing
        swap.w  d2                              ;move Y position to top word
        asr.w   #1,d2                           ;d2 = bitmap width / 2
        neg.w   d2                              ;d2 = negative bitmap width / 2
        add.l   #GAME_SCREEN_WIDTH>>1,d2        ;d2 = X position for center drawing
        swap.w  d2                              ;d2 word swapped X on top, Y on bottom
        
        bsr DrawBitmapSection   ;draws whole bitmap centered on screen
        
        movem.l (sp)+,d0-d2
        rts


* ----------------------------------------------------------------------------
* Description:  Draws a full size bitmap file to the screen with loading text.
* Parameters:   a0 = bitmap file to draw to screen
DrawScreenWithLoading:
        movem.l d0-d2/a1,-(sp)

        * prints loading message to screen
        lea     LOADING_STRING,a1
        move.w  #LOADING_STRING_POSITION_X,d1
        move.w  #LOADING_STRING_POSITION_Y,d2
        moveq   #DRAW_STRING_TRAP_CODE,d0
        trap    #15

        moveq   #DISPLAY_BUFFER_TRAP_CODE,d0
        trap    #15

        * draws whole bitmap to screen
        bsr     GetBitmapSize
        move.l  d0,d1           ;d1 = bitmap size

        clr.l   d0              ;d0 = origin point at (0,0)
        clr.l   d2              ;d2 = offset of (0,0)
        
        bsr DrawBitmapSection   ;draws whole bitmap

        movem.l (sp)+,d0-d2/a1
        rts


* ----------------------------------------------------------------------------
* Description:  Draws player one's score to the screen
* Parameters:   a0 = game screen bitmap address
DrawPlayerOneScore:
        movem.l d0/a1,-(sp)
        
        * exits early if P1 score has not changed
        lea     IncreaseP1Score,a1
        move.b  (a1),d0
        beq     .Done

        movem.l d1-d3,-(sp)

.InvalScore:
        move.w  #PLAYER_ONE_SCORE_DRAW_X-(INVAL_PADDING>>1),d0
        swap.w  d0
        move.w  #SCORE_DRAW_Y-(INVAL_PADDING>>1),d0

        move.w  #(SEGMENT_DISPLAY_WIDTH<<1)+INVAL_PADDING,d1
        move.w  d1,d2
        swap.w  d1
        move.w  d2,d1

        move.l  d0,d2

        bsr     DrawBitmapSection

.DrawScore:
        moveq   #SET_PEN_COLOR_TRAP_CODE,d0
        move.l  #COLOR_PLAYER_ONE,d1
        trap    #15

        moveq   #SET_PEN_WIDTH_TRAP_CODE,d0
        moveq   #SEGMENT_LINE_WIDTH,d1
        trap    #15
        
        move.l  #PLAYER_ONE_SCORE_DRAW_X,d0
        move.l  #SCORE_DRAW_Y,d1
        move.l  #SEGMENT_DISPLAY_WIDTH,d2
        move.b  PlayerOneScore,d3
        ext.w   d3
        ext.l   d3
        bsr     DrawDigit

        move.b  #0,(a1)
        movem.l (sp)+,d1-d3

.Done:
        movem.l  (sp)+,d0/a1
        rts


* ----------------------------------------------------------------------------
* Description:  Draws player two's score to the screen
DrawPlayerTwoScore:
        movem.l d0/a1,-(sp)     ;saves register values to the stack
        
        * Exits early if P2's score has not changed
        lea     IncreaseP2Score,a1
        move.b  (a1),d0
        beq     .Done

        movem.l d1-d3,-(sp)     ;saves register values to the stack

.InvalScore:
        move.w  #PLAYER_TWO_SCORE_DRAW_X-(INVAL_PADDING>>1),d0
        swap.w  d0
        move.w  #SCORE_DRAW_Y-(INVAL_PADDING>>1),d0

        move.w  #(SEGMENT_DISPLAY_WIDTH<<1)+INVAL_PADDING,d1
        move.w  d1,d2
        swap.w  d1
        move.w  d2,d1

        move.l  d0,d2

        bsr     DrawBitmapSection

.DrawScore:
        moveq   #SET_PEN_COLOR_TRAP_CODE,d0
        move.l  #COLOR_PLAYER_TWO,d1
        trap    #15

        moveq   #SET_PEN_WIDTH_TRAP_CODE,d0
        moveq   #SEGMENT_LINE_WIDTH,d1
        trap    #15

        move.l  #PLAYER_TWO_SCORE_DRAW_X,d0
        move.l  #SCORE_DRAW_Y,d1
        move.l  #SEGMENT_DISPLAY_WIDTH,d2
        move.b  PlayerTwoScore,d3
        ext.w   d3
        ext.l   d3
        bsr     DrawDigit

        move.b  #0,(a1)
        movem.l (sp)+,d1-d3

.Done:
        movem.l  (sp)+,d0/a1
        rts


* ----------------------------------------------------------------------------
* Description:  Draws a circle with player one's attributes to the screen
DrawPlayerOne:
        movem.l d0-d3,-(sp)

        * sets up and draws P1 circle
        move.l  PlayerOnePositionX,d0
        move.l  #COLOR_PLAYER_ONE,d1
        move.l  PlayerOnePositionY,d2
        move.l  #PLAYER_SIZE,d3

        bsr     DrawCircle

        movem.l (sp)+,d0-d3
        rts

* ----------------------------------------------------------------------------
* Description:  Draws a circle with player two's attributes to the screen
DrawPlayerTwo:
        movem.l d0-d3,-(sp)

        * sets up and draws P2 circle
        move.l  PlayerTwoPositionX,d0
        move.l  #COLOR_PLAYER_TWO,d1
        move.l  PlayerTwoPositionY,d2
        move.l  #PLAYER_SIZE,d3
        
        bsr     DrawCircle

        movem.l (sp)+,d0-d3
        rts


* ----------------------------------------------------------------------------
* Description:  Draws a circle with the pickup's attributes to the screen
DrawPickUp:
        movem.l  d0/a0,-(sp)

        * exits early if a pickup does not exist
        move.b  PickUpExists,d0
        beq     .Done

        * exits early if the pickup is already drawn
        lea     PickUpIsDrawn,a0
        move.b  (a0),d0
        bne     .Done

        movem.l d1-d3,-(sp)
        
        * draws pickup circle
        move.l  PickUpPositionX,d0
        move.l  #COLOR_PICKUP,d1
        move.l  PickUpPositionY,d2
        move.l  #PICKUP_SIZE,d3

        bsr     DrawCircle

        move.b  #1,(a0)         ;sets pick up is drawn flag

        movem.l (sp)+,d1-d3

.Done
        movem.l  (sp)+,d0/a0
        rts


* ----------------------------------------------------------------------------
* Description:  Draws a circle to the screen
* Parameters:   d0 = X position
*               d1 = draw color
*               d2 = Y position
*               d3 = size
DrawCircle:
        movem.l d0-d4,-(sp)
        move.l  d0,d4

        moveq   #SET_PEN_COLOR_TRAP_CODE,d0
        trap    #15
        
        moveq   #SET_FILL_COLOR_TRAP_CODE,d0
        trap    #15

        move.l  d4,d1

        * adds a half to position for rounding
        add.l   #(1<<(FIXED_POINT_PRECISION-1)),d1
        add.l   #(1<<(FIXED_POINT_PRECISION-1)),d2

        * converts fixed point positions to integers
        moveq   #FIXED_POINT_PRECISION,d0
        lsr.l   d0,d1   ;d1 = circle left X
        lsr.l   d0,d2   ;d2 = circle upper Y

        move.l   d3,d4  ;copy circle width drom d3 to d4

        add.w   d1,d3   ;d3 = circle right X
        add.w   d2,d4   ;d4 = circle lower Y

        moveq   #DRAW_CIRCLE_TRAP_CODE,d0
        trap    #15

        movem.l (sp)+,d0-d4
        rts


* ----------------------------------------------------------------------------
* Description:  Invals player one renders left on the screen
* Parameters:   a0 = address of the bitmap in memory
InvalPlayerOne:
        movem.l d0-d3,-(sp)

        * draws bitmap background over previous player position
        move.l  PlayerOnePositionX,d0
        move.l  PlayerOnePositionY,d1        
        moveq   #PLAYER_SIZE,d2
        moveq   #INVAL_PADDING,d3

        bsr     InvalCircle

        movem.l (sp)+,d0-d3
        rts

* ----------------------------------------------------------------------------
* Description:  Invals player tw0 renders left on the screen
* Parameters:   a0 = address of the bitmap in memory
InvalPlayerTwo:
        movem.l d0-d3,-(sp)

        * draws bitmap background over previous player position
        move.l  PlayerTwoPositionX,d0        
        move.l  PlayerTwoPositionY,d1
        moveq   #PLAYER_SIZE,d2
        moveq   #INVAL_PADDING,d3

        bsr     InvalCircle

        movem.l (sp)+,d0-d3
        rts


* ----------------------------------------------------------------------------
* Description:  Invals pickup renders left on the screen
* Parameters:   a0 = address of the bitmap in memory
InvalPickUp:
        movem.l  d0/a1,-(sp)
        
        * exits early if pickup does not exist
        move.b  PickUpExists,d0
        bne     .Done

        * exits early if pickup is no longer drawn
        lea     PickUpIsDrawn,a1
        move.b  (a1),d0
        beq     .Done

        movem.l d1-d3,-(sp)

        * draws bitmap background over old pickup location 
        move.l  PickUpPositionX,d0        
        move.l  PickUpPositionY,d1
        moveq   #PICKUP_SIZE,d2
        moveq   #INVAL_PADDING,d3

        bsr     InvalCircle

        move.b  #0,(a1)                 ;sets pickup is drawn flag false

        movem.l (sp)+,d1-d3

.Done:
        movem.l  (sp)+,d0/a1
        rts

* ----------------------------------------------------------------------------
* Description:  Invals a player render left on the screen
* Parameters:   a0 = address of the bitmap in memory
*               d0 = X position
*               d1 = Y position
*               d2 = size
*               d3 = padding
InvalCircle:
        move.l  d4,-(sp)

        * adds a half to circle position for rounding
        add.l   #(1<<(FIXED_POINT_PRECISION-1)),d0
        add.l   #(1<<(FIXED_POINT_PRECISION-1)),d1

        * coverts fixed point positions to integers
        moveq   #FIXED_POINT_PRECISION,d4
        lsr.l   d4,d0   ;d0 = left X position
        lsr.l   d4,d1   ;d1 = upper Y position

        add.l   d3,d2   ;d2 = inval size
        asr.l   #1,d3   ;d2 = inval size /2
        sub.l   d3,d0   ;d0 = X position shifted over by inval padding
        sub.l   d3,d1   ;d1 = Y position shifted over by inval padding

        * sets d0 with X and Y position in top and bottom word
        swap.w  d0      
        move.w  d1,d0

        * sets d1 with inval size
        move.w  d2,d1
        swap.w  d1
        move.w  d2,d1

        * copies bitmap draw position to bitmap offset
        move.l d0,d2

        bsr     DrawBitmapSection

        move.l  (sp)+,d4
        rts




*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
