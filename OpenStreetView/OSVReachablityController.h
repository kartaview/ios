//
//  OSVReachablilityController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 14/12/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSVReachablityController : NSObject

+ (BOOL)checkReachablility;
+ (BOOL)hasWiFiAccess;
+ (BOOL)hasCellularAcces;

@end
