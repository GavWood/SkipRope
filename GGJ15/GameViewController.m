//
//  GameViewController.m
//  GGJ15
//
//  Created by Gavin Wood / John Shearer on 24/01/2015.

#import "GameViewController.h"

@implementation GameViewController

SCNScene *scene;
SCNNode *ropeNode = NULL;

-(void)awakeFromNib
{
    // create a new scene
    scene = [SCNScene scene];
    
    // create and add a camera to the scene
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    [scene.rootNode addChildNode:cameraNode];
    
    // place the camera
    cameraNode.position = SCNVector3Make(0, 0, 25);
    
    // set the scene to the view
    self.gameView.scene = scene;
    
    // allows the user to manipulate the camera
    self.gameView.allowsCameraControl = YES;
    
    self.gameView.autoenablesDefaultLighting = true;
    
    // show statistics such as fps and timing information
    self.gameView.showsStatistics = YES;
    
    // configure the view
    float red = 0.5f;
    float green = 0.2f;
    float blue = 0.4f;
    float alpha = 0.8f;
    
    NSColor *rgb = [NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha];
    self.gameView.backgroundColor = rgb;
   
    // set the delegate
    self.gameView.delegate = self.gameView;
    
    // Init the game view
    [self.gameView initGame];
    
    // http://stackoverflow.com/questions/21886224/drawing-a-line-between-two-points-using-scenekit
    // http://ronnqvi.st/custom-scenekit-geometry/
  
    [self addCube];
    
    // problems:
    // updating these lines at runtime
    // how do i call game logic?
    // how to crash into the player
}

-(void)addCube
{
    float halfSide = 10.0f;
    SCNVector3 positions[] = {
        //                  x       y           z
        SCNVector3Make(-halfSide, -halfSide, -halfSide),
        SCNVector3Make(-halfSide, -halfSide,  halfSide),
        SCNVector3Make(-halfSide,  halfSide, -halfSide),
        SCNVector3Make(-halfSide,  halfSide,  halfSide),
        SCNVector3Make( halfSide, -halfSide, -halfSide),
        SCNVector3Make( halfSide, -halfSide,  halfSide),
        SCNVector3Make( halfSide,  halfSide, -halfSide),
        SCNVector3Make( halfSide,  halfSide,  halfSide)
    };
    int indices[] = {
        0, 1,
        1, 5,
        4, 5,
        0, 4,
        
        2, 3,
        3, 7,
        6, 7,
        2, 6,
        
        0, 2,   // Sides
        1, 3,
        5, 7,
        4, 6,
    };
    SCNGeometrySource *vertexSource =
    [SCNGeometrySource geometrySourceWithVertices:positions count:8];

    NSData *indexData = [NSData dataWithBytes:indices
                                       length:sizeof(indices)];

    //
    SCNGeometryElement *element =
    [SCNGeometryElement geometryElementWithData:indexData
                                  primitiveType:SCNGeometryPrimitiveTypeLine
                                 primitiveCount:12
                                  bytesPerIndex:sizeof(int)];

    SCNGeometry *line = [SCNGeometry geometryWithSources:@[vertexSource] elements:@[element]];

    SCNNode *lineNode = [SCNNode nodeWithGeometry:line];
    [scene.rootNode addChildNode:lineNode];
}

@end
