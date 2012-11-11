//
//  DeconvolutionTool.m
//  Sampling Manager
//
//  Created by Демидов Александр on 10.11.12.
//  Copyright (c) 2012 Александр Демидов. All rights reserved.
//

#import "DeconvolutionTool.h"
#import <Accelerate/Accelerate.h>

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
    
}

#pragma mark - Private methods

- (void)findDiraction
{
    
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
