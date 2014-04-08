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
    CGRect _originalbuttonViewerRect;
    UIImage *_imageForTesseract;
}

@end

@implementation OCRViewController

#pragma mark -

#pragma mark ViewController delegates:

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _originalbuttonViewerRect = _buttonViewer.frame;
    
    _captureSession = nil;
    _tesseract = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"OCR view will appear");
    
    // Restart OCR reading
    [self startReadingOCR];
    _isShowingPhoto = NO;
    _ocrResultImageView.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"OCR view did appear");
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"OCR view will disappear");
    
    // Stop OCR reading
    [_opencvPhotoCamera stop];
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

#pragma mark -

#pragma mark IBActions:

- (IBAction)touchScreen:(id)sender {
    
    // Al tocar la pantalla...
    // Si estaba mostrando la foto anterior, la descartamos y reiniciamos la cámara
    if (_isShowingPhoto) {
        _isShowingPhoto = NO;
        _ocrResultImageView.hidden = YES;
        [_opencvPhotoCamera start];
    }
    // Si ya estaba en modo cámara, tomamos una foto
    else {
        _isShowingPhoto = YES;
        
        [_opencvPhotoCamera takePicture]; // Esto llama al delegate photoCamera:capturedImage
    }
}

// Para pasar datos de esta vista a la vista modal al pulsar el boton de Ver Texto Reconocido
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"viewer"]) {
        
        // Abrimos un visor en una vista modal
        ViewerViewController *viewerViewController = segue.destinationViewController;
        viewerViewController.receivedData = _recognizedText;
        viewerViewController.receivedDataType = TEXT;
        _isShowingPhoto = NO;
        
        
        // Mostramos un spinner mientras pasamos el Tesseract, que tarda bastante
        [MBProgressHUD showHUDAddedTo:viewerViewController.view animated:YES];
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            
            // Pasamos el Tesseract
            [self recognizeImageWithTesseract:_imageForTesseract];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                viewerViewController.receivedData = _recognizedText;
                [viewerViewController viewWillAppear:NO];
                _recognizedText = @"";
                [MBProgressHUD hideHUDForView:viewerViewController.view animated:YES];
            });
        });
        
        
        // Ocultamos el botón del visor de texto reconocido
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

#pragma mark -

#pragma mark Tesseract:

// Tesseract
- (BOOL)startReadingOCR
{
    // Instanciamos Tesseract para el OCR
    if (!_tesseract)
        _tesseract = [[Tesseract alloc] initWithLanguage:@"eng"];
    
    // Instanciamos openCV para capturar la imagen
    if (!_opencvPhotoCamera) {
        _opencvPhotoCamera = [[CvPhotoCamera alloc] initWithParentView:_ocrImageView];
        _opencvPhotoCamera.delegate = self;
        
        _opencvPhotoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack; // Cámara frontal o trasera
        _opencvPhotoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480; // Tamaño del frame
        _opencvPhotoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait; // Orientación
        _opencvPhotoCamera.defaultFPS = 30; // FPS
    }
    
    [_opencvPhotoCamera start];
    return YES;
}

-(void)recognizeImageWithTesseract:(UIImage *)img
{
//    dispatch_async(dispatch_get_main_queue(), ^{
//          [self.activityIndicator startAnimating];
//    });
    
    [_tesseract setVariableValue:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'()@?!" forKey:@"tessedit_char_whitelist"]; //limit search
    [_tesseract setImage:img]; //image to check
    [_tesseract recognize];
    
    _recognizedText = [_tesseract recognizedText];
    
    NSLog(@"%@", _recognizedText);
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.activityIndicator stopAnimating];
//        
//    });
    
    //tesseract = nil; //deallocate and free all memory
}

- (BOOL)shouldCancelImageRecognitionForTesseract:(Tesseract*)tesseract {
    NSLog(@"progress: %d", tesseract.progress);
    return YES;  // return YES, if you need to interrupt tesseract before it finishes
}

#pragma mark -

#pragma mark OpenCV:

