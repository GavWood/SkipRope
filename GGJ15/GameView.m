//
//  GameView.m
//  GGJ15
//
//  Created by Gavin Wood / John Shearer on 24/01/2015.

#import "GameView.h"
#include "psmove.h"

@implementation GameView

// To maintain the scenegraph
extern SCNScene *scene;
extern SCNNode *ropeNode;
SCNNode *textNode = NULL;
SCNNode *sphereNode[2] = {0, 0 };

// Rope defines
/*
 // http://www.nortechskippingropes.co.uk/jump-ropes/size-guide.aspx
 7ft / 213 cm	up to 4’ 10” / up to 147 cm
 8ft / 244 cm	4’ 11”  to 5’ 4” / 149 cm to 163 cm
 9ft / 274 cm 	5’5” to 5’11” / 165 cm to 180 cm
 10ft / 305 cm	6’0” to 6’6” / 182cm to 198 cm
 11ft / 335cm	6’ 7” and above / 200cm
 15ft / 457 cm	Our ‘Double –Dutch length, enabling at least 2 skipper inside the rope.
 25ft / 762 cm	Ideal for team & class games, fitting many skippers inside the rope.
 */
SCNVector3 v3P[1024];
SCNVector3 v3O[1024];
float counter =  0;
const float RestLength = 0.06f;
const float RopeLength = 7.62f;
const int NumSegments = 128;                    // This is the ropes length divided by the (taught - x1.5) rest length
const int LastSegment = 128-1;
const float dt = 1.0f / 60.0f;                  // Assume we are at 60fps
const float dtSq = dt * dt;
int indices[256];
float ropeHeight;
float ropeAverage;
float isBottom;

// Controller defines
PSMove *moveControllers[32];
int numControllerConnected;
float fx, fy, fz;
float mag;
SCNVector3 controllerPosition[2];
SCNVector3 start;
SCNVector3 end;
bool isHeld[2] = { false, false };
bool isArmed = false;

// Player defines
const float PlayerHeight = 1.6f;
const float HalfPlayerHeight = PlayerHeight / 2;
const float GameTime = 20;
float health[2] = {0, 0 };
float PlayerHeightOffGround[2] = {0, 0 };

// Reset the game
float gameClock = 0;
bool isCounting = false;

-(void)initGame
{
    // Init the controllers
    [self initControllers];
    
    // Init the rope
    [self initRope];
    
    // Reset our game
    [self reset];
}

-(void)initControllers
{
    numControllerConnected = psmove_count_connected();

    // Get the number of controllers
    printf("Num connected controllers: %d\n", numControllerConnected );

    // Connect to each one
    for( int i=0; i<numControllerConnected; i++ )
    {
        moveControllers[i] = psmove_connect_by_id(i);
        assert( moveControllers[i] );
    }
}

-(void)initRope
{
    // Create the index array
    int index = 0;
    for( int i=0; i<NumSegments-1; i++ )
    {
        indices[index++] = i;
        indices[index++] = i+1;
    }
}

-(void)reset
{
    gameClock = 0;
    [self resetRope];
    [self resetPlayer];
}

-(void)updatePlayers
{
    int halfNumSegments = NumSegments /2;
    int numToConsider = NumSegments / 5;
    int start = halfNumSegments - numToConsider;
    int end   = halfNumSegments + numToConsider;
    float maxY = v3P[0].y;
    float minY = maxY;
    
    // Get the bounding box
    for( int i=0; i<NumSegments; i++ )
    {
        float y = v3P[i].y;
        if( y > maxY )
        {
            maxY = y;
        }
        if( y < minY )
        {
            minY = y;
        }
    }
    float range = maxY - minY;
    (void)range;
    
    // Calculate the average
    float average = 0;
    for( int i=start; i<end; i++ )
    {
        float y = v3P[i].y;
        average += y;
    }
    ropeHeight  = average / (end-start);
    ropeAverage = ( v3P[0].y + v3P[NumSegments-1].y ) / 2;
    
    if( ropeHeight < ropeAverage )
    {
        float delta = ropeAverage - ropeHeight;
       
        if( delta < ( range * 0.5f ) )
        {
            isBottom = 1.0;
        }
    }
    else
    {
        isBottom = 0;
    }
    
    // Now catch the players out
    if( gameClock < GameTime )
    {
        // first check the ropes are armed
        if( isArmed )
        {
            // Are we at the bottom
            if( isBottom )
            {
                for( int i=0; i<2; i++ )
                {
                    if( PlayerHeightOffGround[i] > 0 )
                    {
                        // safe
                    }
                    else
                    {
                        health[i] += 1.0f;
                        
                        //if( health[i] <  )
                        // {
                        //    health[i] = 0;
                       // }
                    }
                }
            }
        }
    }
    
    if( isCounting )
    {
        gameClock += 1.0f / 60.0f;
        
        if( gameClock > GameTime )
        {
            gameClock = GameTime;
        }
    }
}

