//
//  CACameraSessionDelegate.h
//
//  Created by Christopher Cohen & Gabriel Alvarado on 1/23/15.
//  Copyright (c) 2015 Gabriel Alvarado. All rights reserved.
//

#import "CameraSessionView.h"
#import "CaptureSessionManager.h"
#import <ImageIO/ImageIO.h>

//Custom UI classesdrawLaunchCameraWithFrame
#import "CameraFocalReticule.h"
#import "Constants.h"

@interface CameraSessionView () <CaptureSessionManagerDelegate>
{
    //Size of the UI elements variables
    CGSize shutterButtonSize;
    CGSize topBarSize;
    CGSize barButtonItemSize;
    
    //Variable vith the current camera being used (Rear/Front)
    CameraType cameraBeingUsed;
}

//Primative Properties
@property (readwrite) BOOL animationInProgress;

//Object References
@property (nonatomic, strong) CaptureSessionManager *captureManager;

@property (nonatomic, strong) CameraFocalReticule *focalReticule;

@property (nonatomic, strong) UIView *topBarView;

//Temporary/Diagnostic properties
@property (nonatomic, strong) UILabel *ISOLabel, *apertureLabel, *shutterSpeedLabel;

@end

@implementation CameraSessionView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _animationInProgress = NO;
        [self setupCaptureManager:RearFacingCamera];
        cameraBeingUsed = RearFacingCamera;
        self.viewBackgroundColor = [UIColor blackColor];
        
        [self composeInterface];
        
        [[_captureManager captureSession] startRunning];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _animationInProgress = NO;
        [self setupCaptureManager:RearFacingCamera];
        cameraBeingUsed = RearFacingCamera;
        self.viewBackgroundColor = [UIColor blackColor];
        
        [self composeInterface];
        
        
        [[_captureManager captureSession] startRunning];
    }
    return self;
}

#pragma mark - Setup

