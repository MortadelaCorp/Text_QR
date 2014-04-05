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
#import "ViewerViewController.h"

using namespace cv;

@interface OCRViewController : UIViewController < AVCaptureVideoDataOutputSampleBufferDelegate, CvPhotoCameraDelegate, TesseractDelegate> {
    
}

@property (strong, nonatomic) IBOutlet UIImageView *ocrImageView;
@property (strong, nonatomic) IBOutlet UIImageView *ocrResultImageView;

@property (strong, nonatomic) IBOutlet UILabel *labelStatus;
@property (strong, nonatomic) IBOutlet UIButton *buttonViewer;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
//@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;

@property (nonatomic, strong) CvPhotoCamera *videoCamera;

@property (nonatomic, strong) Tesseract *tesseract;

- (IBAction)touchScreen:(id)sender;

@end
