//
//  IntroViewController.h
//  TTQR
//
//  Created by Andrés Ruiz on 26/03/14.
//  Copyright (c) 2014 tratamientodeimagen. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "ShapeView.h"
#import "UILabelWithPadding.h"
#import "ViewerViewController.h"

@interface QRViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>

@property (strong, nonatomic) IBOutlet UIView *informationBar;
@property (strong, nonatomic) IBOutlet UILabel *labelStatus;
@property (strong, nonatomic) IBOutlet UIButton *openQRbutton;

@property (strong, nonatomic) IBOutlet UIView *viewPreview;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic, strong) ShapeView *boundingBox;

@end