-(void)setupCaptureManager:(CameraType)camera {
    
    // remove existing input
    AVCaptureInput* currentCameraInput = [self.captureManager.captureSession.inputs objectAtIndex:0];
    [self.captureManager.captureSession removeInput:currentCameraInput];
    
    _captureManager = nil;
    
    //Create and configure 'CaptureSessionManager' object
    _captureManager = [CaptureSessionManager new];
    
    // indicate that some changes will be made to the session
    [self.captureManager.captureSession beginConfiguration];
    
    if (_captureManager) {
        
        //Configure
        [_captureManager setDelegate:self];
        [_captureManager initiateCaptureSessionForCamera:camera];
        [_captureManager addStillImageOutput];
        [_captureManager addVideoPreviewLayer];
        [self.captureManager.captureSession commitConfiguration];
        
        CGFloat topBuffer = 64.f; //20 for status bar and 44 for standard navbar height
        CGFloat bottomBuffer = 100.f;
        
        //Preview Layer setup
        CGRect layerRect = self.layer.bounds;
        layerRect.origin.y = topBuffer;
        layerRect.size.height = layerRect.size.height - (topBuffer + bottomBuffer);
        
        [_captureManager.previewLayer setBounds:layerRect];
        [_captureManager.previewLayer setPosition:CGPointMake(CGRectGetMidX(layerRect),CGRectGetMidY(layerRect))];
        
        //Apply animation effect to the camera's preview layer
        CATransition *applicationLoadViewIn =[CATransition animation];
        [applicationLoadViewIn setDuration:0.6];
        [applicationLoadViewIn setType:kCATransitionReveal];
        [applicationLoadViewIn setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
        [_captureManager.previewLayer addAnimation:applicationLoadViewIn forKey:kCATransitionReveal];
        
        //Add to self.view's layer
        [self.layer addSublayer:_captureManager.previewLayer];
    }
}

-(void)composeInterface {
    
    [self setBackgroundColor:self.viewBackgroundColor];
    
    //Adding notifier for orientation changes
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:)    name:UIDeviceOrientationDidChangeNotification  object:nil];
    
    
    //Define adaptable sizing variables for UI elements to the right device family (iPhone or iPad)
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        //Declare the sizing of the UI elements for iPad
        shutterButtonSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width * 0.1, [[UIScreen mainScreen] bounds].size.width * 0.1);
        topBarSize        = CGSizeMake([[UIScreen mainScreen] bounds].size.width, 64.f);
        barButtonItemSize = CGSizeMake([[UIScreen mainScreen] bounds].size.height * 0.04, [[UIScreen mainScreen] bounds].size.height * 0.04);
    } else
    {
        //Declare the sizing of the UI elements for iPhone
        shutterButtonSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width * 0.21, [[UIScreen mainScreen] bounds].size.width * 0.21);
        topBarSize        = CGSizeMake([[UIScreen mainScreen] bounds].size.width, 64.f);
        barButtonItemSize = CGSizeMake([[UIScreen mainScreen] bounds].size.height * 0.05, [[UIScreen mainScreen] bounds].size.height * 0.05);
    }
    
    
    //Create shutter button
    self.cameraShutter = [UIButton new];
    
    if (_captureManager) {
        
        //Button Visual attribution
        self.cameraShutter.frame = (CGRect){0,0, shutterButtonSize};
        self.cameraShutter.center = CGPointMake(self.center.x, [[UIScreen mainScreen] bounds].size.height - 50);
        self.cameraShutter.tag = ShutterButtonTag;
        self.cameraShutter.backgroundColor = [UIColor clearColor];
        [self.cameraShutter setBackgroundImage:[UIImage imageNamed:@"scanbutton"] forState:UIControlStateNormal];
        
        //Button target
        [self.cameraShutter addTarget:self action:@selector(inputManager:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.cameraShutter];
    }
    
    //Create the top bar and add the buttons to it
    self.topBarView = [UIView new];
    
    if (self.topBarView) {
        
        //Setup visual attribution for bar
        self.topBarView.frame  = (CGRect){0,0, topBarSize};
        self.topBarView.backgroundColor = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0];
        [self addSubview:self.topBarView];
        
        //Add the flash button
        self.cameraFlash = [UIButton new];
        if (self.cameraFlash) {
            
            self.cameraFlash.frame = (CGRect){0,0, barButtonItemSize};
            self.cameraFlash.center = CGPointMake(20, self.topBarView.center.y + 10);
            self.cameraFlash.tag = FlashButtonTag;
            if ( UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad ) [self.topBarView addSubview:self.cameraFlash];
            
        }
        
        //Add the camera toggle button
        self.cameraToggle = [UIButton new];
        if (self.cameraToggle) {
            
            self.cameraToggle.frame = (CGRect){0,0, barButtonItemSize};
            self.cameraToggle.center = CGPointMake(self.topBarView.center.x, self.topBarView.center.y + 10);
            self.cameraToggle.tag = ToggleButtonTag;
            [self.topBarView addSubview:self.cameraToggle];
            
        }
        
        //Add the camera dismiss button
        self.cameraDismiss = [UIButton new];
        if (self.cameraDismiss) {
            
            self.cameraDismiss.frame = (CGRect){0,0, barButtonItemSize};
            self.cameraDismiss.center = CGPointMake([[UIScreen mainScreen] bounds].size.width - 20, _topBarView.center.y + 10);
            self.cameraDismiss.tag = DismissButtonTag;
            [self.topBarView addSubview:self.cameraDismiss];
            
        }
        
        //Attribute and configure all buttons in the bar's subview
        for (UIButton *button in _topBarView.subviews) {
            [button addTarget:self action:@selector(inputManager:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    //Create the focus reticule UIView
    self.focalReticule = [CameraFocalReticule new];
    
    if (self.focalReticule) {
        
        self.focalReticule.frame = (CGRect){0,0, 60, 60};
        self.focalReticule.backgroundColor = [UIColor clearColor];
        self.focalReticule.hidden = YES;
        [self addSubview:self.focalReticule];
    }
    
    //Create the gesture recognizer for the focus tap
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusGesture:)];
    if (singleTapGestureRecognizer) [self addGestureRecognizer:singleTapGestureRecognizer];
    
}

#pragma mark - User Interaction

-(void)inputManager:(id)sender {
    
    //If animation is in progress, ignore input
    if (_animationInProgress) return;
    
    //If sender does not inherit from 'UIButton', return
    if (![sender isKindOfClass:[UIButton class]]) return;
    
    //Input manager switch
    switch ([(UIButton *)sender tag]) {
        case ShutterButtonTag:  [self onTapShutterButton];  return;
        case ToggleButtonTag:   [self onTapToggleButton];   return;
        case FlashButtonTag:    [self onTapFlashButton];    return;
        case DismissButtonTag:  [self onTapDismissButton];  return;
    }
}

- (void)onTapShutterButton {
    
    //Animate shutter release
    [self animateShutterRelease];
    
    //Capture image from camera
    [_captureManager captureStillImage];
}

- (void)onTapFlashButton {
    BOOL enable = !self.captureManager.isTorchEnabled;
    self.captureManager.enableTorch = enable;
}

- (void)onTapToggleButton {
    if (cameraBeingUsed == RearFacingCamera) {
        [self setupCaptureManager:FrontFacingCamera];
        cameraBeingUsed = FrontFacingCamera;
        //[self composeInterface];
        [[_captureManager captureSession] startRunning];
        
        [self.cameraFlash setHidden:YES];
        
        
    } else {
        [self setupCaptureManager:RearFacingCamera];
        cameraBeingUsed = RearFacingCamera;
        //[self composeInterface];
        [[_captureManager captureSession] startRunning];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.cameraFlash setHidden:NO];
        });
    }
}