-(void)resetRope
{
    // Init verlet simulation positions
    float z = 0;
    int index = 0;
    for( float x=0; x<RopeLength; x+= RestLength )
    {
        float usex = x - (RopeLength / 2);
        usex *= 2.0f;
        v3P[index] = SCNVector3Make( usex, 0, z );
        v3O[index] = v3P[index];
        ++index;
    }
    start = v3P[0];
    end   = v3O[LastSegment];
    assert( index == NumSegments );
    
    // Setup default controller positions
    controllerPosition[0] = SCNVector3Make( 0, 0, 0 );
    controllerPosition[1] = SCNVector3Make( 0, 0, 0 );
}

- (void)resetPlayer
{
    health[0] = 0.0f;
    health[1] = 0.0f;
    isCounting = false;
}

- (void)keyDown:(NSEvent *)event
{
    NSString *characters = [event characters];
    for (int s = 0; s<[characters length]; s++)
    {
        unichar character = [characters characterAtIndex:s];
        if( character == 'r' )
        {
            [self reset];
        }
        if( character == 'j' )
        {
            controllerPosition[0].z -= 0.3f;
            controllerPosition[1].z += 0.3f;
            
            v3P[0] = controllerPosition[0];
            v3P[0].x += start.x;
            v3P[0].y += start.y;
            v3P[0].z += start.z;
            
            v3P[LastSegment] = controllerPosition[1];
            v3P[LastSegment].x += end.x;
            v3P[LastSegment].y += end.y;
            v3P[LastSegment].z += end.z;
        }
        if( character == 'k' )
        {
            controllerPosition[0].z += 0.3f;
            controllerPosition[1].z -= 0.3f;
            
            v3P[0] = controllerPosition[0];
            v3P[0].x += start.x;
            v3P[0].y += start.y;
            v3P[0].z += start.z;
            
            v3P[LastSegment] = controllerPosition[1];
            v3P[LastSegment].x += end.x;
            v3P[LastSegment].y += end.y;
            v3P[LastSegment].z += end.z;
        }
    }
}

- (void)keyUp:(NSEvent *)event {
    int a=0;
    a++;
}

