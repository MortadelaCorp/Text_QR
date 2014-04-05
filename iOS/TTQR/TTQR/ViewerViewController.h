//
//  ViewerViewController.h
//  TTQR
//
//  Created by Andrés Ruiz on 30/03/14.
//  Copyright (c) 2014 tratamientodeimagen. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    URL,
    TEXT,
    LOCATION,
    CONTACT,
    PAYPAL
}RECEIVED_DATA_TYPE;

@interface ViewerViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIWebView *webview;
@property (nonatomic, strong) NSString *receivedData;
@property (nonatomic, assign) RECEIVED_DATA_TYPE receivedDataType;
@property (strong, nonatomic) IBOutlet UILabel *urlLabel;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *reloadButton;
@property (strong, nonatomic) IBOutlet UITextView *textview;

- (IBAction)reloadWeb:(id)sender;

- (IBAction)dismissView:(id)sender;

@end
