//
//  OSVPhoto+Convertor.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 18/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVServerPhoto.h"

@interface OSVServerPhoto (Convertor)

+ (OSVServerPhoto *)photoFromDictionary:(NSDictionary *)photoDictionary;
+ (OSVServerPhoto *)photoFromPhoto:(OSVPhoto *)photo;

@end