// OpenCV
#ifdef __cplusplus
- (void)processImage:(Mat &)image imageForTesseract:(Mat &)imageForTesseract
{
    
    // Este tratamiento de la imagen es para detectar dónde está el texto, no para mejorar su reconocimiento OCR posterior
    NSLog(@"*** [OpenCV - ProcessImage:]");
    
    // Creamos una copia de la imagen a procesar
    Mat img = image.clone();
    cvtColor(image, img, CV_BGR2GRAY); // Para cambiar de espacio de color a grises
    
    // Subimos contraste y brillo
    double contrast = 2.0;
    int brightness = 30;
    
    for (int i = 0; i < img.rows; i++)
        for (int j = 0; j < img.cols; j++)
            img.at<uchar>(i, j) = saturate_cast<uchar>(contrast*(img.at<uchar>(i, j))+brightness);
    
    // Si es para Tesseract, el resto de procesamientos no sirven, así que sólo clonamos hasta aquí
    imageForTesseract = img.clone();
    
    // transformamos las zonas de texto en "blobs"
    Mat blobShape = cv::getStructuringElement(CV_SHAPE_RECT, cv::Size(30, 7));
    int dilateLevel = 4;
    cv::morphologyEx(img, img, CV_MOP_TOPHAT, blobShape);
    cv::threshold(img, img, 100, 200, CV_THRESH_BINARY);
    cv::GaussianBlur(img, img, cv::Size(5,5), cv::BORDER_CONSTANT);
    
    for (int k = 0; k < dilateLevel; k++)
        cv::dilate(img, img, blobShape);
    
    
    // Detectamos bordes
    cv::Canny(img, img, 45.0, 50.0);
    
    std::vector<std::vector<cv::Point> > contours;
    
    cv::findContours(img, contours, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE); // Pasamos una copia de la imagen porque la sobreescribe
    
    // iteramos por los contornos
    for(int i = 0; i < contours.size(); i++) {
        
        if (contours[i].size() >= 50) {
            cv::Rect rectangle = cv::boundingRect(contours[i]);
            
            if (rectangle.width > 40 && rectangle.height > 20) {
                cv::Point pt1, pt2;
                pt1.x = rectangle.x;
                pt1.y = rectangle.y;
                pt2.x = rectangle.x + rectangle.width;
                pt2.y = rectangle.y + rectangle.height;
                cv::rectangle(image, pt1, pt2, CV_RGB(0, 255, 0), 4); // Para ver los rectángulos sobre la imagen
            }
        }
    }
}

#endif

// OpenCV photoCameraDelegates
- (void)photoCamera:(CvPhotoCamera *)photoCamera capturedImage:(UIImage *)image
{
    NSLog(@"PHOTO CAMERA DELEGATE");
    
    // Paramos la cámara
    [_opencvPhotoCamera stop];
    
    // Pasamos la imagen a Mat, que es el formato con el que trabaja OpenCV
    Mat img = [self cvMatFromUIImage:image];
    
    // Rectificamos el giro para que esté vertical
    rotate(img, -90, img);
    
    // Ponemos una preview de la foto
    _ocrImageView.image = _imageForTesseract;

    // Variable para el output para Tesseract:
    Mat imageForTesseract;
    
    // Procesamos la imagen para detectar texto (como resultado debe renderizar rectángulos encima del texto)
    [self processImage:img imageForTesseract:imageForTesseract];

    // Guardamos la imagen para Tesseract ya convertida a UIImage
    _imageForTesseract = [self UIImageFromCVMat:imageForTesseract];

    // Mostramos el botón inferior del visor de texto
    [UIView animateWithDuration: 0.5
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         _buttonViewer.frame = _originalbuttonViewerRect;
                         _buttonViewer.alpha = 1.0;
                     }
                     completion:nil];
    
    // Mostramos la imagen procesada
    _ocrResultImageView.image = [self UIImageFromCVMat:img];
    _ocrResultImageView.hidden = NO;
}

- (void)photoCameraCancel:(CvPhotoCamera *)photoCamera
{
    NSLog(@"CANCEL PHOTO CAMERA");
}

#pragma mark Compatibility OpenCV-Foundation:

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
