//
//  ViewController.h
//  Sampling Manager
//
//  Created by Александр Демидов on 11.09.12.
//  Copyright (c) 2012 Александр Демидов. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>

@class PlotView;
@class OpenGLView;

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    CMMotionManager *accelManager;
    GLfloat accelX, accelY, accelZ;
	unsigned int memoryCount;
    UIImagePickerController *cameraUI;
}

@property (weak, nonatomic) IBOutlet PlotView *plotter;
@property (weak, nonatomic) IBOutlet OpenGLView *plotter3D;
@property (weak, nonatomic) IBOutlet UIButton *toggleButton;
@property (readonly, assign, nonatomic) GLfloat *arrayWithPoints;

- (IBAction)takePhoto:(UIButton *)sender;
- (IBAction)refreshViews:(UIButton *)sender;
- (void)beginSamplingAndTakePhoto:(UIButton *)sender;

@end
