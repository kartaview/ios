//
//  OSVCamView.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 27/04/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVCamView.h"

@implementation OSVCamView

//capture toches outside the current view
- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event {
    return CGRectContainsPoint(self.window.frame, point);
}

@end
