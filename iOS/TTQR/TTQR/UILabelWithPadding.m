//
//  UILabel+UILabelWithPadding.m
//  TTQR
//
//  Created by Andrés Ruiz on 30/03/14.
//  Copyright (c) 2014 tratamientodeimagen. All rights reserved.
//

#import "UILabelWithPadding.h"

@implementation UILabelWithPadding

@synthesize edgeInsets;

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.edgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.edgeInsets)];
}

@end
