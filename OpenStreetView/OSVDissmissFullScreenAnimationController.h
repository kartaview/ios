//
//  OSVDissmissFullScreenAnimationController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 16/06/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OSVDissmissFullScreenAnimationController : NSObject <UIViewControllerAnimatedTransitioning>

@property (assign, nonatomic) CGRect destinationFrame;

@end