- (void)onTapDismissButton {
    [UIView animateWithDuration:0.3 animations:^{
        self.center = CGPointMake(self.center.x, self.center.y*3);
    } completion:^(BOOL finished) {
        [_captureManager stop];
        [self removeFromSuperview];
    }];
}

- (void)focusGesture:(id)sender {
    
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tap = sender;
        if (tap.state == UIGestureRecognizerStateRecognized) {
            CGPoint location = [sender locationInView:self];
            
            if(CGRectContainsPoint(_captureManager.previewLayer.bounds, location)) {
                [self focusAtPoint:location completionHandler:^{
                    [self animateFocusReticuleToPoint:location];
                }];
            }  
        }
    }
}

#pragma mark - Animation

- (void)animateShutterRelease {
    
    _animationInProgress = YES; //Disables input manager
    
    [UIView animateWithDuration:.1 animations:^{
        _cameraShutter.transform = CGAffineTransformMakeScale(1.25, 1.25);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:.1 animations:^{
            _cameraShutter.transform = CGAffineTransformMakeScale(1, 1);
        } completion:^(BOOL finished) {
            
            _animationInProgress = NO; //Enables input manager
        }];
    }];
}

- (void)animateFocusReticuleToPoint:(CGPoint)targetPoint
{
    _animationInProgress = YES; //Disables input manager
    
    [self.focalReticule setCenter:targetPoint];
    self.focalReticule.alpha = 0.0;
    self.focalReticule.hidden = NO;
    
    [UIView animateWithDuration:0.4 animations:^{
         self.focalReticule.alpha = 1.0;
     } completion:^(BOOL finished) {
         [UIView animateWithDuration:0.4 animations:^{
              self.focalReticule.alpha = 0.0;
          }completion:^(BOOL finished) {
              
              _animationInProgress = NO; //Enables input manager
          }];
     }];
}

