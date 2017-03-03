//
//  OSVScoreHistory.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 15/11/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSVScoreHistory : NSObject

@property (nonatomic, assign) NSInteger localSequenceID;
@property (nonatomic, assign) NSInteger coverage;
@property (nonatomic, assign) NSInteger photos;
@property (nonatomic, assign) NSInteger photosWithOBD;
@property (nonatomic, assign) NSInteger detectedSigns;
@property (nonatomic, assign) double    multiplier;
@property (nonatomic, assign) double    distance;
@property (nonatomic, assign) NSInteger points;

- (nonnull instancetype)initForCoverage:(NSInteger)coverage withLocalSequenceID:(NSInteger)seqID;

- (nonnull NSDictionary *)jsonDictionary;

@end
