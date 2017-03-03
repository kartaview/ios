//
//  OSVServerSequence.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 20/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSVSequence.h"

@interface OSVServerSequence : NSObject <OSVSequence>

@property (nonatomic, strong) NSString  *countryCode;
@property (nonatomic, strong) NSString  *clientToken;
@property (nonatomic, assign) NSInteger photoCount;
@property (nonatomic, assign) NSInteger points;
@property (nonatomic, strong) NSMutableArray   *scoreHistory;

@end


@interface OSVServerSequencePart: NSObject <OSVSequence>

@property (nonatomic, assign) CLLocationCoordinate2D    coordinate;
@property (nonatomic, assign) NSInteger                 selectedIndex;
@property (nonatomic, strong) NSString                  *author;
@property (nonatomic, assign) NSInteger                 photoCount;

@end
