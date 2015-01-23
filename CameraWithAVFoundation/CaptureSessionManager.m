//
//  CaptureSessionManager.m
//  CameraWithAVFoundation
//
//  Created by Gabriel Alvarado on 4/16/14.
//  Copyright (c) 2014 Gabriel Alvarado. All rights reserved.
//

#import "CaptureSessionManager.h"
#import <ImageIO/ImageIO.h>

@implementation CaptureSessionManager

@synthesize captureSession;
@synthesize previewLayer;
@synthesize stillImageOutput;
@synthesize stillImage;

#pragma mark Capture Session Configuration

- (id)init {
	if ((self = [super init])) {
		[self setCaptureSession:[[AVCaptureSession alloc] init]];
        captureSession.sessionPreset = AVCaptureSessionPresetHigh;
	}
	return self;
}

- (void)addVideoPreviewLayer {
	[self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:[self captureSession]]];
	[[self previewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
}

- (void)addVideoInputFrontCamera:(BOOL)front {
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    
    for (AVCaptureDevice *device in devices) {
        
        NSLog(@"Device name: %@", [device localizedName]);
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack) {
                NSLog(@"Device position : back");
                backCamera = device;
            }
            else {
                NSLog(@"Device position : front");
                frontCamera = device;
            }
        }
    }
    
    NSError *error = nil;
    
    if (front) {
        AVCaptureDeviceInput *frontFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
        if (!error) {
            if ([[self captureSession] canAddInput:frontFacingCameraDeviceInput]) {
                [[self captureSession] addInput:frontFacingCameraDeviceInput];
            } else {
                NSLog(@"Couldn't add front facing video input");
            }
        }
    } else {
        AVCaptureDeviceInput *backFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
        if (!error) {
            if ([[self captureSession] canAddInput:backFacingCameraDeviceInput]) {
                [[self captureSession] addInput:backFacingCameraDeviceInput];
            } else {
                NSLog(@"Couldn't add back facing video input");
            }
        }
    }
}

- (void)addStillImageOutput
{
    [self setStillImageOutput:[[AVCaptureStillImageOutput alloc] init]];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
    [[self stillImageOutput] setOutputSettings:outputSettings];
    
    AVCaptureConnection *videoConnection = nil;
    
    for (AVCaptureConnection *connection in [[self stillImageOutput] connections]) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                AVCaptureVideoOrientation newOrientation;
                switch ([[UIDevice currentDevice] orientation]) {
                    case UIDeviceOrientationPortrait:
                        newOrientation = AVCaptureVideoOrientationPortrait;
                        break;
                    case UIDeviceOrientationPortraitUpsideDown:
                        newOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                        break;
                    case UIDeviceOrientationLandscapeLeft:
                        newOrientation = AVCaptureVideoOrientationLandscapeRight;
                        break;
                    case UIDeviceOrientationLandscapeRight:
                        newOrientation = AVCaptureVideoOrientationLandscapeLeft;
                        break;
                    default:
                        newOrientation = AVCaptureVideoOrientationPortrait;
                }
                [videoConnection setVideoOrientation: newOrientation];
                break;
            }
        }
        if (videoConnection) {
            AVCaptureVideoOrientation newOrientation;
            switch ([[UIDevice currentDevice] orientation]) {
                case UIDeviceOrientationPortrait:
                    newOrientation = AVCaptureVideoOrientationPortrait;
                    break;
                case UIDeviceOrientationPortraitUpsideDown:
                    newOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                    break;
                case UIDeviceOrientationLandscapeLeft:
                    newOrientation = AVCaptureVideoOrientationLandscapeRight;
                    break;
                case UIDeviceOrientationLandscapeRight:
                    newOrientation = AVCaptureVideoOrientationLandscapeLeft;
                    break;
                default:
                    newOrientation = AVCaptureVideoOrientationPortrait;
            }
            [videoConnection setVideoOrientation: newOrientation];
            break;
        }
    }
    
    [[self captureSession] addOutput:[self stillImageOutput]];
}

- (void)captureStillImage
{
	AVCaptureConnection *videoConnection = nil;
    
	for (AVCaptureConnection *connection in [[self stillImageOutput] connections]) {
		for (AVCaptureInputPort *port in [connection inputPorts]) {
			if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
                AVCaptureVideoOrientation newOrientation;
                switch ([[UIDevice currentDevice] orientation]) {
                    case UIDeviceOrientationPortrait:
                        newOrientation = AVCaptureVideoOrientationPortrait;
                        break;
                    case UIDeviceOrientationPortraitUpsideDown:
                        newOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                        break;
                    case UIDeviceOrientationLandscapeLeft:
                        newOrientation = AVCaptureVideoOrientationLandscapeRight;
                        break;
                    case UIDeviceOrientationLandscapeRight:
                        newOrientation = AVCaptureVideoOrientationLandscapeLeft;
                        break;
                    default:
                        newOrientation = AVCaptureVideoOrientationPortrait;
                }
                [videoConnection setVideoOrientation: newOrientation];
				break;
			}
		}
		if (videoConnection) {
            AVCaptureVideoOrientation newOrientation;
            switch ([[UIDevice currentDevice] orientation]) {
                case UIDeviceOrientationPortrait:
                    newOrientation = AVCaptureVideoOrientationPortrait;
                    break;
                case UIDeviceOrientationPortraitUpsideDown:
                    newOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                    break;
                case UIDeviceOrientationLandscapeLeft:
                    newOrientation = AVCaptureVideoOrientationLandscapeRight;
                    break;
                case UIDeviceOrientationLandscapeRight:
                    newOrientation = AVCaptureVideoOrientationLandscapeLeft;
                    break;
                default:
                    newOrientation = AVCaptureVideoOrientationPortrait;
            }
            [videoConnection setVideoOrientation: newOrientation];
            break;
        }
	}
    
	NSLog(@"about to request a capture from: %@", [self stillImageOutput]);
	[[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:videoConnection
                                                         completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
                                                             CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
                                                             if (exifAttachments) {
                                                                 NSLog(@"attachements: %@", exifAttachments);
                                                             } else {
                                                                 NSLog(@"no attachments");
                                                             }
                                                             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                                                             UIImage *image = [[UIImage alloc] initWithData:imageData];
                                                             [self setStillImage:image];
                                                             [[NSNotificationCenter defaultCenter] postNotificationName:kImageCapturedSuccessfully object:nil];
                                                         }];
}

- (void)dealloc {
    
	[[self captureSession] stopRunning];
    
	previewLayer = nil;
	captureSession = nil;
    stillImageOutput = nil;
    stillImage = nil;
}


@end