- (void)orientationChanged:(NSNotification *)notification{
    
    //Animate top bar buttons on orientation changes
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationPortrait:
        {
            //Standard device orientation (Portrait)
            [UIView animateWithDuration:0.6 animations:^{
                CGAffineTransform transform = CGAffineTransformMakeRotation( 0 );
                
                _cameraFlash.transform = transform;
                _cameraFlash.center = CGPointMake(20 , _topBarView.center.y + 10);
                
                _cameraToggle.transform = transform;
                _cameraToggle.center = CGPointMake(_topBarView.center.x, _topBarView.center.y + 10);
                
                _cameraDismiss.center = CGPointMake([[UIScreen mainScreen] bounds].size.width - 20, _topBarView.center.y + 10);
            }];
        }
            break;
        case UIDeviceOrientationLandscapeLeft:
        {
            //Device orientation changed to landscape left
            [UIView animateWithDuration:0.6 animations:^{
                CGAffineTransform transform = CGAffineTransformMakeRotation( M_PI_2 );
                
                _cameraFlash.transform = transform;
                _cameraFlash.center = CGPointMake(20 , _topBarView.center.y + 10);
                
                _cameraToggle.transform = transform;
                _cameraToggle.center = CGPointMake(_topBarView.center.x, _topBarView.center.y + 10);
                
                _cameraDismiss.center = CGPointMake([[UIScreen mainScreen] bounds].size.width - 20, _topBarView.center.y + 10);
            }];
        }
            break;
        case UIDeviceOrientationLandscapeRight:
        {
            //Device orientation changed to landscape right
            [UIView animateWithDuration:0.6 animations:^{
                CGAffineTransform transform = CGAffineTransformMakeRotation( - M_PI_2 );
                
                _cameraFlash.transform = transform;
                _cameraFlash.center = CGPointMake(20 , _topBarView.center.y + 10);
                
                _cameraToggle.transform = transform;
                _cameraToggle.center = CGPointMake(_topBarView.center.x, _topBarView.center.y + 10);
                
                _cameraDismiss.center = CGPointMake([[UIScreen mainScreen] bounds].size.width - 20, _topBarView.center.y + 10);
            }];
        }
            break;
        default:;
    }
}

#pragma mark - Camera Session Manager Delegate Methods

-(void)cameraSessionManagerDidCaptureImage
{
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(didCaptureImage:)])
            [self.delegate didCaptureImage:[[self captureManager] stillImage]];
        
        if ([self.delegate respondsToSelector:@selector(didCaptureImageWithData:)])
            [self.delegate didCaptureImageWithData:[[self captureManager] stillImageData]];
    }
}

-(void)cameraSessionManagerFailedToCaptureImage {
}

-(void)cameraSessionManagerDidReportAvailability:(BOOL)deviceAvailability forCameraType:(CameraType)cameraType {
}

-(void)cameraSessionManagerDidReportDeviceStatistics:(CameraStatistics)deviceStatistics {
}

#pragma mark - Helper Methods

- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^)())completionHandler
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];;
    CGPoint pointOfInterest = CGPointZero;
    CGSize frameSize = self.bounds.size;
    pointOfInterest = CGPointMake(point.y / frameSize.height, 1.f - (point.x / frameSize.width));
    
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        
        //Lock camera for configuration if possible
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            
            if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
                [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
            }
            
            if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                [device setFocusMode:AVCaptureFocusModeAutoFocus];
                [device setFocusPointOfInterest:pointOfInterest];
            }
            
            if([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                [device setExposurePointOfInterest:pointOfInterest];
                [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            
            [device unlockForConfiguration];
            
            completionHandler();
        }
    }
    else { completionHandler(); }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(void)viewDidDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

#pragma mark - API Functions

- (void)setTopBarColor:(UIColor *)topBarColor
{
    _topBarView.backgroundColor = topBarColor;
}

- (void)hideFlashButton
{
    _cameraFlash.hidden = YES;
}

- (void)hideCameraToogleButton
{
    _cameraToggle.hidden = YES;
}

- (void)hideDismissButton
{
    _cameraDismiss.hidden = YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
