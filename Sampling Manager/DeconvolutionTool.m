//
//  DeconvolutionTool.m
//  Sampling Manager
//
//  Created by Демидов Александр on 10.11.12.
//  Copyright (c) 2012 Александр Демидов. All rights reserved.
//

#import "DeconvolutionTool.h"
#import "fftw3.h"

#define DIMENSIONS_NUM 3
#define Length_Factor 1.0

typedef enum {
	RED, GREEN, BLUE
} CurrentChannel;


@interface DeconvolutionTool ()

- (void)findDiraction;
- (void)buildKernelImage;
- (CGFloat *)doDeconvoluateForChannel:(CurrentChannel)channel;
- (void)prepareForFFT;
- (void)getPixelInfoOfSourceImage;

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
        _pixelInfoOfKernelImage = NULL;
        _redChannel = _greenChannel = _blueChannel = NULL;
        width = _originalImage.size.width;
        height = _originalImage.size.height;
        
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
    
    //2)get kernel image pixel information of motion curve and source image
    [self buildKernelImage];
    [self getPixelInfoOfSourceImage];
    
    //3)now we should do deconvolition process for red, green and blue channels
    //of original image. this method returns pointer to array with result.
    //spicing of these array will be the net step.
    [self prepareForFFT];
	CGFloat *resultOfRedChannel = [self doDeconvoluateForChannel:RED];
	CGFloat *resultOfGreenChannel = [self doDeconvoluateForChannel:GREEN];
	CGFloat *resultOfBlueChannel = [self doDeconvoluateForChannel:BLUE];
    
	//temporary plug for result image
	_resultImage = nil;
    
    free(resultOfRedChannel);
    free(resultOfGreenChannel);
    free(resultOfBlueChannel);
    
    if ([self.delegate respondsToSelector:@selector(deconvolitonTool:hasFinished:)]) {
        [self.delegate deconvolitonTool:self hasFinished:self.resultImage];
    }
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
        
        _vector.x += (x - tempX);
        _vector.y += (y - tempY);
    }
}

- (void)buildKernelImage
{
    CGFloat motionLength = Length_Factor*sqrtf(powf(_vector.x, 2) + powf(_vector.y, 2));
    CGFloat motionAngle;
    if (_vector.x > 0.0f && _vector.y > 0.0f) motionAngle = atanf(_vector.y/_vector.x);
    else if (_vector.x < 0.0f && _vector.y > 0.0f) motionAngle = M_PI - atanf(_vector.y/_vector.x);
    else if (_vector.x < 0.0f && _vector.y < 0.0f) motionAngle = M_PI + atanf(_vector.y/_vector.x);
    else if (_vector.x > 0.0f && _vector.y < 0.0f) motionAngle = 2 * M_PI - atanf(_vector.y/_vector.x);
    else motionAngle = 0.0f;
    
    double centerX = 0.5 + width / 2;
    double centerY = 0.5 + height / 2;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    unsigned char *rawData = (unsigned char *)calloc(height * width, sizeof(unsigned char));
    
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, 8, width, colorSpace, kCGImageAlphaNone);
    CGContextSetFillColor(context, CGColorGetComponents([[UIColor blackColor] CGColor]));
    CGContextSetStrokeColor(context, CGColorGetComponents([[UIColor whiteColor] CGColor]));
    CGContextSetLineWidth(context, 1.01);
    
    CGContextFillRect(context, CGRectMake(0.0, 0.0, width, height));
    
    CGContextMoveToPoint(context, centerX - motionLength*cos(motionAngle)/2, centerY - motionLength*sin(motionAngle)/2);
    CGContextAddLineToPoint(context, centerX + motionLength*cos(motionAngle)/2, centerY + motionLength*sin(motionAngle)/2);
    
    CGContextStrokePath(context);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    _pixelInfoOfKernelImage = (CGFloat *)malloc(width * height * sizeof(CGFloat));
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int xTranslated = (x + width/2) % width;
            int yTranslated = (y + height/2) % height;
            _pixelInfoOfKernelImage[y*width + x] = rawData[yTranslated*width + xTranslated] / 255.0;
        }
    }
    
    free(rawData);
    rawData = NULL;
}

- (CGFloat *)doDeconvoluateForChannel:(CurrentChannel)channel
{
    CGFloat *resultArray = NULL;
    CGFloat **pointerToWorkingChannel = NULL;
	switch (channel) {
		case RED:
            pointerToWorkingChannel = &_redChannel;
			break;
		case GREEN:
            pointerToWorkingChannel = &_greenChannel;
			break;
		case BLUE:
            pointerToWorkingChannel = &_blueChannel;
			break;
		default:
			NSLog(@"Hmm.. Something is wrong, this channel does not exist.");
			break;
	}
    CGFloat *workingChannel = *pointerToWorkingChannel;
    
    CGFloat *tempMemory = (CGFloat *)malloc(width * height * sizeof(CGFloat));
    
    fftw_complex *complex = (fftw_complex *)fftw_malloc(5);
    fftw_free(complex);
    
    free(tempMemory);
    free(*pointerToWorkingChannel);
    *pointerToWorkingChannel = NULL;
    return resultArray;
}

- (void)prepareForFFT
{
    //i should think about preparations of fft
    //and in the method above it is necessary to process these ffts
}

- (void)getPixelInfoOfSourceImage
{
    CGImageRef imageRef = [self.originalImage CGImage];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char *)calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    int N = width*height;
    _redChannel = (CGFloat *)malloc(width * height * sizeof(CGFloat));
    _greenChannel = (CGFloat *)malloc(width * height * sizeof(CGFloat));
    _blueChannel = (CGFloat *)malloc(width * height * sizeof(CGFloat));
    
    int j = 0;
    for (int i = 0; i < N; i++) {
        _redChannel[i] = (rawData[j] * 1.0) / 255.0;
        _greenChannel[i] = (rawData[j+1] * 1.0) / 255.0;
        _blueChannel[i] = (rawData[j+2] * 1.0) / 255.0;
        j += 4;
    }
    
    free(rawData);
}

#pragma mark - Lifecycle methods

- (void)dealloc
{
    free(_points);
    _points = NULL;
    
    free(_redChannel);
    free(_greenChannel);
    free(_blueChannel);
    _redChannel = _greenChannel = _blueChannel = NULL;
    
    free(_pixelInfoOfKernelImage);
    _pixelInfoOfKernelImage = NULL;
    
    _originalImage = nil;
    _resultImage = nil;
    _delegate = nil;
}

@end
