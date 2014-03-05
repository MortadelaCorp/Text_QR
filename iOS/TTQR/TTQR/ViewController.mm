//
//  ViewController.m
//  TTQR
//
//  Created by Andrés Ruiz on 19/02/14.
//  Copyright (c) 2014 tratamientodeimagen. All rights reserved.
//

#import "ViewController.h"
#import <Accelerate/Accelerate.h>

@interface ViewController () {
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _captureSession = nil;
    _tesseract = nil;

    
    // OCR

    
    //[self recognizeImageWithTesseract:[UIImage imageNamed:@"image_sample.jpg"]];
    
    [self startReadingOCR]; //ESTO lo debe lanzar un botón en realidad
}

-(void)recognizeImageWithTesseract:(UIImage *)img
{
    dispatch_async(dispatch_get_main_queue(), ^{
		//[self.activityIndicator startAnimating];
	});
    
    [_tesseract setVariableValue:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;_'-()%$€#@?¿!¡" forKey:@"tessedit_char_whitelist"]; //limit search
    [_tesseract setImage:img]; //image to check
    [_tesseract recognize];
    
    NSString *recognizedText = [_tesseract recognizedText];
    
    NSLog(@"%@", recognizedText);
    
    dispatch_async(dispatch_get_main_queue(), ^{
		//[self.activityIndicator stopAnimating];
        
        _labelStatus.text = recognizedText;
        
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tesseract OCR iOS" message:recognizedText delegate:nil cancelButtonTitle:@"Yeah!" otherButtonTitles:nil];
        //[alert show];
        
    });
    
    //tesseract = nil; //deallocate and free all memory
}

- (BOOL)shouldCancelImageRecognitionForTesseract:(Tesseract*)tesseract {
    NSLog(@"progress: %d", tesseract.progress);
    return YES;  // return YES, if you need to interrupt tesseract before it finishes
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)startReadingOCR
{
    // Instanciamos Tesseract para el OCR
    if (!_tesseract)
        _tesseract = [[Tesseract alloc] initWithLanguage:@"eng"];
    
    // Instanciamos openCV para capturar la imagen
    _videoCamera = [[CvVideoCamera alloc] initWithParentView:_ocrImageView];
    _videoCamera.delegate = self;
    
    _videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack; // Cámara frontal o trasera
    _videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288; // Tamaño del frame
    _videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait; // Orientación
    _videoCamera.defaultFPS = 30; // FPS
    _videoCamera.grayscaleMode = YES; // Escala de grises
    _ocrImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);

    
    [_videoCamera setRotateVideo:YES];
    [_videoCamera start];
    return YES;
}

- (BOOL)startReadingQR
{
    NSError *error;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession addInput:input];
    
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
     [_captureSession addOutput:captureMetadataOutput];
     
     dispatch_queue_t dispatchQueue;
     dispatchQueue = dispatch_queue_create("myQueue", NULL);
     [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
     [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:_viewPreview.layer.bounds];
    [_viewPreview.layer addSublayer:_videoPreviewLayer];
    
    [_captureSession startRunning];
    
    return YES;
}

