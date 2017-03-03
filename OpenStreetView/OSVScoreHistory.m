//
//  OSVScoreHistory.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 15/11/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVScoreHistory.h"

@interface OSVScoreHistory ()

@property (nonatomic, strong) NSString *scoreHistoryID;

@end

@implementation OSVScoreHistory

- (instancetype)initForCoverage:(NSInteger)coverage withLocalSequenceID:(NSInteger)seqID {
    self = [super init];
    if (self) {
        self.localSequenceID = seqID;
        self.coverage = coverage;
        self.scoreHistoryID = [NSString stringWithFormat:@"%ld%ld", seqID, coverage];
        self.photos = 0;
        self.photosWithOBD = 0;
        self.detectedSigns = 0;
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary {
    return @{@"coverage"        : @(self.coverage),
             @"photo"           : @(self.photos),
             @"obdPhoto"        : @(self.photosWithOBD),
             @"detectedSigns"   : @(self.detectedSigns)};
}

@end
