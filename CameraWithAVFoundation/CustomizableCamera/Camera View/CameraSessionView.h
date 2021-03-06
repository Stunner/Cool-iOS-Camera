//
//  CACameraSessionDelegate.h
//
//  Created by Christopher Cohen & Gabriel Alvarado on 1/23/15.
//  Copyright (c) 2015 Gabriel Alvarado. All rights reserved.
//

#import <UIKit/UIKit.h>

///Protocol Definition
@protocol CACameraSessionDelegate <NSObject>

@optional - (void)didCaptureImage:(UIImage *)image;
@optional - (void)didCaptureImageWithData:(NSData *)imageData;
@optional - (void)didPressCloseButton:(id)sender;

@end

@interface CameraSessionView : UIView

@property (nonatomic, strong) UIColor*      viewBackgroundColor;

@property (nonatomic, strong) UIButton *cameraShutter;
@property (nonatomic, strong) UIButton *cameraToggle;
@property (nonatomic, strong) UIButton *cameraFlash;
@property (nonatomic, strong) UIButton *cameraDismiss;

//Delegate Property
@property (nonatomic, weak) id <CACameraSessionDelegate> delegate;

//API Functions
- (void)setTopBarColor:(UIColor *)topBarColor;
- (void)hideFlashButton;
- (void)hideCameraToogleButton;
- (void)hideDismissButton;

@end
