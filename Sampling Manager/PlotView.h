//
//  PlotView.h
//  Sampling Manager
//
//  Created by Демидов Александр on 12.09.12.
//  Copyright (c) 2012 Александр Демидов. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlotView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic) CGFloat scale;
@property (nonatomic, assign) CGFloat *points;
@property (nonatomic) GLuint arrayCount;

- (void)pinch:(UIPinchGestureRecognizer *)gesture;
- (void)handelPanGesture:(UIPanGestureRecognizer *)gesture;

@end
