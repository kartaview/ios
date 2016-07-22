//
//  OSMPersistentManager.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 15/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSVPhoto.h"
#import "OSVSequence.h"
#import "RLMBoundingBox.h"

@interface OSVPersistentManager : NSObject

+ (BOOL)hasPhotos;

+ (void)getAllSequencesWithCompletion:(void (^)(NSArray *sequences, NSInteger photosCount))completion;
+ (void)getSequencesInBox:(id<RLMBoundingBox>)box withCompletion:(void (^)(NSArray *sequences, NSInteger photosCount))completion;

+ (NSMutableArray *)getSequenceIDsInBox:(id<RLMBoundingBox>)box;
+ (OSVSequence *)getSequenceWithID:(NSInteger)sequenceID;

+ (void)storePhoto:(OSVPhoto *)photo;
+ (void)removePhoto:(OSVPhoto *)photo;
+ (void)removeSequenceWithID:(NSInteger)sequenceID;
+ (void)removePhotosWithVideoIndex:(NSInteger)videoIndex localSequenceID:(NSInteger)localSequenceID;

+ (void)updatedPhoto:(OSVPhoto *)photo withAddress:(NSString *)address;
+ (void)updatePhotosHavingLocalSequenceID:(NSInteger)sequenceID withServerID:(NSInteger)serverID;

@end
