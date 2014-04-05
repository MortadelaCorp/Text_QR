//
//  IntroViewController.m
//  TTQR
//
//  Created by Andrés Ruiz on 26/03/14.
//  Copyright (c) 2014 tratamientodeimagen. All rights reserved.
//

#import "QRViewController.h"

@interface QRViewController () {
    
    NSString *_decodedText;
    RECEIVED_DATA_TYPE decodedTextType;
    UILabelWithPadding *_label;
    NSTimer *_qrAliveTime;
    
    BOOL animationEnded;
    BOOL secondAnimationEnded;
    
    CGRect originalStatusLabelFrame;
}
@end

@implementation QRViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _captureSession = nil;
    
    _boundingBox = [[ShapeView alloc] initWithFrame:self.view.bounds];
    _boundingBox.backgroundColor = [UIColor clearColor];
    _boundingBox.hidden = YES;
    [self.view addSubview:_boundingBox];
    
    _label = [[UILabelWithPadding alloc] initWithFrame:self.view.bounds];
    _label.adjustsFontSizeToFitWidth = YES;
    _label.font = [UIFont fontWithName:@"Helvetica" size:24];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.numberOfLines = 10;
    _label.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    _label.textColor = [UIColor whiteColor];
    _label.layer.cornerRadius = 20;
    _label.layer.masksToBounds = YES;
    _label.alpha = 0;
    [self.view addSubview:_label];
    
    originalStatusLabelFrame = _informationBar.frame;
    
    animationEnded = YES;
    secondAnimationEnded = YES;
}

- (void)viewWillAppear:(BOOL)animated{
    NSLog(@"QR view will appear");
    
    _informationBar.frame = CGRectMake(_informationBar.frame.origin.x, _informationBar.frame.origin.y + _informationBar.frame.size.height, _informationBar.frame.size.width, _informationBar.frame.size.height);
    _informationBar.alpha = 0;
    
    // Restart QR reading
    [self startReadingQR];
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"QR view did appear");
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"QR view will disappear");
    
    // Stop QR reading
    [_captureSession stopRunning];
}

