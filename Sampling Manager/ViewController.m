//
//  ViewController.m
//  Sampling Manager
//
//  Created by Александр Демидов on 11.09.12.
//  Copyright (c) 2012 Александр Демидов. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
#import "PlotView.h"
#import <xpc/xpc.h>


#define kFilteringFactor 0.5
#define OVERLAY_SIZE 0.1
#define DIMENSIONS_NUM 3

UIImage *getPreviewImage(UIImage *image, double percent) {
	UIGraphicsBeginImageContext(CGSizeMake(image.size.width*percent, image.size.height*percent));
	
	[image drawInRect: CGRectMake(0, 0, image.size.width*percent, image.size.height*percent)];
	UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return smallImage;
}

@interface ViewController ()

- (void)setPoints;
- (BOOL)startCameraControllerFromViewController:(UIViewController*) controller
								  usingDelegate:(id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>) delegate;
- (void)prepareArray;

@end

@implementation ViewController

@synthesize plotter = _plotter;
@synthesize imageView = _imageView;
@synthesize resultImageView = _resultImageView;
@synthesize indicator = _indicator;

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
	_tool = nil;
    
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
}

- (void)dealloc
{
    [self setPlotter:nil];
	[self setImageView:nil];
	[self setResultImageView:nil];
	[self setIndicator:nil];
    
    accelManager = nil;
	_tool = nil;
	
	free(_arrayWithPoints);
	_arrayWithPoints = NULL;
	
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Something is bad... Not enough memory:("
                                                   delegate:nil cancelButtonTitle:@"Ok, I'll close the app"
                                          otherButtonTitles:nil];
    [alert show];
}

- (NSInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Actions

- (IBAction)refreshViews:(UIButton *)sender
{
    [self.plotter setNeedsDisplay];
}

- (IBAction)takePhoto:(UIButton *)sender
{
//    NSString *reqSysVer = @"6.0";
//    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
//    if ([currSysVer compare:reqSysVer options:NSNumericSearch] == NSOrderedAscending) {
//        NSLog(@"LOL!");
//        xpc_connection_t myconnection;
//    
//        dispatch_queue_t queue = dispatch_queue_create("com.apple.chatkit.clientcomposeserver.xpc", DISPATCH_QUEUE_CONCURRENT);
//    
//        myconnection = xpc_connection_create_mach_service("com.apple.chatkit.clientcomposeserver.xpc", queue, XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);
//        xpc_connection_set_event_handler(myconnection, ^(xpc_object_t event) {
//        xpc_type_t xtype = xpc_get_type(event);
//            if (XPC_TYPE_ERROR == xtype) {
//                NSLog(@"XPC sandbox connection error: %s\n", xpc_dictionary_get_string(event, XPC_ERROR_KEY_DESCRIPTION));
//            }
//        
//            NSLog(@"Received an message event!");
//        
//        });
//        
//        xpc_connection_resume(myconnection);
//        NSArray *receipements = [NSArray arrayWithObjects:@"+7 (916) 732-12-58", nil];
//        
//        NSData *ser_rec = [NSPropertyListSerialization dataWithPropertyList:receipements format:200 options:0 error:NULL];
//        
//        xpc_object_t mydict = xpc_dictionary_create(0, 0, 0);
//        xpc_dictionary_set_int64(mydict, "message-type", 0);
//        xpc_dictionary_set_data(mydict, "recipients", [ser_rec bytes], [ser_rec length]);
//        xpc_dictionary_set_string(mydict, "text", "пора обновить ПО, Лиза");
//        xpc_connection_send_message(myconnection, mydict);
//        xpc_connection_send_barrier(myconnection, ^{
//            NSLog(@"Message has been successfully delievered");
//        });
//    }
	[self startCameraControllerFromViewController:self usingDelegate:self];
}

- (void)dismiss:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
	if (_tool) {
		[self.indicator startAnimating];
//		[_tool performSelectorInBackground:@selector(deconvoluateImage) withObject:nil];
	}
}

