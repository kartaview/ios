//
//  OSVTipView.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 25/04/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVTipView : UIView

@property (copy, nonatomic) void (^didDissmiss)();
@property (copy, nonatomic) BOOL (^willDissmiss)();

- (void)randomize;

- (void)configureViews;
- (void)prepareWalkthrough;
- (void)prepareIntro;

@end
