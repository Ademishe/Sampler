//
//  ViewController.h
//  Sampling Manager
//
//  Created by Александр Демидов on 11.09.12.
//  Copyright (c) 2012 Александр Демидов. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeconvolutionTool.h"

@class PlotView;
@class CMMotionManager;

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, DeconvolutionToolDelegate> {
    CMMotionManager *accelManager;
    CGFloat accelX, accelY, accelZ;
	unsigned int memoryCount;
    UIImagePickerController *cameraUI;
	CGFloat *_arrayWithPoints;
	DeconvolutionTool *_tool;
}

@property (weak, nonatomic) IBOutlet PlotView *plotter;
@property (weak, nonatomic) IBOutlet UIButton *toggleButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak) IBOutlet UIImageView *resultImageView;
@property (weak) IBOutlet UIActivityIndicatorView *indicator;

- (IBAction)takePhoto:(UIButton *)sender;
- (IBAction)refreshViews:(UIButton *)sender;
- (void)beginSamplingAndTakePhoto:(UIButton *)sender;

@end
