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
- (CGFloat *)buildKernelImage;

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
        _vector.x = 0.0;
        _vector.y = 0.0;
        _kernelImage = NULL;
        
        _points = (CGFloat *)malloc(_cnt * sizeof(CGFloat));
        if (_points == NULL) {
            NSLog(@"Memory allocation error!");
            return nil;
        }
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
    
    //2)get kernel image pixel information of motion curve
    CGFloat *kernelImagePixelInfo = [self buildKernelImage];
    free(kernelImagePixelInfo);
    kernelImagePixelInfo = NULL;
    
	//temporary plug for result image
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
//		NSLog(@"x = %lf y = %lf", x, y);
        
        _vector.x += (x - tempX);
        _vector.y += (y - tempY);
    }
//	NSLog(@"angle = %lf length = %lf", atan(_vector.y/_vector.x), sqrt(pow(_vector.x, 2) + pow(_vector.y, 2)));
//	NSLog(@"result: x = %lf y = %lf", _vector.x, _vector.y);
}

- (CGFloat *)buildKernelImage
{
    CGFloat motionLength = sqrtf(powf(_vector.x, 2) + powf(_vector.y, 2));
    CGFloat motionAngle;
    if (_vector.x > 0.0f && _vector.y > 0.0f) motionAngle = atanf(_vector.y/_vector.x);
    else if (_vector.x < 0.0f && _vector.y > 0.0f) motionAngle = M_PI - atanf(_vector.y/_vector.x);
    else if (_vector.x < 0.0f && _vector.y < 0.0f) motionAngle = M_PI + atanf(_vector.y/_vector.x);
    else if (_vector.x > 0.0f && _vector.y < 0.0f) motionAngle = 2 * M_PI - atanf(_vector.y/_vector.x);
    else motionAngle = 0.0f;
    
    int size = (int)motionLength + 6;
    size += size%2;
    double center = 0.5 + size / 2;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    unsigned char *rawData = (unsigned char *)calloc(size * size, sizeof(unsigned char));
    CGContextRef context = CGBitmapContextCreate(rawData, size, size, 8, size, colorSpace, kCGImageAlphaNone);
    CGContextSetFillColor(context, CGColorGetComponents([[UIColor blackColor] CGColor]));
    CGContextSetStrokeColor(context, CGColorGetComponents([[UIColor whiteColor] CGColor]));
    CGContextSetLineWidth(context, 1.01);
    
    CGContextFillRect(context, CGRectMake(0.0, 0.0, size, size));
    
    CGContextMoveToPoint(context, center - motionLength*cos(motionAngle)/2, center - motionLength*sin(motionAngle)/2);
    CGContextAddLineToPoint(context, center + motionLength*cos(motionAngle)/2, center + motionLength*sin(motionAngle)/2);
    
    CGContextStrokePath(context);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    CGFloat *pixelInfo = (CGFloat *)malloc(size * size * sizeof(CGFloat));
    for (int i = 0; i < size * size; i++) {
        pixelInfo[i] = rawData[i] / 255.0;
    }
    
    free(rawData);
    rawData = NULL;
    return pixelInfo;
}

#pragma mark - Lifecycle methods

- (void)dealloc
{
    NSLog(@"tool deallocated!");
    free(_points);
    _points = NULL;
    
    _originalImage = nil;
    _resultImage = nil;
    _delegate = nil;
}

@end