- (void)viewDidDisappear:(BOOL)animated {
    NSLog(@"QR view did disappear");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
        [_captureSession addInput:input];
        
        
        AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
        [_captureSession addOutput:captureMetadataOutput];
        
        dispatch_queue_t dispatchQueue;
        dispatchQueue = dispatch_queue_create("QRqueue", NULL);
        [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
        [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
        
        _videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
        [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [_videoPreviewLayer setFrame:self.view.bounds];
        _videoPreviewLayer.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
        [_viewPreview.layer addSublayer:_videoPreviewLayer];
    }
    [_captureSession startRunning];
    
    return YES;
}

// QR delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    if ([metadataObjects count] > 0) {
        
        for (AVMetadataObject *metadata in metadataObjects) {
            
            if([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
                
                // Como tenemos que actualizar la GUI, pasamos la operación al thread principal
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    
                    if (animationEnded) {
                        
                        // Sacamos el contenido del QR
                        AVMetadataMachineReadableCodeObject *transformed = (AVMetadataMachineReadableCodeObject *)[_videoPreviewLayer transformedMetadataObjectForMetadataObject:metadata];
                        
                        _decodedText = [transformed stringValue];
                        
                        if (_decodedText) {
                            NSDataDetector *detect = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink error:nil];
                            NSArray *matches = [detect matchesInString:_decodedText options:0 range:NSMakeRange(0, [_decodedText length])];
                            
                            if ([matches count] > 0) {
                                _labelStatus.text = @"Contenido: Enlace Web";
                                _label.backgroundColor = [UIColor colorWithRed:75.0/256 green:140.0/256 blue:240.0/256 alpha:0.7];
                                _label.textColor = [UIColor whiteColor];
                                _label.shadowColor = [UIColor colorWithWhite:0.5 alpha:0.7];
                                _label.shadowOffset = CGSizeMake(1, 1);
                                
                                decodedTextType = URL;
                            }
                            else if ([_decodedText length] > 0) {
                                _labelStatus.text = @"Contenido: Texto plano";
                                _label.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
                                _label.textColor = [UIColor whiteColor];
                                _label.shadowColor = [UIColor colorWithWhite:0.5 alpha:0.7];
                                _label.shadowOffset = CGSizeMake(1, 1);
                                
                                decodedTextType = TEXT;
                            }
                            _openQRbutton.enabled = YES;
                        }
                        else {
                            _labelStatus.text = @"QR con formato desconocido";
                            _label.backgroundColor = [UIColor colorWithRed:240.0/256 green:100.0/256 blue:120.0/256 alpha:0.7];
                            _label.textColor = [UIColor whiteColor];
                            _label.shadowColor = [UIColor colorWithWhite:0.5 alpha:0.7];
                            _label.shadowOffset = CGSizeMake(1, 1);
                            
                            _openQRbutton.enabled = NO;
                        }
                        
                        // Invalidamos el timer que oculta el label
                        if (_qrAliveTime != nil)
                        {
                            [_qrAliveTime invalidate];
                            _qrAliveTime = nil;
                        }
                        
                        // Animación para mover el label que tapa al QR y la barra de información
                        [UIView animateWithDuration:0.25
                                              delay: 0.0
                                            options: UIViewAnimationOptionCurveLinear
                                         animations:^{
                                             
                                             animationEnded = NO;
                                             
                                             
                                             _boundingBox.frame = transformed.bounds;
                                             _boundingBox.hidden = YES;
                                             
                                             NSArray *translatedCorners = [self translatePoints:transformed.corners fromView:_viewPreview toView:_boundingBox];
                                             
                                             _boundingBox.corners = translatedCorners;
                                             
                                             if (!_decodedText)
                                                 _label.text = @"QR con formato desconocido";
                                             else
                                                 _label.text = _decodedText;
                                             _informationBar.frame = originalStatusLabelFrame;
                                             _informationBar.alpha = 0.95;
                                             
                                             // Inclinamos el texto según la inclinación del QR
                                             CGPoint endPoint = [translatedCorners[1] CGPointValue];
                                             CGPoint startPoint = [translatedCorners[0] CGPointValue];
                                             float angleVal = atan2((endPoint.x - startPoint.x) , (endPoint.y - startPoint.y));
                                             _label.transform = CGAffineTransformMakeRotation(-angleVal);
                                             
                                             // Movemos el label que se pone sobre el QR
                                             _label.bounds = CGRectMake(_boundingBox.bounds.origin.x, _boundingBox.bounds.origin.y, _boundingBox.bounds.size.width * 1.1, _boundingBox.bounds.size.height * 1.1);
                                             _label.center = CGPointMake(_boundingBox.center.x, _boundingBox.center.y * 1.1);
                                             _label.hidden = NO;
                                             _label.alpha = 1.0;
                                             _label.layer.cornerRadius = _label.bounds.size.width/10.0;
                                             _label.edgeInsets = UIEdgeInsetsMake(_label.bounds.size.width/10.0, _label.bounds.size.width/10.0, _label.bounds.size.width/10.0, _label.bounds.size.width/10.0);
                                             [self.view bringSubviewToFront:_informationBar];
                                         }
                                         completion:^(BOOL finished){
                                             animationEnded = YES;
                                             
                                             // Timer para ocultar el label si hace tiempo que no se refresca
                                             _qrAliveTime = [NSTimer scheduledTimerWithTimeInterval:(0.5)
                                                                                             target: self
                                                                                           selector:@selector(onTimer)
                                                                                           userInfo: nil repeats: NO];
                                         }];
                    }
                }];
            }
        }
    }
}

// Selector que oculta de forma animada el label cuando ya no hay QR
- (void)onTimer
{
    [UIView animateWithDuration: 0.5
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         _label.alpha = 0.0;
                         _informationBar.frame = CGRectMake(_informationBar.frame.origin.x, _informationBar.frame.origin.y + _informationBar.frame.size.height, _informationBar.frame.size.width, _informationBar.frame.size.height);
                         _informationBar.alpha = 0.0;
                         _labelStatus.text = @"";
                     }
                     completion:nil];
}

- (NSArray *)translatePoints:(NSArray *)points fromView:(UIView *)fromView toView:(UIView *)toView
{
    NSMutableArray *translatedPoints  = [NSMutableArray new];
    
    for(NSDictionary *point in points) {
        CGPoint pointValue = CGPointMake([point[@"X"] floatValue],
                                         [point[@"Y"] floatValue]);
        CGPoint translatedPoint = [fromView convertPoint:pointValue toView:toView];
        
        [translatedPoints addObject:[NSValue valueWithCGPoint:translatedPoint]];
        
    }
    
    return [translatedPoints copy];
}

// Para pasar datos de esta vista a la vista modal al pulsar el boton de Abrir QR
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"viewer"]) {        
        ViewerViewController *viewerViewController = segue.destinationViewController;
        viewerViewController.receivedData = _decodedText;
        viewerViewController.receivedDataType = decodedTextType;
    }
}

@end
