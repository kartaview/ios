//
//  OSVServerPhoto.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 20/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSVPhoto.h"

@interface OSVServerPhoto : NSObject <OSVPhoto>

@property (nonatomic, assign) NSInteger photoId;
@property (nonatomic, strong) NSString  *thumbnailName;

@end
