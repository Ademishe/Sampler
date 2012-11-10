//
//  ViewController.h
//  Sampling Manager
//
//  Created by Александр Демидов on 11.09.12.
//  Copyright (c) 2012 Александр Демидов. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PlotView;
@class CMMotionManager;
@protocol UIImagePickerControllerDelegate;

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    CMMotionManager *accelManager;
    CGFloat accelX, accelY, accelZ;
	unsigned int memoryCount;
    UIImagePickerController *cameraUI;
}

@property (weak, nonatomic) IBOutlet PlotView *plotter;
@property (weak, nonatomic) IBOutlet UIButton *toggleButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (readonly, assign, nonatomic) CGFloat *arrayWithPoints;

- (IBAction)takePhoto:(UIButton *)sender;
- (IBAction)refreshViews:(UIButton *)sender;
- (void)beginSamplingAndTakePhoto:(UIButton *)sender;

@end
