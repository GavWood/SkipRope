//
//  GameView.m
//  GGJ15
//
//  Created by Gavin Wood / John Shearer on 24/01/2015.

#import <SceneKit/SceneKit.h>

@interface GameView : SCNView< SCNSceneRendererDelegate>

-(void)initControllers;
-(void)initGame;
-(void)initRope;

-(void)resetRope;
-(void)resetPlayer;

@end
