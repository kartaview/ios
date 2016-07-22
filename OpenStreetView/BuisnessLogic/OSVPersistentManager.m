//
//  OSMPersistentManager.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 15/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVPersistentManager.h"
#import <Realm/Realm.h>
#import "OSVPhoto+Relm.h"
#import "OSVUtils+Location.m"
#import "OSVVideo.h"

@implementation OSVPersistentManager

+ (BOOL)hasPhotos {
    RLMResults *results = [RLMPhoto allObjects];
    return results.count > 0;
}

#pragma mark - Get

+ (void)getAllSequencesWithCompletion:(void (^)(NSArray *sequences, NSInteger photosCount))completion {
    
    RLMResults *results = [[RLMPhoto allObjects] sortedResultsUsingProperty:@"sequenceIndex" ascending:YES];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (RLMPhoto *managedObject in results) {
        OSVPhoto *photo = [OSVPhoto fromRealmObject:managedObject];
        
        OSVSequence *localSeq = dictionary[@(photo.localSequenceId)];

        if (!localSeq) {
            localSeq            = [OSVSequence new];
            localSeq.photos     = [NSMutableArray array];
            localSeq.dateAdded  = [NSDate dateWithTimeIntervalSince1970:photo.photoData.timestamp];
            localSeq.uid        = photo.localSequenceId;
            localSeq.uploadID   = photo.serverSequenceId;
            localSeq.topLeftCoordinate      = CLLocationCoordinate2DMake(1000, -1000);
            localSeq.bottomRightCoordinate  = CLLocationCoordinate2DMake(-1000, 1000);
            localSeq.length                 = 0;
            localSeq.videos                 = [NSMutableDictionary dictionary];
            dictionary[@(photo.localSequenceId)] = localSeq;
        }
        
        if (!localSeq.videos[@(photo.photoData.videoIndex)]) {
            OSVVideo *video = [OSVVideo new];
            video.videoIndex = photo.photoData.videoIndex;
            video.uid = photo.serverSequenceId;
            
            localSeq.videos[@(photo.photoData.videoIndex)] = video;
        }
        
        if (localSeq.photos.count) {
            CLLocationCoordinate2D last = [localSeq.photos lastObject].photoData.location.coordinate;
            localSeq.length += [OSVUtils getAirDistanceBetweenCoordinate:last andCoordinate:photo.photoData.location.coordinate];
        }
        
        [localSeq.photos addObject:photo];
        
        if (photo.hasOBD) {
            localSeq.hasOBD = YES;
        }
        
        CLLocationCoordinate2D topLeftLocation = localSeq.topLeftCoordinate;
        CLLocationCoordinate2D bottomRightLocation = localSeq.bottomRightCoordinate;
        
        if (topLeftLocation.latitude > photo.photoData.location.coordinate.latitude ) {
            topLeftLocation.latitude = photo.photoData.location.coordinate.latitude;
        }
        if (topLeftLocation.longitude < photo.photoData.location.coordinate.longitude) {
            topLeftLocation.longitude = photo.photoData.location.coordinate.longitude;
        }
        
        if (bottomRightLocation.latitude < photo.photoData.location.coordinate.latitude) {
            bottomRightLocation.latitude = photo.photoData.location.coordinate.latitude;
        }
        
        if (bottomRightLocation.longitude > photo.photoData.location.coordinate.longitude) {
            bottomRightLocation.longitude = photo.photoData.location.coordinate.longitude;
        }
        
        localSeq.topLeftCoordinate = topLeftLocation;
        localSeq.bottomRightCoordinate = bottomRightLocation;
    }

    completion([dictionary allValues], results.count);
}

+ (void)getSequencesInBox:(id<RLMBoundingBox>)box withCompletion:(void (^)(NSArray *sequences, NSInteger photosCount))completion {
    NSMutableArray *sequencesArray = [NSMutableArray array];
    
    NSArray *sequnceIDs = [self getSequenceIDsInBox:box];
    NSInteger allCount = 0;

    for (NSNumber *localSequnenceID in sequnceIDs) {
        OSVSequence *localSeq = [self getSequenceWithID:[localSequnenceID integerValue]];
        
        [sequencesArray addObject:localSeq];
    }
    
    completion(sequencesArray, allCount);
}

+ (NSMutableArray *)getSequenceIDsInBox:(id<RLMBoundingBox>)box {
    NSString *string = [NSString stringWithFormat:@"latitude BETWEEN {%f, %f} AND longitude BETWEEN {%f, %f}", box.bottomRightCoordinate.latitude, box.topLeftCoordinate.latitude, box.topLeftCoordinate.longitude, box.bottomRightCoordinate.longitude];
    RLMResults *realmResults = [RLMPhoto objectsWhere:string];
    NSMutableSet *result = [NSMutableSet set];
    
    for (RLMPhoto *managedObject in realmResults) {
        [result addObject:@(managedObject.localSequenceID)];
    }
    
    return [[result allObjects] mutableCopy];
}

