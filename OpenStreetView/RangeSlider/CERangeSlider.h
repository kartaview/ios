//
//  CERangeSlider.h
//  CERangeSlider
//
//  Created by Colin Eberhardt on 22/03/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CERangeSlider : UIControl

@property (nonatomic) float maximumValue;

@property (nonatomic) float minimumValue;

@property (nonatomic) float upperValue;

@property (nonatomic) float lowerValue;

@property (nonatomic) float curvatiousness;

@property (nonatomic) UIColor *trackColour;

@property (nonatomic) UIColor *trackHighlightColour;

@property (nonatomic) UIColor *knobColour;

- (float)positionForValue:(float)value;

@end
