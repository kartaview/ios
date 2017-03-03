//
//  OSVGamificationInfo.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 22/11/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSVGamificationInfo : NSObject

@property (nonatomic, assign) double    totalPoints;

@property (nonatomic, assign) double    regionTotalPoints;
@property (nonatomic, assign) NSInteger regionRank;
@property (nonatomic, strong) NSString  *regionCode;

@property (nonatomic, assign) NSInteger level;
@property (nonatomic, assign) NSInteger levelPoints;
@property (nonatomic, assign) NSInteger totalLevelPoints;
@property (nonatomic, strong) NSString  *levelName;

@property (nonatomic, assign) NSInteger rank;

@end
