//
//  OSVSyncUtils.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVSyncUtils.h"
#import "OSVUserDefaults.h"
#import "OSVUtils+Image.m"
#import "OSVBaseUser+OSM.h"
#import "ConnectivityHandler.h"
#import "OSVPhoto.h"
#import "OSVServerPhoto.h"
#import "OSVServerSequence.h"
#import "OSVLogger.h"

@implementation OSVSyncUtils

+ (BOOL)hasInternetPermissions {
    if ([ConnectivityHandler sharedInstance].isConnectionViaWWAN && ![OSVUserDefaults sharedInstance].useCellularData) {
        return NO;
    }
    
    return YES;
}

+ (void)correctImageDataForPhoto:(OSVPhoto *)photo {
    if (photo.image && photo.correctionOrientation != UIImageOrientationUp) {
        photo.image = [OSVUtils rotateImage:photo.image toImageOrientation:photo.correctionOrientation];
        photo.correctionOrientation = UIImageOrientationUp;
    }
}

+ (long long)sizeOnDiskForSequence:(id<OSVSequence>)sequence atPath:(NSString *)path {
    if ([sequence isKindOfClass:[OSVServerSequence class]]) {
        
        return 0.0;
    } else {
        NSString *seqPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"/%ld", (long)sequence.uid]];
        
        return [OSVUtils sizeOfFolder:seqPath];
    }
}

+ (long long)sizeOnDiskForSequence:(id<OSVSequence>)sequence atPath:(NSString *)path containsImages:(BOOL *)contains {
    if ([sequence isKindOfClass:[OSVServerSequence class]]) {
        
        return 0.0;
    } else {
        NSString *seqPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"/%ld", (long)sequence.uid]];
        
        return [OSVUtils sizeOfFolder:seqPath containsImages:contains];
    }
}

+ (long long)sizeOnDiskForPhoto:(id<OSVPhoto>)photo atPath:(NSString *)path {
    if ([photo isKindOfClass:[OSVServerPhoto class]]) {
        
        return 0.0;
    } else {
        NSString *photoPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", photo.imageName]];
        
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:photoPath error:nil];
        
        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        
        return [fileSizeNumber longLongValue];
    }
}

+ (long long)sizeOnDiskForSequencesAtPath:(NSString *)path {
    return [OSVUtils sizeOfFolder:path];
}

+ (BOOL)removeTrackWithID:(NSInteger)seqID atPath:(NSString *)path {
    NSString *photoPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"/%ld", (long)seqID]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error;
    BOOL succes = [fileManager removeItemAtPath:photoPath error:&error];
    
    if (succes) {
        [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"deleted:%ld", (long)seqID] withLevel:LogLevelDEBUG];
    } else {
        [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"faild to delete:%ld", (long)seqID] withLevel:LogLevelDEBUG];
    }
    
    return succes;
}

+ (BOOL)removeVideoAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    BOOL succes = [fileManager removeItemAtPath:path error:&error];
    
    if (succes) {
        NSLog(@"deleted:%@", path);
    } else {
        NSLog(@"faild to delete");
    }
    
    return succes;
}

+ (NSArray *)getFolderNamesAtPath:(NSString *)path {
    NSMutableArray *array = [NSMutableArray new];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *fileList = [manager contentsOfDirectoryAtPath:path error:nil];
    for (NSString *folderName in fileList){
        [array addObject:folderName];
    }
    
    return array;
}

@end
