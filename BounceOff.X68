*------------------------------------------------------------------------------------------
* Program:      Bounce Off
* Written by:   Logan Harvell
* Created:      9/30/2019
* Last updated: 
* Description:  A competitive multiplayer bouncy ball game written in 68k assembly.
*               
*               
*------------------------------------------------------------------------------------------

        ORG     $1000

*------------------------------------------------------------------------------------------
* Includes

        INCLUDE "BounceOffConfig.X68"
        INCLUDE "Utility.X68"
        INCLUDE "BounceOffRender.X68"
        INCLUDE "BounceOffMovement.X68"

*------------------------------------------------------------------------------------------
* Program Start

START   

        * Sets drawing mode to use double buffering
        move.l  #DRAWING_MODE_TRAP_CODE,d0
        move.l  #DOUBLE_BUFFER_DRAWING_MODE,d1
        trap    #15

        bsr     InitSegmentTable
        
*-------------------------------------------------------------------------------
* Initialization

Initialization:

        lea     GameScreen,a0
        bsr     VerifyBitmap
        bne     EndGame
        
        lea     StartScreen,a0
        bsr     VerifyBitmap
        bne     EndGame

        lea     StartScreen,a0
        bsr     DrawScreenWithLoading

        moveq   #DISPLAY_BUFFER_TRAP_CODE,d0
        trap    #15

        lea     GameScreen,a0
        bsr     DrawScreen

.GetInput:
        moveq   #GET_INPUT_TRAP_CODE,d0
        move.l  #END_SCREEN_INPUTS,d1
        trap    #15

        btst    #24,d1
        beq     .GetInput

StartGame:
        bsr     DrawPlayerOneScore
        bsr     DrawPlayerTwoScore

        moveq   #DISPLAY_BUFFER_TRAP_CODE,d0
        trap    #15
        
        lea     GameIsRunning,a6    ;a6 = address for game running flag

        moveq   #GET_TIME_TRAP_CODE,d0 
        trap    #15                     ;d1 = current frame time
        move.l  d1,d3        

        bsr     UpdatePickUp
        

*-------------------------------------------------------------------------------
* Game Loop

GameLoop:
        move.b  (a6),d0
        beq     EndGameScreen

        moveq   #GET_TIME_TRAP_CODE,d0 
        trap    #15                     ;d1 = current frame time
        
        move.l  d1,d0                   ;d0 = current frame time
        sub.l   d3,d0                   ;d0 = delta time between frames
        move.l  d1,d3                   ;d3 = current frame time for next frame use

        add.l   d0,d4
        cmp.l   #INPUT_DELAY,d4          
        blt     .Update
        clr.l   d4

.HandleInput:
        bsr     UpdatePlayerOneVelocity
        bsr     UpdatePlayerTwoVelocity
        
.Update:
        bsr     InvalPlayerOne
        bsr     InvalPlayerTwo
        
        bsr     UpdatePlayerOnePosition
        bsr     UpdatePlayerTwoPosition

        bsr     UpdatePlayerOneScore
        bsr     UpdatePlayerTwoScore

        bsr     InvalPickUp
        bsr     UpdatePickUp

.Render:
        bsr     DrawPlayerOneScore
        bsr     DrawPlayerTwoScore
        bsr     DrawPickUp
        bsr     DrawPlayerOne
        bsr     DrawPlayerTwo

        moveq   #DISPLAY_BUFFER_TRAP_CODE,d0
        trap    #15

        bra     GameLoop

*-------------------------------------------------------------------------------
* End Game Screen

EndGameScreen:
        moveq   #SET_FILL_COLOR_TRAP_CODE,d0
        moveq   #COLOR_BLACK,d1
        trap    #15

        cmp.b   #MAX_SCORE,PlayerOneScore
        bne     .PlayerTwoWins         
        
.PlayerOneWins:
        lea     PlayerOneWinScreen,a0
        bra     .DrawScreen

.PlayerTwoWins:
        lea     PlayerTwoWinScreen,a0

.DrawScreen:
        bsr     DrawPanelInCenter

        moveq   #DISPLAY_BUFFER_TRAP_CODE,d0
        trap    #15

.ResetVariables:
        move.b  #1,GameIsRunning
        move.b  #0,PlayerOneScore
        move.b  #0,PlayerTwoScore 
        move.b  #1,IncreaseP1Score
        move.b  #1,IncreaseP2Score

        move.b  #0,PickUpExists
        move.b  #0,PickUpIsDrawn

        move.l   #0,FrameTime

        move.l   #0,PlayerOneVelocityX
        move.l   #0,PlayerOneVelocityY
        move.l   #0,PlayerTwoVelocityX
        move.l   #0,PlayerTwoVelocityY

        move.l  #PLAYER_ONE_START_X,PlayerOnePositionX
        move.l  #PLAYER_ONE_START_Y,PlayerOnePositionY
        move.l  #PLAYER_TWO_START_X,PlayerTwoPositionX
        move.l  #PLAYER_TWO_START_Y,PlayerTwoPositionY

.GetInput:
        moveq   #GET_INPUT_TRAP_CODE,d0
        move.l  #END_SCREEN_INPUTS,d1
        trap    #15

        btst    #0,d1
        bne     EndGame     

        btst    #8,d1
        bne     Initialization

        btst    #16,d1
        bne     .Restart

        btst    #24,d1
        bne     .Restart   

        bra     .GetInput   

.Restart:
        lea     GameScreen,a0
        bsr     DrawScreenWithLoading
        bra     StartGame


*-------------------------------------------------------------------------------
* End Game

EndGame:
        move.b  #9,D0
        trap    #15             Halt Simulator
        stop    #$2000    

*------------------------------------------------------------------------------------------
* Binary Includes
    
StartScreen             INCBIN "Assets/StartScreen.bmp"
GameScreen              INCBIN "Assets/GameScreen.bmp"
PlayerOneWinScreen      INCBIN "Assets/PlayerOneWinScreen.bmp"
PlayerTwoWinScreen      INCBIN "Assets/PlayerTwoWinScreen.bmp"

*------------------------------------------------------------------------------------------
* Program End

        END     START
















*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
