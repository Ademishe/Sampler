//
//  ViewController.m
//  Sampling Manager
//
//  Created by Александр Демидов on 11.09.12.
//  Copyright (c) 2012 Александр Демидов. All rights reserved.
//

#import "ViewController.h"
#import "PlotView.h"
#import "OpenGLView.h"
#import <QuartzCore/QuartzCore.h>
#import "fftw3.h"

#define kFilteringFactor 0.5
#define OVERLAY_SIZE 0.1

@interface ViewController ()

- (void)setPoints;
- (BOOL)startCameraControllerFromViewController:(UIViewController*) controller
								  usingDelegate:(id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>) delegate;
- (void)prepareArray;

@end

@implementation ViewController

@synthesize plotter = _plotter;
@synthesize plotter3D = _plotter3D;
@synthesize toggleButton = _toggleButton;
@synthesize arrayWithPoints = _arrayWithPoints;

- (void)viewDidLoad
{
    [super viewDidLoad];
    cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    cameraUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    cameraUI.allowsEditing = NO;
    cameraUI.showsCameraControls = NO;
    UIView *cameraOverlayView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, cameraUI.view.frame.size.height - OVERLAY_SIZE*cameraUI.view.frame.size.height, cameraUI.view.frame.size.width, OVERLAY_SIZE*cameraUI.view.frame.size.height)];
    [cameraOverlayView setBackgroundColor:[UIColor whiteColor]];
    
    UIButton *photoButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [photoButton setFrame:CGRectMake(0.0, 0.0, 0.2*cameraOverlayView.frame.size.width, 0.9*cameraOverlayView.frame.size.height)];
    [photoButton setTitle:@"Take it!" forState:UIControlStateNormal];
    [photoButton addTarget:self action:@selector(beginSamplingAndTakePhoto:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [cancelButton setFrame:CGRectMake(photoButton.frame.size.width, 0.0, 0.2*cameraOverlayView.frame.size.width, 0.9*cameraOverlayView.frame.size.height)];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
    
    [cameraOverlayView addSubview:cancelButton];
    [cameraOverlayView addSubview:photoButton];
	[cameraUI setCameraOverlayView:cameraOverlayView];
    
	_arrayWithPoints = NULL;
    
    accelX = accelY = accelZ = 0.0;
    
    accelManager = [CMMotionManager new];
    accelManager.accelerometerUpdateInterval = 0.01;
	
	[self.plotter setBounds:CGRectMake(-self.plotter.bounds.size.width / 2.0, -self.plotter.bounds.size.height / 2.0, self.plotter.bounds.size.width, self.plotter.bounds.size.height)];
	
	UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self.plotter action:@selector(pinch:)];
	[pinch setDelegate:self.plotter];
	[self.plotter addGestureRecognizer:pinch];
	UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self.plotter action:@selector(handelPanGesture:)];
	[pan setDelegate:self.plotter];
	[pan setMaximumNumberOfTouches:2];
	[self.plotter addGestureRecognizer:pan];
    
//    UIPinchGestureRecognizer *pinch3D = [[UIPinchGestureRecognizer alloc] initWithTarget:self.plotter3D action:@selector(handelPinchGesture:)];
//	[pinch3D setDelegate:self.plotter3D];
//	[self.plotter3D addGestureRecognizer:pinch3D];
//	UIPanGestureRecognizer *pan3D = [[UIPanGestureRecognizer alloc] initWithTarget:self.plotter3D action:@selector(handelPanGesture:)];
//	[pan3D setDelegate:self.plotter3D];
//	[pan3D setMaximumNumberOfTouches:2];
//	[self.plotter3D addGestureRecognizer:pan3D];
//    
//    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.plotter3D.layer;
//    
//    eaglLayer.opaque = TRUE;
//    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
//    
//    [self.plotter3D resizeFromLayer:eaglLayer];
}

- (void)viewDidUnload
{
    [self setToggleButton:nil];
    [self setPlotter:nil];
//	[self setPlotter3D:nil];
    
    accelManager = nil;
	
	free(self.arrayWithPoints);
	_arrayWithPoints = NULL;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)refreshViews:(UIButton *)sender
{
    [self.plotter setNeedsDisplay];
//	[self.plotter3D render];
}

