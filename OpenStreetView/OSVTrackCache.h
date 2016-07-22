//
//  OSVTrackCache.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSVSequence.h"
#import "OSVBoundingBox.h"

@interface OSVTrackCache : NSObject

- (void)cacheLevelOneID:(NSInteger)trackID;
- (void)removeLevelOneID:(NSInteger)trackID;
- (void)moveCacheLevelOneToLevelTwo;
- (NSArray *)clearLevelOneCache;
- (NSArray *)clearLevelTwoCache;
- (NSArray *)allCachedIDs;
- (void)resetCacheToIDs:(NSArray *)allIDs;

@end
