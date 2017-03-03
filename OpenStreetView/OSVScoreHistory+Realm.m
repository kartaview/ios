//
//  OSVScoreHistory+Realm.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 21/11/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVScoreHistory+Realm.h"
#import "RLMScoreHistory.h"

@interface OSVScoreHistory ()

@property (nonatomic, strong) NSString *scoreHistoryID;

@end

@implementation OSVScoreHistory (Realm)

- (RLMScoreHistory *)toRealmObject {
    
    RLMScoreHistory *history    = [[RLMScoreHistory alloc] init];
    history.scoreHistoryID      = self.scoreHistoryID;
    history.localSequenceID     = self.localSequenceID;
    history.coverage            = self.coverage;
    history.photos              = self.photos;
    history.photosWithOBD       = self.photosWithOBD;
    history.detectedSigns       = self.detectedSigns;

    return history;
}

+ (OSVScoreHistory *)fromRealmObject:(RLMScoreHistory *)historyObject {
    OSVScoreHistory *history    = [OSVScoreHistory new];
    history.scoreHistoryID      = historyObject.scoreHistoryID;
    history.localSequenceID     = historyObject.localSequenceID;
    history.coverage            = historyObject.coverage;
    history.photos              = historyObject.photos;
    history.photosWithOBD       = historyObject.photosWithOBD;
    history.detectedSigns       = historyObject.detectedSigns;

    return history;
}


@end