// OCR opencv
#ifdef __cplusplus
- (void)processImage:(Mat &)image
{
    // Creamos una copia de la imagen a procesar
    
    //Mat image_copy;
    //cvtColor(image, image_copy, CV_GRAY2BGR); // Para cambiar de espacio de color
    Mat new_image = Mat::zeros(image.size(), image.type());
    
    
    // La tratamos
    
    
    // Subimos contraste y brillo
    /*double contrast = 2.0;
    int brightness = 30;
    
    for (int i = 0; i < image.rows; i++) {
        for (int j = 0; j < image.cols; j++) {
         
            image.at<uchar>(i, j) = saturate_cast<uchar>(contrast*(image.at<uchar>(i, j))+brightness);
        }
    }
     */
    
    
    // transformamos las zonas de texto en "blobs"
    // Para ello -> cvMorphologyEx -> cvThreshold (blanco y negro) -> cvSmooth (difuminar) -> cvDilate (formar el blob final)
    Mat img = image;
    
    Mat img_temp = Mat::zeros(image.size(), image.type());

    cv::morphologyEx(img, img, CV_MOP_TOPHAT, cv::getStructuringElement(CV_SHAPE_RECT, cv::Size(21, 3)));
    //cvMorphologyEx(&img, &img, &img_temp, cvCreateStructuringElementEx(21, 3, 10, 2, CV_SHAPE_RECT, NULL), CV_MOP_TOPHAT, 1);
    cv::threshold(img, img, 100, 255, CV_THRESH_BINARY);
    
    cv::GaussianBlur(img, img, cv::Size(5,5), cv::BORDER_CONSTANT); //cvSmooth();
    
    cv::dilate(img, img, cv::getStructuringElement(CV_SHAPE_RECT, cv::Size(21, 3)));
    cv::dilate(img, img, cv::getStructuringElement(CV_SHAPE_RECT, cv::Size(21, 3)));
    
    // Detectamos bordes
    //cvCanny(&tmp, &tmp, 50.0, 300.0);
    cv::Canny(img, img, 50.0, 300.0);
    
    Mat copy = img.clone();
    
    std::vector<std::vector<cv::Point> > contours;
    cv::findContours(copy, contours, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE); // Pasamos una copia de la imagen porque la sobreescribe

    // iteramos por los contornos
    // NOS HEMOS QUEDADO POR AQUIIIII -> Mirar morourl
    
    
    // Y se la pasamos al Tesseract
    
    //if((int)CACurrentMediaTime()%3==0) // Cada 3 segundos reconoce una imagen
    //[self recognizeImageWithTesseract:[ViewController UIImageFromCVMat:image]];
    
    
    // Finalmente, volcamos la copia sobre la original para verla en el preview
    
    //cvtColor(image_copy, image, CV_GRAY2BGRA);
    //image = new_image;
}
#endif

// OCR delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{

}

// QR delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            [_labelStatus performSelectorOnMainThread:@selector(setText:) withObject:[metadataObj stringValue] waitUntilDone:NO];
            
            //[self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
            //[_bbitemStart performSelectorOnMainThread:@selector(setTitle:) withObject:@"Start!" waitUntilDone:NO];
            NSLog(@"x: %f, y: %f, width: %f, height: %f", metadataObj.bounds.origin.x, metadataObj.bounds.origin.y, metadataObj.bounds.size.width, metadataObj.bounds.size.height);
        }

    }
}

// Sirve para pasar del formato que devuelve openCV (cv::Mat) a UIImage. Sacado de una web china D:
+(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    bool alpha = cvMat.channels() == 4;
    CGBitmapInfo bitMapInfo = (alpha ? kCGImageAlphaLast : kCGImageAlphaNone) | kCGBitmapByteOrderDefault;
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        bitMapInfo,                                 // bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end

// Category de UIImage para pasar a grayscale

@implementation UIImage (grayscale)

typedef enum {
    ALPHA = 0,
    BLUE = 1,
    GREEN = 2,
    RED = 3
} PIXELS;

- (UIImage *)convertToGrayscale {
    CGSize size = [self size];
    int width = size.width;
    int height = size.height;
    
    // the pixels will be painted to this array
    uint32_t *pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [self CGImage]);
    
    for(int y = 0; y < height; y++) {
        for(int x = 0; x < width; x++) {
            uint8_t *rgbaPixel = (uint8_t *) &pixels[y * width + x];
            
            // convert to grayscale using recommended method: http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale
            uint32_t gray = 0.3 * rgbaPixel[RED] + 0.59 * rgbaPixel[GREEN] + 0.11 * rgbaPixel[BLUE];
            
            // set the pixels to gray
            rgbaPixel[RED] = gray;
            rgbaPixel[GREEN] = gray;
            rgbaPixel[BLUE] = gray;
        }
    }
    
    // create a new CGImageRef from our context with the modified pixels
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    // we're done with the context, color space, and pixels
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    
    // make a new UIImage to return
    UIImage *resultUIImage = [UIImage imageWithCGImage:image];
    
    // we're done with image now too
    CGImageRelease(image);
    
    return resultUIImage;
}

@end
