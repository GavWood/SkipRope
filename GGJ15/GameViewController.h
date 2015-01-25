//
//  GameViewController.h
//  GGJ15
//
//  Created by Gavin Wood / John Shearer on 24/01/2015.

#import <SceneKit/SceneKit.h>

#import "GameView.h"

@interface GameViewController : NSViewController< SCNSceneRendererDelegate>

@property (assign) IBOutlet GameView *gameView;

-(void)addCube;

@end
