//
//  OpenGLView.h
//  Sampling Manager
//
//  Created by Александр Демидов on 16.09.12.
//  Copyright (c) 2012 Александр Демидов. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CAEAGLLayer;

@interface OpenGLView : UIView <UIGestureRecognizerDelegate> {
    EAGLContext *context;
    
    GLint backingWidth;
	GLint backingHeight;
    GLuint defaultFramebuffer, colorRenderbuffer;
	GLfloat R, tetta, fi;
}

@property (nonatomic, assign) GLfloat *points;
@property (nonatomic) GLuint arrayCount;

- (void)render;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;
- (void)handelPinchGesture:(UIPinchGestureRecognizer *)gesture;
- (void)handelPanGesture:(UIPanGestureRecognizer *)gesture;

@end
