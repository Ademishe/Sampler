//
//  DeconvolutionTool.h
//  Sampling Manager
//
//  Created by Демидов Александр on 10.11.12.
//  Copyright (c) 2012 Александр Демидов. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeconvolutionTool : NSObject

- (DeconvolutionTool *)initWithArray:(CGFloat *)points arrayCount:(int)cnt andImage:(UIImage *)image;
- (void)deconvoluateImage;

@end
