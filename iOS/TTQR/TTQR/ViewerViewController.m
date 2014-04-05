//
//  ViewerViewController.m
//  TTQR
//
//  Created by Andrés Ruiz on 30/03/14.
//  Copyright (c) 2014 tratamientodeimagen. All rights reserved.
//

#import "ViewerViewController.h"

@interface ViewerViewController () {
    UIColor *originalTintColor;
}
@end

@implementation ViewerViewController

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
    
    originalTintColor = _reloadButton.tintColor;
}

- (void)viewWillAppear:(BOOL)animated
{
    switch (self.receivedDataType) {
        case URL:
        {
            _reloadButton.enabled = YES;
            _reloadButton.tintColor = originalTintColor;
            
            _urlLabel.hidden = NO;
            _webview.hidden = NO;
            _textview.hidden = YES;
            
            _urlLabel.text = _receivedData;
            NSURL *URL = [NSURL URLWithString:_receivedData];
            NSURLRequest *requestObj = [NSURLRequest requestWithURL:URL];
            [self.webview loadRequest:requestObj];

            break;
        }
        case TEXT:
            _reloadButton.enabled = NO;
            _reloadButton.tintColor = [UIColor clearColor];
            _urlLabel.hidden = YES;
            _webview.hidden = YES;
            _textview.hidden = NO;
            
            _textview.text = _receivedData;
            _textview.font = [UIFont fontWithName:@"Helvetica" size:22];
            
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)reloadWeb:(id)sender {
    [self.webview reload];
}

- (IBAction)dismissView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
