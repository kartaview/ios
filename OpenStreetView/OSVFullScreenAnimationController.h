//
//  OSVFullScreenAnimationController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 16/06/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol OSVPlayer;

@interface OSVFullScreenAnimationController : NSObject <UIViewControllerAnimatedTransitioning>

@property (assign, nonatomic) CGRect originFrame;
@property (assign, nonatomic) CGRect fullScreeFrame;
@property (strong, nonatomic) id<OSVPlayer> player;

@end