-(void)renderer:(id<SCNSceneRenderer>)aRenderer willRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time
{
    static int count = 0;
    ++count;
    
    // Flash the first two controllers
    static int flicker = 0;
    --flicker;
    if( flicker<-10)
    {
        flicker=10;
    }
    for( int i=0; i<2; i++ )
    {
        PSMove *move = moveControllers[i];
        
        int res = psmove_poll( move);
        if (res)
        {
            // Get the accelerometer
            int ax, ay, az;
            psmove_get_accelerometer( move, &ax, &ay, &az );
            fx = ((float)ax) / 32768.0f;
            fy = ((float)ay) / 32768.0f;
            fz = ((float)az) / 32768.0f;
            fx *= 250.0f;
            fy *= 250.0f;
            fz *= 250.0f;
            fz -= 30.0f;
     
            // Integrate
            controllerPosition[i].z += fx * dt;
            controllerPosition[i].y += fz * dt;
            
            // Kill the drift
            controllerPosition[i].x *= 0.9f;
            controllerPosition[i].y *= 0.9f;
            controllerPosition[i].z *= 0.9f;
            
            // Check the battery level
            unsigned int pressed, released;
            psmove_get_button_events( move, &pressed, &released);
            
            // Arm the rope
            if( pressed == Btn_MOVE )
            {
                isHeld[i] = true;
            }
            if( released == Btn_MOVE )
            {
                isHeld[i] = false;
            }
            
            // Colour the first two move controllers blue
            // Set the lights to 0
            if( flicker > 0 )
            {
                if( isHeld[0] || isHeld[1] )
                {
                    psmove_set_leds( move, 255, 0, 0 );
                    isArmed = true;
                    isCounting = true;
                }
                else
                {
                    isArmed = false;
                    psmove_set_leds( move, 0, 255, 255 );
                }
            }
            else
            {
                psmove_set_leds( move, 0, 0, 0 );
            }
            
            // Always update our leds
            psmove_update_leds( move );
            
            int a=0;
            a++;
        }
    }
    
    // For one player controlling both ends
    //controllerPosition[0].x = 0; controllerPosition[0].y = 0; controllerPosition[0].z = 0;
    //controllerPosition[1] = controllerPosition[0];
    
    v3P[0].x = start.x + controllerPosition[0].x;
    v3P[0].y = start.y + controllerPosition[0].y;
    v3P[0].z = start.z + controllerPosition[0].z;
    
    v3P[LastSegment].x = end.x + controllerPosition[1].x;
    v3P[LastSegment].y = end.y + controllerPosition[1].y;
    v3P[LastSegment].z = end.z - controllerPosition[1].z;
    
    // Essentially an impulse at the ends of the rope rather than an acceleration
    v3O[0] = v3P[0];
    v3O[LastSegment] = v3P[LastSegment];
    
    // Set the remaining controllers to yellow
    int playerIndex = 0;
    for( int i=2; i<numControllerConnected; i++ )
    {
        PSMove *move = moveControllers[i];
        
        int res = psmove_poll( move);
        if (res)
        {
            // Get the accelerometer
            int ax, ay, az;
            psmove_get_accelerometer( move, &ax, &ay, &az );
            fx = ((float)ax) / 32768.0f;
            fy = ((float)ay) / 32768.0f;
            fz = ((float)az) / 32768.0f;
            fx *= 250.0f;
            fy *= 250.0f;
            fz *= 250.0f;
            
            mag = sqrt( (fx * fx ) + ( fy * fy ) + ( fz * fz ) );
            
            // Jumping player goes in here - seems to be a magnitude of about
            //if( fy > 10 )
            if( mag > 40 )
            {
                // Jump
                PlayerHeightOffGround[playerIndex] = HalfPlayerHeight;
            }
            
            // Decay any jumping
            PlayerHeightOffGround[playerIndex] -= 0.02f;
            if( PlayerHeightOffGround[playerIndex] < 0 )
            {
                PlayerHeightOffGround[playerIndex] = 0;
            }
           
            // Always update our leds
            psmove_update_leds( move );
            
            ++playerIndex;
        }
    }
    
    // Set the winner
    {
        PSMove *move1 = moveControllers[2];
        PSMove *move2 = moveControllers[3];
        
        if( gameClock >= GameTime )
        {
            if( health[0] < health[1] )
            {
                psmove_set_leds( move1, 0, 255, 0 );
                psmove_set_leds( move2, 255, 0, 0 );
            }
            else
            {
                psmove_set_leds( move1, 255, 0, 0 );
                psmove_set_leds( move2, 0, 255, 0 );
            }
        }
        else
        {
            psmove_set_leds( move1, 255, 255, 255 );
            psmove_set_leds( move2, 255, 255, 255 );
        }
        
        psmove_update_leds( move1 );
        psmove_update_leds( move2 );
    }
    
    // Update the ropes vertex
    // Integrate but don't move the first or the last point - we'll move this by hand which is an impulse
    for( int i = 1; i < LastSegment; i++)
    {
        // Derive the velocity
        SCNVector3 v3Velocity;
        v3Velocity.x = v3P[i].x - v3O[i].x;
        v3Velocity.y = v3P[i].y - v3O[i].y;
        v3Velocity.z = v3P[i].z - v3O[i].z;
        
        float dampen = 0.98f;
        //float dampen = 0.9f;
        
        v3Velocity.x *= dampen;
        v3Velocity.y *= dampen;
        v3Velocity.z *= dampen;
        
        // Add gravity
        SCNVector3 v3Acc;
        v3Acc.x =  0.0f;
        v3Acc.y = -9.8f * dtSq;
        v3Acc.z =  0;
        
        // Add the velocity
        SCNVector3 v3Next;
        v3Next.x = v3P[i].x + v3Velocity.x + v3Acc.x;
        v3Next.y = v3P[i].y + v3Velocity.y + v3Acc.y;
        v3Next.z = v3P[i].z + v3Velocity.z + v3Acc.z;
        
        // Copy the last position
        v3O[i] = v3P[i];
        v3P[i] = v3Next;
    }
    
    int relax = 1;
    if( relax )
    {
        int itterations = 9;
        for( int itt=0; itt<itterations; itt++ )
        {
            // Solve the rest lengths
            for( int i = 0; i < LastSegment; i++)
            {
                int j = i + 1;
                
                SCNVector3 v3Delta;
                v3Delta.x = v3P[i].x - v3P[j].x;
                v3Delta.y = v3P[i].y - v3P[j].y;
                v3Delta.z = v3P[i].z - v3P[j].z;
                
                float datalength = sqrtf((v3Delta.x * v3Delta.x) + (v3Delta.y * v3Delta.y) + (v3Delta.z * v3Delta.z));
                
                float diff = (datalength - RestLength ) / datalength;
                //diff = powf( diff, 0.1f );
                //diff = 1.0f;
                
                // Move toward solving the constraints
                if( i != 0 )
                {
                    v3P[i].x -= (v3Delta.x * 0.5f * diff );
                    v3P[i].y -= (v3Delta.y * 0.5f * diff );
                    v3P[i].z -= (v3Delta.z * 0.5f * diff );
                }
                
                if( j != LastSegment )
                {
                    v3P[j].x += (v3Delta.x * 0.5f * diff );
                    v3P[j].y += (v3Delta.y * 0.5f * diff );
                    v3P[j].z += (v3Delta.z * 0.5f * diff );
                }
            }
        }
    }
    
    // Update the scene graph
    NSData *indexData = [NSData dataWithBytes:indices length:sizeof(indices)];
    
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:indexData
                                                                primitiveType:SCNGeometryPrimitiveTypeLine
                                                                primitiveCount:NumSegments-1
                                                                bytesPerIndex:sizeof(int)];
    
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:v3P count:NumSegments];
    
    // Fill rope vertex
    SCNGeometry *rope = [SCNGeometry geometryWithSources:@[vertexSource] elements:@[element]];
    
    // Create a new node (or every other time a replacement)
    SCNNode *newNode = [SCNNode nodeWithGeometry:rope];
    
    // Create some text
    NSString *string = [NSString stringWithFormat:@"Time %.0f Score %.0f Score %.0f", gameClock, health[0], health[1] ];
    //NSString *string = [NSString stringWithFormat:@"%.4f %.4f %.4f", ropeAverage, ropeHeight, isBottom ];
    //NSString *string = [NSString stringWithFormat:@"%.4f", mag ];
    SCNText *text = [SCNText textWithString:string extrusionDepth:0];
    SCNNode *newTextNode = [SCNNode nodeWithGeometry:text];
    newTextNode.position = SCNVector3Make(-5, 5, 0);
    newTextNode.transform = CATransform3DScale(newTextNode.transform, .04f, .04f, .04f);

    // Add spheres for the players
    SCNCylinder *sphereGeom = [SCNCylinder cylinderWithRadius:0.35 height:PlayerHeight];
    SCNNode *sphereNode1 = [SCNNode nodeWithGeometry:sphereGeom];
    sphereNode1.position = SCNVector3Make(-3.0, PlayerHeightOffGround[0] - HalfPlayerHeight, 0.0);
   
    sphereGeom = [SCNCylinder cylinderWithRadius:0.35 height:1.6];
    SCNNode *sphereNode2 = [SCNNode nodeWithGeometry:sphereGeom];
    sphereNode2.position = SCNVector3Make( 3.0, PlayerHeightOffGround[1] - HalfPlayerHeight, 0.0);
 
    // If it exists - replace it - i bet there is a better way to do this. Apple?
    // Essentially we want to dynamically upload to the vertex buffer. Can't be hard.
    if( ropeNode )
    {
        [scene.rootNode replaceChildNode:textNode with:newTextNode];
        [scene.rootNode replaceChildNode:ropeNode with:newNode];
        [scene.rootNode replaceChildNode:sphereNode[0] with:sphereNode1];
        [scene.rootNode replaceChildNode:sphereNode[1] with:sphereNode2];
    }
    else
    {
        [scene.rootNode addChildNode:newTextNode];
        [scene.rootNode addChildNode:newNode];
        [scene.rootNode addChildNode:sphereNode1];
        [scene.rootNode addChildNode:sphereNode2];
    }
    ropeNode = newNode;
    textNode = newTextNode;
    sphereNode[0] = sphereNode1;
    sphereNode[1] = sphereNode2;
    
    [self updatePlayers];
}

-(void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
}

@end
