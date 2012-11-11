//
//  DeconvolutionTool.m
//  Sampling Manager
//
//  Created by Демидов Александр on 10.11.12.
//  Copyright (c) 2012 Александр Демидов. All rights reserved.
//

#import "DeconvolutionTool.h"

@implementation DeconvolutionTool

@synthesize originalImage;
@synthesize resultImage = _resultImage;
@synthesize delegate = _delegate;

- (DeconvolutionTool *)initWithArray:(CGFloat *)points arrayCount:(int)cnt andImage:(UIImage *)image
{
	return self;
}

- (void)deconvoluateImage
{
	
}

@end
