//
//  ViewController.h
//  TTQR
//
//  Created by Andrés Ruiz on 19/02/14.
//  Copyright (c) 2014 tratamientodeimagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <TesseractOCR/TesseractOCR.h>
#import <opencv2/highgui/cap_ios.h>

using namespace cv;

@interface ViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, CvVideoCameraDelegate, TesseractDelegate> {
    
}

@property (strong, nonatomic) IBOutlet UIImageView *ocrImageView;

@property (strong, nonatomic) IBOutlet UIView *viewPreview;
@property (strong, nonatomic) IBOutlet UILabel *labelStatus;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;

@property (nonatomic, strong) CvVideoCamera *videoCamera;

@property (nonatomic, strong) Tesseract *tesseract;


@end
