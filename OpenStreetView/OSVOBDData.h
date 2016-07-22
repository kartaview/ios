//
//  OSVOBDData.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/03/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSVOBDData : NSObject

//km/h
@property (assign, nonatomic)   double          speed;
@property (assign, nonatomic)   double          rpm;

@property (assign, nonatomic) NSTimeInterval    timestamp;

@end