- (IBAction)takePhoto:(id)sender
{
	[self startCameraControllerFromViewController:self usingDelegate:self];
}

#pragma mark - Private Methods

- (void)prepareArray
{
    free(_arrayWithPoints);
	_arrayWithPoints = NULL;
	_arrayWithPoints = (GLfloat *)malloc(3 * sizeof(GLfloat));
	if (_arrayWithPoints == NULL) {
		NSLog(@"Memory allocation error!");
		return;
	}
	_arrayWithPoints[0] = _arrayWithPoints[1] = _arrayWithPoints[2] = 0.0f;
	memoryCount = 3;
}


- (void)setPoints
{
//	[self.plotter3D setArrayCount:memoryCount];
//    [self.plotter3D setPoints:self.arrayWithPoints];
	[self.plotter setArrayCount:memoryCount];
	[self.plotter setPoints:self.arrayWithPoints];
}

- (BOOL)startCameraControllerFromViewController:(UIViewController*) controller
								  usingDelegate:(id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>) delegate
{
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) ||
		(delegate == nil) ||
		(controller == nil)) return NO;
    
    cameraUI.delegate = delegate;
    [controller presentViewController:cameraUI animated:YES completion:nil];
    return YES;
}

#pragma mark - Delegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self.toggleButton setTitle:@"Start sampling" forState:UIControlStateNormal];
    [self setPoints];
//    NSLog(@"count = %d", memoryCount);
//    for (int i = 0; i < memoryCount; i += 3) {
//        NSLog(@"x = %f y = %f", self.arrayWithPoints[i], self.arrayWithPoints[i+1]);
//    }
    NSLog(@"%@", [info description]);
    UIImageWriteToSavedPhotosAlbum([info objectForKey:UIImagePickerControllerOriginalImage], nil, nil, nil);
}


- (void)dismiss:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)beginSamplingAndTakePhoto:(UIButton *)sender
{
    [self.plotter setArrayCount:0];
    [self.plotter setPoints:NULL];
//    [self.plotter3D setArrayCount:0];
//    [self.plotter3D setPoints:NULL];
    
    [self.toggleButton setTitle:@"Stop sampling" forState:UIControlStateNormal];
    [self prepareArray];
    
    void (^handlerBlock)(CMAccelerometerData *, NSError *) = ^(CMAccelerometerData *accelerometerData, NSError *error) {
        accelX = accelerometerData.acceleration.x - ( (accelerometerData.acceleration.x * kFilteringFactor) + (accelX * (1.0 - kFilteringFactor)) );
        accelY = accelerometerData.acceleration.y - ( (accelerometerData.acceleration.y * kFilteringFactor) + (accelY * (1.0 - kFilteringFactor)) );
        accelZ = accelerometerData.acceleration.z - ( (accelerometerData.acceleration.z * kFilteringFactor) + (accelZ * (1.0 - kFilteringFactor)) );
        
        GLfloat *tempArray = (GLfloat *)realloc(_arrayWithPoints, (memoryCount + 3) * sizeof(GLfloat));
        if (tempArray == NULL) {
            NSLog(@"Memory error!");
            return;
        }
        _arrayWithPoints = tempArray;
        memoryCount += 3;
        
        GLfloat oldX = _arrayWithPoints[memoryCount - 6];
        GLfloat oldY = _arrayWithPoints[memoryCount - 5];
        GLfloat oldZ = _arrayWithPoints[memoryCount - 4];
        _arrayWithPoints[memoryCount - 3] = oldX + accelX;
        _arrayWithPoints[memoryCount - 2] = oldY - accelY;
        _arrayWithPoints[memoryCount - 1] = oldZ + accelZ;
    };
    
    [accelManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:handlerBlock];
    [accelManager performSelector:@selector(stopAccelerometerUpdates) withObject:nil afterDelay:0.2];
    [cameraUI takePicture];
}

@end
