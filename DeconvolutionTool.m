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
        vector.angle = 0.0;
        vector.length = 0.0;
        
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
}

#pragma mark - Private methods

- (void)findDiraction
{
    CGFloat x = _points[0];
    CGFloat y = _points[1];
//    CGFloat z = _points[2];
    CGFloat tempX, tempY;
    for (int i = 3; i < _cnt; i+=DIMENSIONS_NUM) {
        x = _points[i];
        y = _points[i+1];
//        z = _points[i+2];
        
        tempX = x;
        tempY = y;
        x -= tempX;
        y -= tempY;
        vector.length = sqrt(pow(x, 2) + pow(y, 2));
        vector.angle = atan(y/x);
    }
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
