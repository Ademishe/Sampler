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


#define kFilteringFactor 0.5

@interface ViewController ()

- (void)setPoints;
- (void)draw;
- (BOOL)startCameraControllerFromViewController:(UIViewController*) controller
								  usingDelegate:(id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>) delegate;
@end

@implementation ViewController

@synthesize plotter = _plotter;
@synthesize plotter3D = _plotter3D;
@synthesize toggleButton = _toggleButton;
@synthesize arrayWithPoints = _arrayWithPoints;

- (void)viewDidLoad
{
    [super viewDidLoad];
	_arrayWithPoints = NULL;
    isSampling = NO;
    
    accelX = accelY = accelZ = 0.0;
    
    accelManager = [CMMotionManager new];
    accelManager.accelerometerUpdateInterval = 0.08;
	
	[self.plotter setBounds:CGRectMake(-self.plotter.bounds.size.width / 2.0, -self.plotter.bounds.size.height / 2.0, self.plotter.bounds.size.width, self.plotter.bounds.size.height)];
	
	UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self.plotter action:@selector(pinch:)];
	[pinch setDelegate:self.plotter];
	[self.plotter addGestureRecognizer:pinch];
	UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self.plotter action:@selector(handelPanGesture:)];
	[pan setDelegate:self.plotter];
	[pan setMaximumNumberOfTouches:2];
	[self.plotter addGestureRecognizer:pan];
    
    UIPinchGestureRecognizer *pinch3D = [[UIPinchGestureRecognizer alloc] initWithTarget:self.plotter3D action:@selector(handelPinchGesture:)];
	[pinch3D setDelegate:self.plotter3D];
	[self.plotter3D addGestureRecognizer:pinch3D];
	UIPanGestureRecognizer *pan3D = [[UIPanGestureRecognizer alloc] initWithTarget:self.plotter3D action:@selector(handelPanGesture:)];
	[pan3D setDelegate:self.plotter3D];
	[pan3D setMaximumNumberOfTouches:2];
	[self.plotter3D addGestureRecognizer:pan3D];
    
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.plotter3D.layer;
    
    eaglLayer.opaque = TRUE;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    [self.plotter3D resizeFromLayer:eaglLayer];
}

- (void)viewDidUnload
{
    [self setToggleButton:nil];
    [self setPlotter:nil];
	[self setPlotter3D:nil];
    
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

- (IBAction)toggleSampling:(UIButton *)sender
{
    if (isSampling) {
        isSampling = NO;
        [self.toggleButton setTitle:@"Start sampling" forState:UIControlStateNormal];
        
        [accelManager stopAccelerometerUpdates];
		[self setPoints];
        [self draw];
    }
    else {
        isSampling = YES;
		[self.plotter setArrayCount:0];
		[self.plotter setPoints:NULL];
		[self.plotter3D setArrayCount:0];
		[self.plotter3D setPoints:NULL];
		
        [self.toggleButton setTitle:@"Stop sampling" forState:UIControlStateNormal];
		
		free(self.arrayWithPoints);
		_arrayWithPoints = NULL;
		_arrayWithPoints = (GLfloat *)malloc(3 * sizeof(GLfloat));
		if (_arrayWithPoints == NULL) {
			NSLog(@"Memory allocation error!");
			return;
		}
		_arrayWithPoints[0] = _arrayWithPoints[1] = _arrayWithPoints[2] = 0.0f;
		memoryCount = 3;
		
        [accelManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue]
                                           withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
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
                                           }];
    }
}

- (IBAction)takePhoto:(id)sender
{
	[self startCameraControllerFromViewController:self usingDelegate:self];
}

#pragma mark - Private Methods

- (void)setPoints
{
	[self.plotter setNeedsDisplay];
	[self.plotter3D render];
}

- (void)draw
{
    [self.plotter3D setArrayCount:memoryCount];
    [self.plotter3D setPoints:self.arrayWithPoints];
	[self.plotter setArrayCount:memoryCount];
	[self.plotter setPoints:self.arrayWithPoints];
}

- (BOOL)startCameraControllerFromViewController:(UIViewController*) controller
								  usingDelegate: (id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>) delegate
{
	
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) ||
		(delegate == nil) ||
		(controller == nil)) return NO;
	
	
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
	
    // Displays a control that allows the user to choose picture or
    // movie capture, if both are available:
    cameraUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
	
    // Hides the controls for moving & scaling pictures, or for
    // trimming movies. To instead show the controls, use YES.
    cameraUI.allowsEditing = NO;
	
    cameraUI.delegate = delegate;
	
    [controller presentModalViewController:cameraUI animated:YES];
    return YES;
}

@end
