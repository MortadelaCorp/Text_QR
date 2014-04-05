//
//  ViewController.m
//  TTQR
//
//  Created by Andrés Ruiz on 19/02/14.
//  Copyright (c) 2014 tratamientodeimagen. All rights reserved.
//

#import "OCRViewController.h"
#import <Accelerate/Accelerate.h>
#import <MBProgressHUD.h>

@interface OCRViewController () {
    
    BOOL _isShowingPhoto;
    NSString *_recognizedText;
    CGRect originalbuttonViewerRect;
}

@end

@implementation OCRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    originalbuttonViewerRect = _buttonViewer.frame;
    
    _captureSession = nil;
    _tesseract = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"OCR view will appear");
    
    // Restart OCR reading
    [self startReadingOCR];
    _isShowingPhoto = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"OCR view did appear");
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"OCR view will disappear");
    
    // Stop OCR reading
    [_videoCamera stop];
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"OCR view did disappear");
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)recognizeImageWithTesseract:(UIImage *)img
{
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        [self.activityIndicator startAnimating];
    //	});
    
    [_tesseract setVariableValue:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;_'-()%$€#@?¿!¡" forKey:@"tessedit_char_whitelist"]; //limit search
    [_tesseract setImage:img]; //image to check
    [_tesseract recognize];
    
    _recognizedText = [_tesseract recognizedText];
    
    NSLog(@"%@", _recognizedText);
    
    dispatch_async(dispatch_get_main_queue(), ^{
		//[self.activityIndicator stopAnimating];
        
    });
    
    //tesseract = nil; //deallocate and free all memory
}

- (BOOL)shouldCancelImageRecognitionForTesseract:(Tesseract*)tesseract {
    NSLog(@"progress: %d", tesseract.progress);
    return YES;  // return YES, if you need to interrupt tesseract before it finishes
}

- (BOOL)startReadingOCR
{
    // Instanciamos Tesseract para el OCR
    if (!_tesseract)
        _tesseract = [[Tesseract alloc] initWithLanguage:@"eng"];
    
    // Instanciamos openCV para capturar la imagen
    if (!_videoCamera) {
        _videoCamera = [[CvPhotoCamera alloc] initWithParentView:_ocrImageView];
        _videoCamera.delegate = self;
        
        _videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack; // Cámara frontal o trasera
        _videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720; // Tamaño del frame
        _videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait; // Orientación
        _videoCamera.defaultFPS = 30; // FPS
    }
    
    [_videoCamera start];
    return YES;
}

// OCR opencv
#ifdef __cplusplus
- (void)processImage:(Mat &)image
{
    
    NSLog(@"processImage ******************");
    
    // Creamos una copia de la imagen a procesar
    
    Mat img = image.clone();
    
    //Mat image_copy;
    cvtColor(image, img, CV_BGR2GRAY); // Para cambiar de espacio de color a grises
    //Mat new_image = Mat::zeros(image.size(), image.type());
    
    
    // Subimos contraste y brillo
    double contrast = 2.0;
    int brightness = 30;
    
    for (int i = 0; i < img.rows; i++) {
        for (int j = 0; j < img.cols; j++) {
            
            img.at<uchar>(i, j) = saturate_cast<uchar>(contrast*(img.at<uchar>(i, j))+brightness);
        }
    }
    
    // transformamos las zonas de texto en "blobs"
    // Para ello -> cvMorphologyEx -> cvThreshold (blanco y negro) -> cvSmooth (difuminar) -> cvDilate (formar el blob final)
    //Mat img = image;
    
    //Mat img_temp = Mat::zeros(image.size(), image.type());
    
    cv::morphologyEx(img, img, CV_MOP_TOPHAT, cv::getStructuringElement(CV_SHAPE_RECT, cv::Size(30, 7)));
    //cvMorphologyEx(&img, &img, &img_temp, cvCreateStructuringElementEx(21, 3, 10, 2, CV_SHAPE_RECT, NULL), CV_MOP_TOPHAT, 1);
    cv::threshold(img, img, 100, 255, CV_THRESH_BINARY);
    
    cv::GaussianBlur(img, img, cv::Size(5,5), cv::BORDER_CONSTANT); //cvSmooth();
    
    cv::dilate(img, img, cv::getStructuringElement(CV_SHAPE_RECT, cv::Size(30, 7)));
    cv::dilate(img, img, cv::getStructuringElement(CV_SHAPE_RECT, cv::Size(30, 7)));
    cv::dilate(img, img, cv::getStructuringElement(CV_SHAPE_RECT, cv::Size(30, 7)));
    cv::dilate(img, img, cv::getStructuringElement(CV_SHAPE_RECT, cv::Size(30, 7)));
    
    
    // Detectamos bordes
    cv::Canny(img, img, 45.0, 50.0);
    
    // DEBUG: PARA VER EL PROCESAMIENTO. Comentar después
    //image = img.clone();
    
    
    //Mat copy = img.clone();
    
    std::vector<std::vector<cv::Point> > contours;
    
    cv::findContours(img, contours, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE); // Pasamos una copia de la imagen porque la sobreescribe
    //NSLog(@"size %lu", contours.size());
    
    // iteramos por los contornos
    for(int i = 0; i < contours.size(); i++) {
        //NSLog(@"Size contours[%i] = %lu", i, contours[i].size());
        
        if (contours[i].size() >= 50) {
            cv::Rect rectangle = cv::boundingRect(contours[i]);//findRectangleContaining(contours[i]);
            
            if (rectangle.width > 40 && rectangle.height > 20) {
                cv::Point pt1, pt2;
                pt1.x = rectangle.x;
                pt1.y = rectangle.y;
                pt2.x = rectangle.x + rectangle.width;
                pt2.y = rectangle.y + rectangle.height;
                cv::rectangle(image, pt1, pt2, CV_RGB(0, 255, 0), 4);
            }
        }
    }
    // Posteriormente se la pasamos al tesseract (en la acción del botón)
}

#endif

// OpenCV photoCameraDelegates
- (void)photoCamera:(CvPhotoCamera *)photoCamera capturedImage:(UIImage *)image
{
    NSLog(@"PHOTO CAMERA DELEGATE");
    
    // Paramos la cámara
    [_videoCamera stop];
    
    // Pasamos la imagen a Mat, que es el formato con el que trabaja OpenCV
    Mat img = [self cvMatFromUIImage:image];
    
    // Rectificamos el giro para que esté vertical
    rotate(img, -90, img);
    
    _ocrImageView.image = [self UIImageFromCVMat:img]; // Preview
    
    // Procesamos la imagen
    [self processImage:img];
    
    UIImage *imagenCapturada = [self UIImageFromCVMat:img]; // Imagen ya procesada
    
    // Mostramos la imagen procesada
    _ocrResultImageView.image = imagenCapturada;
    _ocrResultImageView.hidden = NO;
    //_ocrResultImageView.alpha = 0.5;
}

- (void)photoCameraCancel:(CvPhotoCamera *)photoCamera
{
    NSLog(@"CANCEL PHOTO CAMERA");
}

// OCR delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
}

