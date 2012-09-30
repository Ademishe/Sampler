//
//  PlotView.m
//  Sampling Manager
//
//  Created by Демидов Александр on 12.09.12.
//  Copyright (c) 2012 Александр Демидов. All rights reserved.
//

#import "PlotView.h"

#define POINT_SIZE 5.0
#define DEFAULT_SCALE 10.0

@implementation PlotView

@synthesize plotPoints = _plotPoints;
@synthesize scale = _scale;
@synthesize points = _points;
@synthesize arrayCount = _arrayCount;

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
	}
	return self;
}

- (CGFloat)scale
{
	if (!_scale) {
		return DEFAULT_SCALE;
	}
	else {
		return _scale;
	}
}

- (void)setScale:(CGFloat)scale
{
	if (scale != _scale) {
		_scale = scale;
		[self setNeedsDisplay];
	}
}

- (void)handelPanGesture:(UIPanGestureRecognizer *)gesture
{
	if ((gesture.state == UIGestureRecognizerStateChanged) ||
		gesture.state == UIGestureRecognizerStateEnded) {
		CGPoint translation = [gesture translationInView:self];
		[self setBounds:CGRectMake(self.bounds.origin.x - translation.x, self.bounds.origin.y - translation.y, self.bounds.size.width, self.bounds.size.height)];
		[gesture setTranslation:CGPointZero inView:self];
		[self setNeedsDisplay];
	}
}

- (void)pinch:(UIPinchGestureRecognizer *)gesture
{
	if ((gesture.state == UIGestureRecognizerStateChanged) ||
		(gesture.state == UIGestureRecognizerStateEnded)) {
		self.scale *= gesture.scale;
		gesture.scale = 1;
	}
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)drawRect:(CGRect)rect
{
	if (self.plotPoints == nil) return;
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetRGBStrokeColor(ctx, 0.0, 0.5, 1.0, 1.0);
	CGContextSetRGBFillColor(ctx, 0.0, 0.5, 1.0, 1.0);
	CGContextSetLineWidth(ctx, 2.0);
	
//	CGFloat zeroX = [[[self.plotPoints objectAtIndex:0] objectForKey:@"x"] floatValue]*self.scale;
//	CGFloat zeroY = [[[self.plotPoints objectAtIndex:0] objectForKey:@"y"] floatValue]*self.scale;
//	double zeroZ = [[[self.plotPoints objectAtIndex:0] objectForKey:@"z"] doubleValue];
	
	CGFloat zeroX = _points[0];
	CGFloat zeroY = _points[1];
//	CGFloat zeroZ = _points[2];
	
	CGContextFillEllipseInRect(ctx, CGRectMake(zeroX - POINT_SIZE / 2.0, zeroY - POINT_SIZE / 2.0, POINT_SIZE, POINT_SIZE));
	CGContextBeginPath(ctx);
	CGContextMoveToPoint(ctx, zeroX, zeroY);
	
	for (int i = 3; i < _arrayCount; i += 3) {
//		CGFloat X = [[[self.plotPoints objectAtIndex:i] objectForKey:@"x"] floatValue]*self.scale;
//		CGFloat Y = [[[self.plotPoints objectAtIndex:i] objectForKey:@"y"] floatValue]*self.scale;
		CGFloat X = _points[i];
		CGFloat Y = _points[i+1];
		
		CGContextAddLineToPoint(ctx, X, Y);
		CGContextStrokePath(ctx);
		CGContextFillEllipseInRect(ctx, CGRectMake(X - POINT_SIZE / 2.0, Y - POINT_SIZE / 2.0, POINT_SIZE, POINT_SIZE));
		CGContextBeginPath(ctx);
		CGContextMoveToPoint(ctx, X, Y);
	}
}

@end
