*------------------------------------------------------------------------------------------
* Program    :  Bounce Off Config File
* Written by :  Logan Harvell
* Date       :  9/22/2019
* Description:  Constant and variable declarations for the BounceOff game program.
*------------------------------------------------------------------------------------------


*------------------------------------------------------------------------------------------
* Trap Codes

GET_ANY_KEY_TRAP_CODE       EQU 5
GET_TIME_TRAP_CODE          EQU 8
CLEAR_SCREEN_TRAP_CODE      EQU 11
GET_INPUT_TRAP_CODE         EQU 19
SET_PEN_COLOR_TRAP_CODE     EQU 80
SET_FILL_COLOR_TRAP_CODE    EQU 81
DRAW_CIRCLE_TRAP_CODE       EQU 88
DRAWING_MODE_TRAP_CODE      EQU 92
SET_PEN_WIDTH_TRAP_CODE     EQU 93
DISPLAY_BUFFER_TRAP_CODE    EQU 94
DRAW_STRING_TRAP_CODE       EQU 95

* Drawing Mode Codes
DOUBLE_BUFFER_DRAWING_MODE  EQU 17

* Clear Screen Code
CLEAR_SCREEN_KEY_CODE      EQU  $FF00

ALL_REG REG d0-d7/a0-a6

*------------------------------------------------------------------------------------------
* Game Constants

MAX_SCORE               EQU 9
FIXED_POINT_PRECISION   EQU 12
INVAL_PADDING           EQU 4

COLOR_BLUE      EQU $00FF0000
COLOR_GREEN     EQU $0000FF00
COLOR_RED       EQU $000000FF
COLOR_YELLOW    EQU COLOR_GREEN+COLOR_RED
COLOR_BLACK     EQU $00000000
COLOR_GRAY      EQU $00808080
COLOR_WHITE     EQU COLOR_BLUE+COLOR_GREEN+COLOR_RED

COLOR_PLAYER_ONE    EQU COLOR_GREEN
COLOR_PLAYER_TWO    EQU COLOR_YELLOW
COLOR_PICKUP        EQU COLOR_WHITE

LOADING_STRING_POSITION_X   EQU     285
LOADING_STRING_POSITION_Y   EQU     235
LOADING_STRING              dc.b    'Loading...',0,0

SEGMENT_DISPLAY_WIDTH   EQU 10
SEGMENT_LINE_WIDTH      EQU 2
PLAYER_ONE_SCORE_DRAW_X EQU 78
PLAYER_TWO_SCORE_DRAW_X EQU 548
SCORE_DRAW_Y            EQU 18

GAME_SCREEN_BORDER_WIDTH    EQU 10
GAME_SCREEN_WIDTH           EQU 640
GAME_SCREEN_HEIGHT          EQU 480

LEFT_WALL   EQU GAME_SCREEN_BORDER_WIDTH
RIGHT_WALL  EQU GAME_SCREEN_WIDTH-11
TOP_WALL    EQU GAME_SCREEN_BORDER_WIDTH+41
BOTTOM_WALL EQU GAME_SCREEN_HEIGHT-GAME_SCREEN_BORDER_WIDTH

PLAYER_SIZE                 EQU 16
PLAYER_ONE_START_X          EQU (GAME_SCREEN_BORDER_WIDTH+10)<<FIXED_POINT_PRECISION
PLAYER_ONE_START_Y          EQU ((GAME_SCREEN_HEIGHT>>1)-(PLAYER_SIZE>>1))<<FIXED_POINT_PRECISION
PLAYER_TWO_START_X          EQU (GAME_SCREEN_WIDTH-GAME_SCREEN_BORDER_WIDTH-PLAYER_SIZE-10)<<FIXED_POINT_PRECISION
PLAYER_TWO_START_Y          EQU ((GAME_SCREEN_HEIGHT>>1)-(PLAYER_SIZE>>1))<<FIXED_POINT_PRECISION

PICKUP_SIZE             EQU 8
PICKUP_RADIUS           EQU 4
PICKUP_WALL_OFFSET      EQU 8
PICKUP_MIN_X            EQU PICKUP_WALL_OFFSET+GAME_SCREEN_BORDER_WIDTH
PICKUP_MAX_X            EQU RIGHT_WALL-PICKUP_WALL_OFFSET-PICKUP_SIZE-PICKUP_MIN_X
PICKUP_MIN_Y            EQU TOP_WALL+PICKUP_WALL_OFFSET
PICKUP_MAX_Y            EQU BOTTOM_WALL-PICKUP_WALL_OFFSET-PICKUP_SIZE-PICKUP_MIN_Y
PICKUP_MAX_X_SEED_MASK  EQU $1FFFFFF
PICKUP_MAX_Y_SEED_MASK  EQU $FFFFFF

PLAYER_ACCELERATION         EQU $100
MAX_VELOCITY                EQU $3000

INPUT_DELAY         EQU 1
PLAYER_ONE_INPUTS   EQU 'W'<<24+'A'<<16+'S'<<8+'D'  ;wasd keys  (up,left,down,right)
PLAYER_TWO_INPUTS   EQU $26252827                   ;arrow keys (up,left,down,right)
END_SCREEN_INPUTS   EQU ' '<<24+'R'<<16+'M'<<8+'Q'

*------------------------------------------------------------------------------------------
* Game Variables

GameIsRunning       dc.b    1
PickUpExists        dc.b    0
PickUpIsDrawn       dc.b    0,0
IncreaseP1Score     dc.b    1
IncreaseP2Score     dc.b    1

FrameTime           dc.l    0

PlayerOneScore      dc.b    0
PlayerTwoScore      dc.b    0

PlayerOneVelocityX  dc.l    0
PlayerOneVelocityY  dc.l    0
PlayerTwoVelocityX  dc.l    0
PlayerTwoVelocityY  dc.l    0

PlayerOnePositionX  dc.l    PLAYER_ONE_START_X
PlayerOnePositionY  dc.l    PLAYER_ONE_START_Y
PlayerTwoPositionX  dc.l    PLAYER_TWO_START_X
PlayerTwoPositionY  dc.l    PLAYER_TWO_START_Y

PickUpPositionX     dc.l    0
PickupPositionY     dc.l    0

*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
