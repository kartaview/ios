//
//  OSVUtils+FileManager.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/10/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVUtils.h"
#import "OSVLogger.h"

#define kMB (1000*1000)
#define kGB (kMB*1000)

@implementation OSVUtils (FileManager)

+ (NSString *)documentsDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    return [paths objectAtIndex:0];
}

+ (NSString *)memoryFormatter:(long long)diskSpace {
    return [NSByteCountFormatter stringFromByteCount:diskSpace countStyle:NSByteCountFormatterCountStyleFile];
}

+ (NSArray *)arrayFormatedFromByteCount:(long long)bytes {
    if (bytes / kGB > 0) {
        NSArray *array = [[self memoryFormatter:bytes] componentsSeparatedByString:@" "];
        NSString *unit = [NSString stringWithFormat:@" %@", array[1]];
        return @[array[0], unit];
    } else if (bytes / kMB > 0){
        return @[[NSString stringWithFormat:@"%lld", (long long)bytes/kMB], @" MB"];
    } else if (bytes / 1000 > 0){
        return @[[NSString stringWithFormat:@"%lld", bytes/1000], @" KB"];
    }
    
    return @[@"0", @" KB"];
}

+ (NSString *)stringFromByteCount:(long long)bytes {
    if (bytes / kGB > 0) {
        return [self memoryFormatter:bytes];
    } else if (bytes / kMB > 0){
        return [NSString stringWithFormat:@"%lld MB", (long long)bytes/kMB];
    } else if (bytes / 1000 > 0){
        return [NSString stringWithFormat:@"%lld KB", bytes/1000];
    }
    
    return @"0 KB";
}

+ (NSString *)totalDiskSpace {
    long long space = [OSVUtils totalDiskSpaceBytes];
    
    return [self memoryFormatter:space];
}

+ (NSString *)freeDiskSpace {
    long long freeSpace = [OSVUtils freeDiskSpaceBytes];
    
    return [self memoryFormatter:freeSpace];
}

+ (NSString *)usedDiskSpace {
    return [self memoryFormatter:[OSVUtils usedDiskSpaceBytes]];
}

+ (long long)totalDiskSpaceBytes {
    long long space = [[[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemSize] longLongValue];
    
    return space;
}

+ (long long)freeDiskSpaceBytes {
    long long freeSpace = [[[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemFreeSize] longLongValue];
    
    return freeSpace;
}

+ (long long)usedDiskSpaceBytes {
    long long usedSpace = [OSVUtils totalDiskSpaceBytes] - [OSVUtils freeDiskSpaceBytes];
    
    return usedSpace;
}

+ (long long)sizeOfFolder:(NSString *)directoryUrl {
    BOOL contains = NO;
    long long sizeValue = [self sizeOfFolder:directoryUrl containsImages:&contains];
    
    return sizeValue;
}

+ (long long)sizeOfFolder:(NSString *)directoryUrl containsImages:(BOOL *)contains {
    NSUInteger folderSize = 0;
    
    NSArray *properties = [NSArray arrayWithObjects: NSURLLocalizedNameKey, NSURLLocalizedTypeDescriptionKey, nil];
    
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL URLWithString:directoryUrl] includingPropertiesForKeys:properties options:(NSDirectoryEnumerationSkipsHiddenFiles) error:nil];
    
    for (NSURL *fileSystemItem in array) {
        BOOL directory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:[fileSystemItem path] isDirectory:&directory];
        if (!directory) {
            
            NSInteger videoSize = [[[[NSFileManager defaultManager] attributesOfItemAtPath:[fileSystemItem path] error:nil] objectForKey:NSFileSize] unsignedIntegerValue];
            
            if (videoSize && [[fileSystemItem pathExtension] isEqualToString:@"mp4"]) {
                *contains = YES;
            }
            
            folderSize += videoSize;
        } else {
            folderSize += [self sizeOfFolder:fileSystemItem.absoluteString containsImages:contains];
        }
    }
    
    NSString *folderSizeStr = [NSByteCountFormatter stringFromByteCount:folderSize countStyle:NSByteCountFormatterCountStyleFile];
    NSLog(@"%@", folderSizeStr);
    
    return folderSize;
}

