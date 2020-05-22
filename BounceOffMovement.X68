*------------------------------------------------------------------------------------------
* Program:      Bounce Off (Input)
* Written by:   Logan Harvell
* Created:      10/5/2019
* Last updated: 
* Description:  Input handling subroutines for the Bounce Off assembly game.
* Dependencies: BounceOffConfig.X68
*------------------------------------------------------------------------------------------

* ----------------------------------------------------------------------------
* Description:  Updates player one's velocity based on wasd keys
* Parameters:   d0 = delta time
UpdatePlayerOneVelocity:
        movem.l d0-d3/a0-a1,-(sp)

        move.l  d0,d3                   ;copies delta time to d3

        moveq   #GET_INPUT_TRAP_CODE,d0
        move.l  #PLAYER_ONE_INPUTS,d1
        trap    #15

        lea     PlayerOneVelocityX,a0
        move.l  (a0),d0

        lea     PlayerOneVelocityY,a1
        move.l  (a1),d2

        bsr     UpdateVelocity

        move.l  d0,(a0)
        move.l  d2,(a1)

        movem.l (sp)+,d0-d3/a0-a1
        rts


* ----------------------------------------------------------------------------
* Description:  Updates player two's velocity based on wasd keys
* Parameters:   d0 = delta time
UpdatePlayerTwoVelocity:
        movem.l d0-d3/a0-a1,-(sp)

        move.l  d0,d3                   ;copies delta time to d3

        moveq   #GET_INPUT_TRAP_CODE,d0
        move.l  #PLAYER_TWO_INPUTS,d1
        trap    #15

        lea     PlayerTwoVelocityX,a0
        move.l  (a0),d0

        lea     PlayerTwoVelocityY,a1
        move.l  (a1),d2

        bsr     UpdateVelocity

        move.l  d0,(a0)
        move.l  d2,(a1)

        movem.l (sp)+,d0-d3/a0-a1
        rts


* ----------------------------------------------------------------------------
* Description:  Updates velocity
* Parameters:   d0 = current X velocity
*               d1 = input bitmask (up=24, left=16, down=8, right=0)
*               d2 = current Y velocity
*               d3 = delta time
* Return:       d0 = updated X velocity
*               d1 = updated Y velocity
UpdateVelocity:

.UpdateRight:
        btst.l  #0,d1
        beq     .UpdateDown

        cmp.l   #MAX_VELOCITY,d0
        bgt     .UpdateDown

        add.l   #PLAYER_ACCELERATION,d0

.UpdateDown
        btst.l  #8,d1
        beq     .UpdateLeft

        cmp.l   #MAX_VELOCITY,d2
        bgt     .UpdateLeft

        add.l   #PLAYER_ACCELERATION,d2

.UpdateLeft:
        btst.l  #16,d1
        beq     .UpdateUp

        cmp.l   #-MAX_VELOCITY,d0
        blt     .UpdateUp

        sub.l   #PLAYER_ACCELERATION,d0

.UpdateUp
        btst.l  #24,d1
        beq     .Done

        cmp.l   #-MAX_VELOCITY,d2
        blt     .Done

        sub.l   #PLAYER_ACCELERATION,d2

.Done
        move.l  d2,d1
        rts


* ----------------------------------------------------------------------------
* Description:  Updates player one's position
* Parameters:   d0 = delta time
UpdatePlayerOnePosition:
        movem.l d0-d6/a0-a3,-(sp)

        move.l  d0,d4                   ;copy delta time to d4

        lea     PlayerOneVelocityX,a0
        lea     PlayerOneVelocityY,a1
        move.l  (a0),d2
        move.l  (a1),d3

        lea     PlayerOnePositionX,a2
        lea     PlayerOnePositionY,a3
        move.l  (a2),d0
        move.l  (a3),d1

        move.l  PlayerTwoPositionX,d5
        move.l  PlayerTwoPositionY,d6

        bsr     UpdatePosition
        bsr     CheckCollisions

        move.l  d0,(a2)
        move.l  d1,(a3)

        movem.l (sp)+,d0-d6/a0-a3
        rts

* ----------------------------------------------------------------------------
* Description:  Updates player two's position
* Parameters:   d0 = delta time
UpdatePlayerTwoPosition:
        movem.l d0-d6/a0-a3,-(sp)

        move.l  d0,d4                   ;copy delta time to d4

        lea     PlayerTwoVelocityX,a0
        lea     PlayerTwoVelocityY,a1
        move.l  (a0),d2
        move.l  (a1),d3

        lea     PlayerTwoPositionX,a2
        lea     PlayerTwoPositionY,a3
        move.l  (a2),d0
        move.l  (a3),d1

        move.l  PlayerOnePositionX,d5
        move.l  PlayerOnePositionY,d6

        bsr     UpdatePosition
        bsr     CheckCollisions
        
        move.l  d0,(a2)
        move.l  d1,(a3)
        
        movem.l (sp)+,d0-d6/a0-a3
        rts


