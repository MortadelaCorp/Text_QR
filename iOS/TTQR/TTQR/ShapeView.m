//
//  ShapeView.m
//  TTQR
//
//  Created by Andrés Ruiz on 26/03/14.
//  Copyright (c) 2014 tratamientodeimagen. All rights reserved.
//

#import "ShapeView.h"

@interface ShapeView () {
    
    CAShapeLayer *_outline;
}
@end

@implementation ShapeView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        _outline = [CAShapeLayer new];
        _outline.strokeColor = [[[UIColor greenColor] colorWithAlphaComponent:0.8] CGColor];
        _outline.lineWidth = 4.0;
        _outline.fillColor = [[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.7] CGColor];
        [self.layer addSublayer:_outline];
    }
    return self;
}

- (void)setCorners:(NSArray *)corners
{
    if (corners != _corners) {
        _corners = corners;
        _outline.path = [[self createPathFromPoints:corners] CGPath];
    }
}

- (UIBezierPath *)createPathFromPoints:(NSArray *)points
{
    UIBezierPath *path = [UIBezierPath new];
    
    [path moveToPoint:[[points firstObject] CGPointValue]];
    
    for (NSUInteger i = 1; i < [points count]; i++) {
        [path addLineToPoint:[points[i] CGPointValue]];
    }
    
    [path addLineToPoint:[[points firstObject] CGPointValue]];
    
    return path;
}

@end