+ (NSURL *)fileNameForTrackID:(NSInteger)trackUID {
    NSString *folderPathString = [NSString stringWithFormat:@"%@%ld", [OSVUtils createOSCBasePath], (long)trackUID];
    
    return [[NSURL alloc] initWithString:folderPathString];
}

+ (NSArray<NSURL *> *)videoPathsFromFolder:(NSURL *)basePath {
    NSMutableArray *videoFiles = [NSMutableArray array];
    
    NSArray *properties = [NSArray arrayWithObjects: NSURLLocalizedNameKey, NSURLCreationDateKey, NSURLLocalizedTypeDescriptionKey, nil];
    
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:basePath includingPropertiesForKeys:properties options:(NSDirectoryEnumerationSkipsHiddenFiles) error:nil];
    
    for (NSURL *fileSystemItem in array) {
        BOOL directory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:[fileSystemItem path] isDirectory:&directory];
        if (!directory && [fileSystemItem pathExtension] && [[fileSystemItem pathExtension] isEqualToString:@"mp4"]) {
            [videoFiles addObject:fileSystemItem];
        }
    }
    
    [videoFiles sortUsingComparator:^NSComparisonResult(NSURL *obj1, NSURL *obj2) {
        
        return [[[obj1 lastPathComponent] stringByDeletingPathExtension] integerValue] > [[[obj2 lastPathComponent] stringByDeletingPathExtension] integerValue];
    }];
    
    return videoFiles;
}

static NSString *oscBasePath = nil;

+ (NSString *)createOSCBasePath {
    NSString *photosFolderPath = [[OSVUtils documentsDirectoryPath] stringByAppendingString:@"/Photos/"];

    if (!oscBasePath) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:photosFolderPath]) {
            NSError *error;
            [[NSFileManager defaultManager] createDirectoryAtPath:photosFolderPath withIntermediateDirectories:YES attributes:nil error:&error];
            NSURL *URL = [NSURL fileURLWithPath:photosFolderPath];
            
            NSError *errorExcluding = nil;
            BOOL success = [URL setResourceValue:[NSNumber numberWithBool:YES]
                                          forKey:NSURLIsExcludedFromBackupKey error:&errorExcluding];
            if (!success) {
                NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], errorExcluding);
            }
        }
        oscBasePath = photosFolderPath;
    }
    
    return oscBasePath;
}

+ (NSString *)fileNameForVideoWithTrackID:(NSInteger)trackUID index:(NSInteger)videoIndex {
    NSString *folderPathString = [NSString stringWithFormat:@"%@%ld/%ld.mp4", [OSVUtils createOSCBasePath], (long)trackUID, (long)videoIndex];
    
    return folderPathString;
}

+ (NSURL *)fileNameForTrackID:(NSInteger)trackUID videoID:(NSInteger)videoUID {
    NSString *folderPathString = [NSString stringWithFormat:@"%@%ld", [OSVUtils createOSCBasePath], (long)trackUID];
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderPathString]) {
        NSError *error;
        BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:folderPathString withIntermediateDirectories:NO attributes:NULL error:&error];
        if (!success) {
            [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Failed to create folder for trackID:%ld error:%@", (long)trackUID, error] withLevel:LogLevelDEBUG];
            success = [[NSFileManager defaultManager] createDirectoryAtPath:folderPathString withIntermediateDirectories:NO attributes:NULL error:&error];
            [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Retry to create folder with result:%d error:%@", success, error] withLevel:LogLevelDEBUG];
        }
    }
    
    return [NSURL fileURLWithPath:[folderPathString stringByAppendingString:[NSString stringWithFormat:@"/%ld.mp4", (long)videoUID]]];
}

@end

#undef kMB
#undef kGB
