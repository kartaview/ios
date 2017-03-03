//
//  OSVPushTransition.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 11/10/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OSVPushTransition : NSObject <UIViewControllerAnimatedTransitioning>

- (instancetype)initWithoutAnimatingSource:(BOOL)animatingSource;

@end
