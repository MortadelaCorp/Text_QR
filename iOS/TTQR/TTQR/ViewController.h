//
//  ViewController.h
//  TTQR
//
//  Created by Andrés Ruiz on 19/02/14.
//  Copyright (c) 2014 tratamientodeimagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>

@property (strong, nonatomic) IBOutlet UIView *viewPreview;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
 
@end
