//
//  OpenGLView.h
//  Sampling Manager
//
//  Created by Александр Демидов on 16.09.12.
//  Copyright (c) 2012 Александр Демидов. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CAEAGLLayer;

@interface OpenGLView : UIView {
    EAGLContext *context;
    
    GLint backingWidth;
	GLint backingHeight;
    GLuint defaultFramebuffer, colorRenderbuffer;
}

@property (strong, nonatomic) NSArray *plotPoints;

- (void)render;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;

@end