* ----------------------------------------------------------------------------
* Description:  Updates player position
* Parameters:   d0 = current X position
*               d1 = current Y position
*               d2 = current X velocity
*               d3 = current Y velocity
*               d4 = delta time
* Return:       d0 = updated X position
*               d1 = updated Y position
UpdatePosition:
        movem.l d2-d3,-(sp)

        muls    d4,d2
        muls    d4,d3
        add.l   d2,d0
        add.l   d3,d1

        movem.l (sp)+,d2-d3
        rts


* ----------------------------------------------------------------------------
* Description:  Updates player position and velocity due to collisions
* Parameters:   d0 = current X position
*               d1 = current Y position
*               d2 = current X velocity
*               d3 = current Y velocity
*               d4 = delta time
*               d5 = opponent X position
*               d6 = opponent Y position
*               a0 = address of X velocity
*               a1 = address of Y velocity
* Return:       d0 = updated X position
*               d1 = updated Y position
CheckCollisions:
        movem.l  d7,-(sp)

.CheckLeftWall:
        cmp.l   #LEFT_WALL<<FIXED_POINT_PRECISION,d0
        bgt     .CheckRightWall    
        
        bsr     .ReverseVelocityX
        bsr     UpdatePosition
        bra     .CheckTopWall

.CheckRightWall:
        cmp.l   #(RIGHT_WALL-PLAYER_SIZE)<<FIXED_POINT_PRECISION,d0
        blt     .CheckTopWall
        
        bsr     .ReverseVelocityX
        bsr     UpdatePosition

.CheckTopWall:
        cmp.l   #TOP_WALL<<FIXED_POINT_PRECISION,d1
        bgt     .CheckBottomWall
        
        bsr     .ReverseVelocityY
        bsr     UpdatePosition
        bra     .CheckOpponent

.CheckBottomWall:
        cmp.l   #(BOTTOM_WALL-PLAYER_SIZE)<<FIXED_POINT_PRECISION,d1
        blt     .CheckOpponent
        
        bsr     .ReverseVelocityY
        bsr     UpdatePosition

.CheckOpponent:

        move.l   #PLAYER_SIZE<<FIXED_POINT_PRECISION,d7
        add.l   d0,d7           ;d7 = max X1
        cmp.l   d5,d7           ;if max X1 < min X2
        blt     .Done           ;then no collision

        move.l  #PLAYER_SIZE<<FIXED_POINT_PRECISION,d7
        add.l   d5,d7           ;d7 = max X2
        cmp.l   d0,d7           ;if max X2 < min X1
        blt     .Done           ;then no collision

        move.l   #PLAYER_SIZE<<FIXED_POINT_PRECISION,d7
        add.l   d1,d7           ;d7 = max Y1
        cmp.l   d6,d7           ;if max Y1 < min Y2
        blt     .Done           ;then no collision

        move.l  #PLAYER_SIZE<<FIXED_POINT_PRECISION,d7
        add.l   d6,d7           ;d7 = max Y2
        cmp.l   d1,d7           ;if max Y2 < min Y1
        blt     .Done           ;then no collision

        bsr     .ReverseVelocityX
        bsr     .ReverseVelocityY
        bsr     UpdatePosition

.Done:
        movem.l  (sp)+,d7
        rts

.ReverseVelocityX:
        neg.l   d2
        move.l  d2,(a0)
        rts

.ReverseVelocityY:
        neg.l   d3
        move.l  d3,(a1)
        rts


* ----------------------------------------------------------------------------
* Description:  Checks for pick up event and updates appropriately
UpdatePlayerOneScore:
        movem.l d0/a0,-(sp)

        * exits early if no pickup exists
        lea     PickupExists,a0
        move.b  (a0),d0
        beq     .Done

        movem.l d1-d4,-(sp)

        * checks if player one is colliding with pickup
        move.l  PickUpPositionX,d0
        move.l  PickUpPositionY,d1
        moveq   #PICKUP_RADIUS,d2
        move.l  PlayerOnePositionX,d3
        move.l  PlayerOnePositionY,d4

        bsr     CheckPickUp
        bne     .AddScore       ;on collision, add to score

.AddReturn:
        movem.l (sp)+,d1-d4

.Done:
        movem.l (sp)+,d0/a0
        rts

.AddScore:
        move.b  #0,(a0)                 ;sets pickup exists flag to false

        move.b  #1,IncreaseP1Score      ;sets score increase flag to true

        ;increments score and checks if game is over
        lea     PlayerOneScore,a0
        add.b   #1,(a0)
        cmp.b   #MAX_SCORE,(a0)
        beq     .SetGameOver
        bra     .AddReturn

.SetGameOver:
        *sets game is running flag to false when max score is met
        move.b  #0,GameIsRunning
        bra .AddReturn

