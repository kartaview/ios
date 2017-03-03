//
//  OSVSyncUtils.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OSVSequence, OSVPhoto;

@class OSVPhoto;

@interface OSVSyncUtils : NSObject

+ (BOOL)hasInternetPermissions;

+ (long long)sizeOnDiskForSequence:(id<OSVSequence>)sequence atPath:(NSString *)path;
+ (long long)sizeOnDiskForSequence:(id<OSVSequence>)sequence atPath:(NSString *)path containsImages:(BOOL *)contains;
+ (long long)sizeOnDiskForPhoto:(id<OSVPhoto>)photo atPath:(NSString *)path;
+ (long long)sizeOnDiskForSequencesAtPath:(NSString *)path;

+ (BOOL)removeTrackWithID:(NSInteger)seqID atPath:(NSString *)path;
+ (BOOL)removeVideoAtPath:(NSString *)path;

+ (NSArray *)getFolderNamesAtPath:(NSString *)path;
@end
