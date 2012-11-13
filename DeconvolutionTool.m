//
//  DeconvolutionTool.m
//  Sampling Manager
//
//  Created by Демидов Александр on 10.11.12.
//  Copyright (c) 2012 Александр Демидов. All rights reserved.
//

#import "DeconvolutionTool.h"
#import <Accelerate/Accelerate.h>

#define DIMENSIONS_NUM 3

@interface DeconvolutionTool ()

- (void)findDiraction;

@end

@implementation DeconvolutionTool

@synthesize originalImage = _originalImage;
@synthesize resultImage = _resultImage;
@synthesize delegate = _delegate;

#pragma mark - Public methods

- (DeconvolutionTool *)initWithArray:(CGFloat *)points arrayCount:(int)cnt andImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        _cnt = cnt;
        _originalImage = image;
        vector.x = 0.0;
        vector.y = 0.0;
        
        _points = (CGFloat *)malloc(_cnt * sizeof(CGFloat));
        for (int i = 0; i < _cnt; i++) {
            _points[i] = points[i];
        }
        
    }
	return self;
}

- (void)deconvoluateImage
{
	//1)determine direction of the motion
    //by finding deriative of the array with points
    [self findDiraction];
	//temporary plug
	_resultImage = nil;
	[self.delegate deconvolitonTool:self hasFinished:self.resultImage];
}

#pragma mark - Private methods

- (void)findDiraction
{
    CGFloat x = _points[0];
    CGFloat y = _points[1];
//    CGFloat z = _points[2];
	
    CGFloat tempX, tempY;
    for (int i = 3; i < _cnt; i+=DIMENSIONS_NUM) {
		tempX = x;
        tempY = y;
        x = _points[i];
        y = _points[i+1];
//        z = _points[i+2];
		NSLog(@"x = %lf y = %lf", x, y);
        
        vector.x += (x - tempX);
        vector.y += (y - tempY);
    }
//	NSLog(@"angle = %lf length = %lf", atan(vector.y/vector.x), sqrt(pow(vector.x, 2) + pow(vector.y, 2)));
	NSLog(@"result: x = %lf y = %lf", vector.x, vector.y);
}

#pragma mark - Lifecycle methods

- (void)dealloc
{
    free(_points);
    _points = NULL;
    
    _originalImage = nil;
    _resultImage = nil;
    _delegate = nil;
}

@end