* ----------------------------------------------------------------------------
* Description:  Checks for pick up event and updates appropriately
UpdatePlayerTwoScore:
        movem.l d0/a0,-(sp)

        * exits early if no pickup exists
        lea     PickupExists,a0
        move.b  (a0),d0
        beq     .Done

        movem.l d1-d4,-(sp)

        * checks if player one is colliding with pickup
        move.l  PickUpPositionX,d0
        move.l  PickUpPositionY,d1
        moveq   #PICKUP_RADIUS,d2
        move.l  PlayerTwoPositionX,d3
        move.l  PlayerTwoPositionY,d4

        bsr     CheckPickUp
        bne     .AddScore               ;on collision, add to score

.AddReturn:
        movem.l (sp)+,d1-d4

.Done:
        movem.l (sp)+,d0/a0
        rts

.AddScore:
        move.b  #0,(a0)                 ;sets pickup exists flag to false

        move.b  #1,IncreaseP2Score      ;sets score increase flag to true

        ;increments score and checks if game is over
        lea     PlayerTwoScore,a0
        add.b   #1,(a0)
        cmp.b   #MAX_SCORE,(a0)
        beq     .SetGameOver
        bra     .AddReturn

.SetGameOver:
        *sets game is running flag to false when max score is met
        move.b  #0,GameIsRunning
        bra     .AddReturn


* ----------------------------------------------------------------------------
* Description:  Creates a pickup if none exists
UpdatePickUp:
        movem.l  d0/a0,-(sp)

.CheckPickUpExists:
        lea     PickupExists,a0
        move.b  (a0),d0
        bne     .Done

        movem.l d1-d5,-(sp)

.GetPickUpPositionX:
        move.l  #PICKUP_MIN_X,d0
        move.l  #PICKUP_MAX_X,d1
        move.l  #PICKUP_MAX_X_SEED_MASK,d2

        bsr     GetRandomNumber
        move.l  d0,d5

.GetPickUpPositionY:
        move.l  #PICKUP_MIN_Y,d0
        move.l  #PICKUP_MAX_Y,d1
        move.l  #PICKUP_MAX_Y_SEED_MASK,d2

        bsr     GetRandomNumber
        move.l  d0,d1
        
.CheckPickUpLocation:
        * converts pickup location to fixed point
        moveq   #FIXED_POINT_PRECISION,d4
        move.l  d5,d0
        lsl.l   d4,d0
        lsl.l   d4,d1

        * uses a radius 4x the size of the pickup for avoiding players
        move.l  #PICKUP_SIZE<<(FIXED_POINT_PRECISION+2),d2

        * checks if pickup location is too close to player one
        move.l  PlayerOnePositionX,d3
        move.l  PlayerOnePositionY,d4

        bsr     CheckPickUp
        bne     .GetPickUpPositionY     ;looks for new Y position if too close

        * checks if pickup location is too close to player two
        move.l  PlayerTwoPositionX,d3
        move.l  PlayerTwoPositionY,d4
       
        bsr     CheckPickUp
        bne     .GetPickUpPositionY     ;looks for new Y position if too close

        move.b  #1,(a0)                 ;sets pickup exists flag to true
        move.l  d0,PickUpPositionX      ;updates pickup X position
        move.l  d1,PickUpPositionY      ;updates pickup Y position

        movem.l (sp)+,d1-d5

.Done
        movem.l  (sp)+,d0/a0
        rts


* ----------------------------------------------------------------------------
* Description:  Checks for pick up event and updates appropriately
* Parameters:   d0 = pickup X position
*               d1 = pickup Y position
*               d2 = pick up radius (in fixed point)
*               d3 = player X position
*               d4 = player Y position
* Return:       d7 = pickup status (1 = pickup, 0 = no pickup)
CheckPickUp:
        movem.l d0-d1,-(sp)

        move.l  #PICKUP_SIZE<<FIXED_POINT_PRECISION,d7
        add.l   d2,d7
        add.l   d0,d7           ;d7 = max X2
        cmp.l   d3,d7           ;if max X1 < min X2
        blt     .NoPickUp       ;then no collision

        move.l  #PLAYER_SIZE<<FIXED_POINT_PRECISION,d7
        add.l   d3,d7           ;d7 = max X1
        sub.l   d2,d0
        cmp.l   d0,d7           ;if max X2 < min X1
        blt     .NoPickUp       ;then no collision

        move.l  #PICKUP_SIZE<<FIXED_POINT_PRECISION,d7
        add.l   d2,d7
        add.l   d1,d7           ;d7 = max Y1
        cmp.l   d4,d7           ;if max Y1 < min Y2
        blt     .NoPickUp       ;then no collision

        move.l  #PLAYER_SIZE<<FIXED_POINT_PRECISION,d7
        add.l   d4,d7           ;d7 = max Y2
        sub.l   d2,d1
        cmp.l   d1,d7           ;if max Y2 < min Y1
        blt     .NoPickUp       ;then no collision

.PickUp:
        movem.l (sp)+,d0-d1
        moveq   #1,d7
        rts

.NoPickUp:
        movem.l (sp)+,d0-d1
        moveq   #0,d7
        rts


*~Font name~Courier New~




*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~8~
