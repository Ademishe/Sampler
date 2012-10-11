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

#define DEFAULT_LOOK_AT_RADIUS 5.0
#define DEFAULT_LOOK_AT_TETTA M_PI/4.0
#define DEFAULT_LOOK_AT_FI M_PI/4.0
#define factor 0.01
#define DOUBLE_M_PI 6.28318531

GLfloat axesCoords[] = {0.0, 0.0, 10.0,
						0.0, 0.0, -10.0,
						0.0, 10.0, 0.0,
						0.0, -10.0, 0.0,
						10.0, 0.0, 0.0,
						-10.0, 0.0, 0.0};

void gluLookAt(GLfloat eyex, GLfloat eyey, GLfloat eyez,
			   GLfloat centerx, GLfloat centery, GLfloat centerz,
			   GLfloat upx, GLfloat upy, GLfloat upz) {
    GLfloat m[16];
    GLfloat x[3], y[3], z[3];
    GLfloat mag;
    
    /* Make rotation matrix */
    
    /* Z vector */
    z[0] = eyex - centerx;
    z[1] = eyey - centery;
    z[2] = eyez - centerz;
    mag = sqrt(z[0] * z[0] + z[1] * z[1] + z[2] * z[2]);
    if (mag) {
        z[0] /= mag;
        z[1] /= mag;
        z[2] /= mag;
    }
    
    /* Y vector */
    y[0] = upx;
    y[1] = upy;
    y[2] = upz;
    
    /* X vector = Y cross Z */
    x[0] = y[1] * z[2] - y[2] * z[1];
    x[1] = -y[0] * z[2] + y[2] * z[0];
    x[2] = y[0] * z[1] - y[1] * z[0];
    
    /* Recompute Y = Z cross X */
    y[0] = z[1] * x[2] - z[2] * x[1];
    y[1] = -z[0] * x[2] + z[2] * x[0];
    y[2] = z[0] * x[1] - z[1] * x[0];
    
    /* mpichler, 19950515 */
    /* cross product gives area of parallelogram, which is < 1.0 for
     * non-perpendicular unit-length vectors; so normalize x, y here
     */
    
    mag = sqrt(x[0] * x[0] + x[1] * x[1] + x[2] * x[2]);
    if (mag) {
        x[0] /= mag;
        x[1] /= mag;
        x[2] /= mag;
    }
    
    mag = sqrt(y[0] * y[0] + y[1] * y[1] + y[2] * y[2]);
    if (mag) {
        y[0] /= mag;
        y[1] /= mag;
        y[2] /= mag;
    }
    
#define M(row,col)  m[col*4+row]
    M(0, 0) = x[0];
    M(0, 1) = x[1];
    M(0, 2) = x[2];
    M(0, 3) = 0.0;
    M(1, 0) = y[0];
    M(1, 1) = y[1];
    M(1, 2) = y[2];
    M(1, 3) = 0.0;
    M(2, 0) = z[0];
    M(2, 1) = z[1];
    M(2, 2) = z[2];
    M(2, 3) = 0.0;
    M(3, 0) = 0.0;
    M(3, 1) = 0.0;
    M(3, 2) = 0.0;
    M(3, 3) = 1.0;
#undef M
    glMultMatrixf(m);
    
    /* Translate Eye to Origin */
    glTranslatef(-eyex, -eyey, -eyez);
    
}

void gluPerspective(double fovy, double aspect, double zNear, double zFar) {
	double xmin, xmax, ymin, ymax;
	ymax = zNear * tan(fovy * M_PI / 360.0);
	ymin = -ymax;
	xmin = ymin * aspect;
	xmax = ymax * aspect;
	glFrustumf(xmin, xmax, ymin, ymax, zNear, zFar);
}

@interface OpenGLView ()

- (void)prepare;
- (void)drawAxis;

@end

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

- (void)prepare
{
	[EAGLContext setCurrentContext:context];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
	
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	gluPerspective(90.0, 1.0, 0.1, 30.0);
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glShadeModel(GL_SMOOTH);
}

- (void)render
{
    if (_arrayCount == 0) return;
    [self prepare];
    glClear(GL_COLOR_BUFFER_BIT);
	gluLookAt(R*sin(tetta)*cos(fi),
			  R*sin(tetta)*sin(fi),
			  R*cos(tetta), 0.0, 0.0, 0.0, 0.0, 0.0, 1.0);
	
    glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
    glEnableClientState(GL_VERTEX_ARRAY);
    [self drawAxis];
	
    glVertexPointer(3, GL_FLOAT, 0, _points);
    glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
    glDrawArrays(GL_LINE_STRIP, 0, _arrayCount);
    
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (void)drawAxis
{
	//нарисовать стрелочки на осях!
    glColor4f(1.0, 1.0, 1.0, 1.0);
    glVertexPointer(3, GL_FLOAT, 0, axesCoords);
    glDrawArrays(GL_LINES, 0, 6);
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
	if (_arrayCount == 0) return;
	if ((gesture.state == UIGestureRecognizerStateChanged) ||
		gesture.state == UIGestureRecognizerStateEnded) {
		CGPoint translation = [gesture translationInView:self];
		GLfloat newTetta = tetta - factor*translation.y;
		GLfloat newFi = fi - factor*translation.x;
        
        if (newTetta > M_PI) newTetta = M_PI;
        else if (newTetta < 0.0f) newTetta = 0.0f;
        
        if (newFi > DOUBLE_M_PI) newFi -= DOUBLE_M_PI;
        else if (newFi < 0.0f) newFi += DOUBLE_M_PI;
        
        fi = newFi;
        tetta = newTetta;
		
		[gesture setTranslation:CGPointZero inView:self];
		[self render];
	}
}

- (void)handelPinchGesture:(UIPinchGestureRecognizer *)gesture
{
	if (_arrayCount == 0) return;
	if ((gesture.state == UIGestureRecognizerStateChanged) ||
		gesture.state == UIGestureRecognizerStateEnded) {
        R /= gesture.scale;
		gesture.scale = 1.0f;
		[self render];
	}
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

@end
