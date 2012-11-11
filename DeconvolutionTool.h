//
//  DeconvolutionTool.h
//  Sampling Manager
//
//  Created by Демидов Александр on 10.11.12.
//  Copyright (c) 2012 Александр Демидов. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DeconvolutionToolDelegate;

@interface DeconvolutionTool : NSObject {
	CGFloat *_points;
	int _cnt;
	UIImage *originalImage;
}

@property (strong) UIImage *originalImage;
@property (strong) UIImage *resultImage;
@property id <DeconvolutionToolDelegate> delegate;

- (DeconvolutionTool *)initWithArray:(CGFloat *)points arrayCount:(int)cnt andImage:(UIImage *)image;
- (void)deconvoluateImage;

@end

@protocol DeconvolutionToolDelegate <NSObject>

- (void)deconvolitonToolHasFinished:(UIImage *)resultImage;

@end
