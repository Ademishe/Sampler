//
//  OpenGLView.m
//  Sampling Manager
//
//  Created by Александр Демидов on 16.09.12.
//  Copyright (c) 2012 Александр Демидов. All rights reserved.
//

#import "OpenGLView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

#define DEFAULT_LOOK_AT_RADIUS 7.0
#define DEFAULT_LOOK_AT_TETTA M_PI/4.0
#define DEFAULT_LOOK_AT_FI M_PI/4.0

@implementation OpenGLView

@synthesize points = _points;
@synthesize arrayCount = _arrayCount;

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.arrayCount = 0;
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        if (!context || ![EAGLContext setCurrentContext:context])
            return nil;
        
        glGenFramebuffersOES(1, &defaultFramebuffer);
        glGenRenderbuffersOES(1, &colorRenderbuffer);
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);
		R = DEFAULT_LOOK_AT_RADIUS;
		fi = DEFAULT_LOOK_AT_FI;
		tetta = DEFAULT_LOOK_AT_TETTA;
    }
    
    return self;
}

- (void)render
{
    if (self.arrayCount == 0) return;
    
    [EAGLContext setCurrentContext:context];
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
//	gluLookAt(R*sin(tetta)*cos(fi),
//			  R*sin(tetta)*sin(fi),
//			  R*cos(tetta), 0.0, 0.0, 0.0, 0.0, 0.0, 1.0);
	
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
//    glOrthof(-1.0f, 1.0f, -1.5f, 1.5f, -1.0f, 1.0f);
//	gluPerspective(90.0, 1.33, 0.1, 30.0);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glVertexPointer(2, GL_FLOAT, 0, _points);
    glEnableClientState(GL_VERTEX_ARRAY);
    glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
    
    glDrawArrays(GL_LINE_STRIP, 0, 4);
    
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
	{
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    return YES;
}

- (void)dealloc
{
    if (defaultFramebuffer) {
		glDeleteFramebuffersOES(1, &defaultFramebuffer);
		defaultFramebuffer = 0;
	}
	
	if (colorRenderbuffer) {
		glDeleteRenderbuffersOES(1, &colorRenderbuffer);
		colorRenderbuffer = 0;
	}
    
	if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	
	context = nil;
}

- (void)handelPanGesture:(UIPanGestureRecognizer *)gesture
{
    
}

- (void)handelPinchGesture:(UIPinchGestureRecognizer *)gesture
{
    
}

@end