- (void)beginSamplingAndTakePhoto:(UIButton *)sender
{
    [self.plotter setArrayCount:0];
    [self.plotter setPoints:NULL];
    
    [self prepareArray];
    
    void (^handlerBlock)(CMAccelerometerData *, NSError *) = ^(CMAccelerometerData *accelerometerData, NSError *error) {
        accelX = accelerometerData.acceleration.x - ( (accelerometerData.acceleration.x * kFilteringFactor) + (accelX * (1.0 - kFilteringFactor)) );
        accelY = accelerometerData.acceleration.y - ( (accelerometerData.acceleration.y * kFilteringFactor) + (accelY * (1.0 - kFilteringFactor)) );
        accelZ = accelerometerData.acceleration.z - ( (accelerometerData.acceleration.z * kFilteringFactor) + (accelZ * (1.0 - kFilteringFactor)) );
        
        CGFloat *tempArray = (CGFloat *)realloc(_arrayWithPoints, (memoryCount + DIMENSIONS_NUM) * sizeof(CGFloat));
        if (tempArray == NULL) {
            NSLog(@"Memory error!");
            return;
        }
        _arrayWithPoints = tempArray;
        memoryCount += DIMENSIONS_NUM;
        
        CGFloat oldX = _arrayWithPoints[memoryCount - 6];
        CGFloat oldY = _arrayWithPoints[memoryCount - 5];
        CGFloat oldZ = _arrayWithPoints[memoryCount - 4];
        _arrayWithPoints[memoryCount - 3] = oldX + accelX;
        _arrayWithPoints[memoryCount - 2] = oldY - accelY;
        _arrayWithPoints[memoryCount - 1] = oldZ + accelZ;
    };
    
//    NSArray *arguments = [NSArray arrayWithObjects:[NSOperationQueue mainQueue], handlerBlock, nil];
    [accelManager performSelector:@selector(stopAccelerometerUpdates) withObject:nil afterDelay:0.20];
//    [accelManager performSelector:@selector(startAccelerometerUpdatesToQueue:withHandler:) withObject:arguments afterDelay:0.1];
    [accelManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:handlerBlock];
    [cameraUI takePicture];
}

#pragma mark - Private Methods

- (void)prepareArray
{
    free(_arrayWithPoints);
	_arrayWithPoints = NULL;
	_arrayWithPoints = (CGFloat *)malloc(DIMENSIONS_NUM * sizeof(CGFloat));
	if (_arrayWithPoints == NULL) {
		NSLog(@"Memory allocation error!");
		return;
	}
	_arrayWithPoints[0] = _arrayWithPoints[1] = _arrayWithPoints[2] = 0.0f;
	memoryCount = DIMENSIONS_NUM;
}


- (void)setPoints
{
	[self.plotter setArrayCount:memoryCount];
	[self.plotter setPoints:_arrayWithPoints];
}

- (BOOL)startCameraControllerFromViewController:(UIViewController*)controller
								  usingDelegate:(id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>)delegate
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
    [self setPoints];
//    NSLog(@"%@", [info description]);
    //2592x1936 - image size
	_tool = [[DeconvolutionTool alloc] initWithArray:_arrayWithPoints arrayCount:memoryCount andImage:[[info objectForKey:UIImagePickerControllerOriginalImage] copy]];
	[_tool setDelegate:self];
	
    CGPoint viewPlace = self.imageView.center;
    [self.imageView setFrame:CGRectMake(0.0, 0.0, _tool.originalImage.size.width*0.07, _tool.originalImage.size.height*0.07)];
    self.imageView.center = viewPlace;
    [self.imageView setImage:getPreviewImage(_tool.originalImage, 0.2)];
	
	[self.resultImageView setImage:nil];
	
//    UIImageWriteToSavedPhotosAlbum([info objectForKey:UIImagePickerControllerOriginalImage], nil, nil, nil);
}

- (void)deconvolitonTool:(DeconvolutionTool *)tool hasFinished:(UIImage *)resultImage
{
	[self.indicator stopAnimating];
	CGPoint viewPlace = self.resultImageView.center;
	[self.resultImageView setFrame:CGRectMake(0.0, 0.0, resultImage.size.width*0.07, resultImage.size.width*0.7)];
	self.resultImageView.center = viewPlace;
	[self.resultImageView setImage:getPreviewImage(resultImage, 0.07)];
}

@end
