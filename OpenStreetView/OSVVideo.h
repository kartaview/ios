//
//  OSVVideo.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 13/05/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSVVideo : NSObject

//upload id
@property (assign, nonatomic) NSInteger uid;
@property (assign, nonatomic) NSInteger videoIndex;

@property (strong, nonatomic) NSString  *videoPath;

@end