- (IBAction)touchScreen:(id)sender {
    
    if (_isShowingPhoto) {
        _isShowingPhoto = NO;
        _ocrResultImageView.hidden = YES;
        [_videoCamera start];
    }
    else {
        NSLog(@"Tomamos una foto");
        _isShowingPhoto = YES;
        
        [_videoCamera takePicture];

        [UIView animateWithDuration: 0.5
                              delay: 0.0
                            options: UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             _buttonViewer.frame = originalbuttonViewerRect;
                             _buttonViewer.alpha = 1.0;
                         }
                         completion:nil];
    }
}

// Para pasar datos de esta vista a la vista modal al pulsar el boton de Abrir QR
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"viewer"]) {
        
        // Mostramos un spinner mientras carga
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];

        // Y se la pasamos al Tesseract
        [self recognizeImageWithTesseract:_ocrResultImageView.image];
        
        // Ocultar el spinner
        [MBProgressHUD hideHUDForView:self.view animated:YES];

        // Abrimos un visor en una vista modal
        ViewerViewController *viewerViewController = segue.destinationViewController;
        viewerViewController.receivedData = _recognizedText;
        viewerViewController.receivedDataType = TEXT;
        _isShowingPhoto = NO;
        
        [UIView animateWithDuration: 0.5
                              delay: 0.0
                            options: UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             _buttonViewer.frame = CGRectMake(_buttonViewer.frame.origin.x, _buttonViewer.frame.origin.y + _buttonViewer.frame.size.height, _buttonViewer.frame.size.width, _buttonViewer.frame.size.height);
                             _buttonViewer.alpha = 0.0;
                         }
                         completion:nil];
    }
}

// Métodos auxiliares de OpenCV para convertir entre UIImage y cv::Mat
- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
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

// Para girar un mat
void rotate(cv::Mat& src, double angle, cv::Mat& dst)
{
    int len = std::max(src.cols, src.rows);
    cv::Point2f pt(len/2., len/2.);
    cv::Mat r = cv::getRotationMatrix2D(pt, angle, 1.0);
    
    cv::warpAffine(src, dst, r, cv::Size(src.rows, src.cols));
}

@end
