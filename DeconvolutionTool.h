//
//  DeconvolutionTool.h
//  Sampling Manager
//
//  Created by Демидов Александр on 10.11.12.
//  Copyright (c) 2012 Александр Демидов. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct _DirectionVector {
    double angle;
    double length;
} DirectionVector;

@protocol DeconvolutionToolDelegate;

@interface DeconvolutionTool : NSObject {
	CGFloat *_points;
	int _cnt;
    DirectionVector vector;
}

@property (readonly, strong) UIImage *originalImage;
@property (readonly, strong) UIImage *resultImage;
@property id <DeconvolutionToolDelegate> delegate;

- (DeconvolutionTool *)initWithArray:(CGFloat *)points arrayCount:(int)cnt andImage:(UIImage *)image;
- (void)deconvoluateImage;

@end


@protocol DeconvolutionToolDelegate <NSObject>

- (void)deconvolitonTool:(DeconvolutionTool *)tool hasFinished:(UIImage *)resultImage;

@end
