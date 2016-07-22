//
//  OSVSectionItem.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSVSectionItem : NSObject

@property (strong, nonatomic) NSString          *title;
@property (strong, nonatomic) NSMutableArray    *rowItems;
@property (assign, nonatomic) NSString          *key;

@property (copy, nonatomic) void (^action)(id sender, id info);

@end