+ (OSVSequence *)getSequenceWithID:(NSInteger)sequenceID {
    CLLocationCoordinate2D topLeftLocation = CLLocationCoordinate2DMake(1000, -1000);
    CLLocationCoordinate2D bottomRightLocation = CLLocationCoordinate2DMake(-1000, 1000);
    
    RLMResults *realmResults = [RLMPhoto objectsWhere:[NSString stringWithFormat:@"localSequenceID == %ld", (long)sequenceID]];
    
    if (!realmResults.count) {
        return nil;
    }
    
    OSVSequence *localSeq = [OSVSequence new];
    localSeq.photos = [NSMutableArray array];
    
    
    for (RLMPhoto *managedObject in  realmResults) {
        OSVPhoto *photo = [OSVPhoto fromRealmObject:managedObject];
        [localSeq.photos addObject:photo];
        
        if (topLeftLocation.latitude > photo.photoData.location.coordinate.latitude ) {
            topLeftLocation.latitude = photo.photoData.location.coordinate.latitude;
        }
        if (topLeftLocation.longitude < photo.photoData.location.coordinate.longitude) {
            topLeftLocation.longitude = photo.photoData.location.coordinate.longitude;
        }
        
        if (bottomRightLocation.latitude < photo.photoData.location.coordinate.latitude) {
            bottomRightLocation.latitude = photo.photoData.location.coordinate.latitude;
        }
        
        if (bottomRightLocation.longitude > photo.photoData.location.coordinate.longitude) {
            bottomRightLocation.longitude = photo.photoData.location.coordinate.longitude;
        }
    }
    
    OSVPhoto *photo = localSeq.photos[0];
    
    localSeq.dateAdded = [NSDate dateWithTimeIntervalSince1970:photo.photoData.timestamp];
    localSeq.uid = photo.localSequenceId;
    localSeq.uploadID = photo.serverSequenceId;
    localSeq.topLeftCoordinate = topLeftLocation;
    localSeq.bottomRightCoordinate = bottomRightLocation;

    return localSeq;
}

#pragma mark - Remove

+ (void)removePhoto:(OSVPhoto *)photo {
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMResults *realmResults = [RLMPhoto objectsWhere:[NSString stringWithFormat:@"localSequenceID == %ld AND sequenceIndex == %ld", (long)photo.localSequenceId, (long)photo.photoData.sequenceIndex]];
    
    if (realmResults.count) {
        [realm transactionWithBlock:^{
            [realm deleteObjects:realmResults];
        }];
    }
}

+ (void)removeSequenceWithID:(NSInteger)sequenceID {
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMResults *realmResults = [RLMPhoto objectsWhere:[NSString stringWithFormat:@"localSequenceID == %ld", (long)sequenceID]];
    if (realmResults.count) {
        [realm transactionWithBlock:^{
            [realm deleteObjects:realmResults];
        }];
    }
}

+ (void)removePhotosWithVideoIndex:(NSInteger)videoIndex localSequenceID:(NSInteger)localSequenceID{
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMResults *realmResults = [RLMPhoto objectsWhere:[NSString stringWithFormat:@"videoIndex == %ld AND localSequenceID == %ld", (long)videoIndex,(long)localSequenceID]];
    
    //NSLog(@"Try remove from DB: %@",realmResults);
    if (realmResults.count) {
        [realm transactionWithBlock:^{
            //NSLog(@"Removing from DB");
            [realm deleteObjects:realmResults];
        }];
    }
}

#pragma mark - Save

+ (void)storePhoto:(OSVPhoto *)photo {
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMPhoto *realmPhoto = [photo toRealmObject];
    
    [realm transactionWithBlock:^{
        [realm addObject:realmPhoto];
    }];
}

#pragma mark - Update

+ (void)updatePhotosHavingLocalSequenceID:(NSInteger)sequenceID withServerID:(NSInteger)serverID {
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMResults *results = [RLMPhoto objectsWhere:[NSString stringWithFormat:@"localSequenceID == %ld", (long)sequenceID]];
    
    [realm transactionWithBlock:^{
        for (RLMPhoto *managedObject in results) {
            managedObject.serverSequenceID = serverID;
        }
        [realm addOrUpdateObjectsFromArray:results];
    }];
}

+ (void)updatedPhoto:(OSVPhoto *)photo withAddress:(NSString *)address {
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMPhoto *realmPhoto = [photo toRealmObject];

    [realm transactionWithBlock:^{
        [realm addOrUpdateObject:realmPhoto];
    }];
}

@end
