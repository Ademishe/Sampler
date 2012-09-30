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

- (void)draw2DPlot;
- (void)draw3DPlot;

@end

@implementation ViewController

@synthesize plotter = _plotter;
@synthesize plotter3D = _plotter3D;
@synthesize toggleButton = _toggleButton;
@synthesize points = _points;
@synthesize arrayWithPoints = _arrayWithPoints;

- (void)viewDidLoad
{
    [super viewDidLoad];
	_arrayWithPoints = NULL;
    isSampling = NO;
    
    accelX = accelY = accelZ = 0.0;
    
    accelManager = [CMMotionManager new];
    accelManager.accelerometerUpdateInterval = 0.02;
//    NSDictionary *pointCoords = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:0.0], @"x",
//                                                                           [NSNumber numberWithFloat:0.0], @"y",
//                                                                           [NSNumber numberWithFloat:0.0], @"z", nil];
//    self.points = [NSMutableArray new];
//    [self.points addObject:pointCoords];
	
	[self.plotter setBounds:CGRectMake(-self.plotter.bounds.size.width / 2.0, -self.plotter.bounds.size.height / 2.0, self.plotter.bounds.size.width, self.plotter.bounds.size.height)];
	
	UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self.plotter action:@selector(pinch:)];
	[pinch setDelegate:self.plotter];
	[self.plotter addGestureRecognizer:pinch];
	UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self.plotter action:@selector(handelPanGesture:)];
	[pan setDelegate:self.plotter];
	[pan setMaximumNumberOfTouches:2];
	[self.plotter addGestureRecognizer:pan];
    
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.plotter3D.layer;
    
    eaglLayer.opaque = TRUE;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    [self.plotter3D resizeFromLayer:eaglLayer];
}

- (void)viewDidUnload
{
    [self setPoints:nil];
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
//		for (int i = 0; i < memoryCount; i += 3)
//			NSLog(@"x = %f, y = %f, z = %f", self.arrayWithPoints[i], self.arrayWithPoints[i+1], self.arrayWithPoints[i+2]);
		[self draw2DPlot];
//        [self draw3DPlot];
    }
    else {
        isSampling = YES;
        [self.toggleButton setTitle:@"Stop sampling" forState:UIControlStateNormal];
		
//		NSMutableArray *newPoints = [NSMutableArray arrayWithObject:[self.points objectAtIndex:0]];
//		[self setPoints:nil];
//		self.points = newPoints;
		
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
//                                               NSDictionary *point = (NSDictionary *)[self.points lastObject];
//                                               NSNumber *newX = [NSNumber numberWithFloat:([[point objectForKey:@"x"] floatValue] + accelX)];
//                                               NSNumber *newY = [NSNumber numberWithFloat:([[point objectForKey:@"y"] floatValue] - accelY)];
//                                               NSNumber *newZ = [NSNumber numberWithFloat:([[point objectForKey:@"z"] floatValue] + accelZ)];
//                                               NSDictionary *newPoint = [NSDictionary dictionaryWithObjectsAndKeys:newX, @"x",
//                                                                                                                   newY, @"y",
//                                                                                                                   newZ, @"z", nil];
//                                               [self.points addObject:newPoint];
											   
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

#pragma mark - Private Methods

- (void)draw2DPlot
{
//	NSDictionary *point1 = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.0], @"x",
//																	  [NSNumber numberWithFloat:1.0], @"y",
//																	  [NSNumber numberWithFloat:0.0], @"z", nil];
//	NSDictionary *point2 = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:50.0], @"x",
//																	  [NSNumber numberWithFloat:40.0], @"y",
//																	  [NSNumber numberWithFloat:0.0], @"z", nil];
//	NSDictionary *point3 = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:100.0], @"x",
//																	  [NSNumber numberWithFloat:100.0], @"y",
//																	  [NSNumber numberWithFloat:0.0], @"z", nil];
//	[self.plotter setPlotPoints:[NSArray arrayWithObjects:point1, point2, point3, nil]];
	
//	[self.plotter setPlotPoints:(NSArray *)self.points];
	[self.plotter setArrayCount:memoryCount];
	[self.plotter setPoints:self.arrayWithPoints];
	[self.plotter setNeedsDisplay];
}

- (void)draw3DPlot
{
    [self.plotter3D setPlotPoints:(NSArray *)self.points];
    [self.plotter3D render];
}

@end
