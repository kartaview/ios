//
//  OSVScoreHistory+Realm.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 21/11/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVScoreHistory.h"
#import "RLMScoreHistory.h"

@interface OSVScoreHistory (Realm)

- (RLMScoreHistory *)toRealmObject;
+ (OSVScoreHistory *)fromRealmObject:(RLMScoreHistory *)historyObject;

@end
