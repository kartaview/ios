//
//  OSVSyncController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 11/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVSyncController.h"
#import "OSVUtils.h"
#import "OSVAPI.h"
#import "OSVPersistentManager.h"
#import "ConnectivityHandler.h"
#import "OSVServerPhoto.h"
#import "OSVServerSequence+Convertor.h"
#import "OSVBaseUser+OSM.h"

#import "UIDevice+Aditions.h"
#import "OSVAPISerialOperation.h"

#import "OSVUserDefaults.h"

#import "OSVTrackSyncController.h"
#import "OSVPersistentManager.h"

#import "OSVLogger.h"

@interface OSVSyncController () <OSVAPIConfigurator>

@property (nonatomic, assign) BOOL              cancelGetRequests;
@property (nonatomic) NSString                  *basePath;
@end

@implementation OSVSyncController

- (instancetype)init {
    self = [super init];
    
    if (self) {
        OSVAPI *osvAPI = [OSVAPI new];
        osvAPI.configurator = self;
        self.basePath = [self createBasePath];
        self.tracksController = [[OSVTrackSyncController alloc] initWithOSVAPI:osvAPI basePath:self.basePath];
        self.logger = [[OSVTrackLogger alloc] initWithBasePath:self.basePath];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNetworkStatusChange:) name:kReachabilityChangedNotification object:nil];
    }
    
    return self;
}

+ (instancetype)sharedInstance {
    static id sharedInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)createBasePath {
    NSError *error;
    NSString *photosFolderPath = [[OSVUtils getDirectoryPath] stringByAppendingString:@"/Photos/"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:photosFolderPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:photosFolderPath withIntermediateDirectories:YES attributes:nil error:&error];
        NSError *error = nil;
        NSURL *URL = [NSURL fileURLWithPath:photosFolderPath];
        
        BOOL success = [URL setResourceValue:[NSNumber numberWithBool:YES]
                                      forKey:NSURLIsExcludedFromBackupKey error: &error];
        if(!success){
            NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
        }
    }
    
    return photosFolderPath;
}

+ (BOOL)isUploading {
    return [[OSVSyncController sharedInstance].tracksController isUploading];
}

+ (long long)sizeOnDiskForSequences {
    return [OSVSyncUtils sizeOnDiskForSequencesAtPath:[OSVSyncController sharedInstance].basePath];
}

+ (long long)sizeOnDiskForSequence:(id<OSVSequence>)sequence  {
    return [OSVSyncUtils sizeOnDiskForSequence:sequence atPath:[OSVSyncController sharedInstance].basePath];
}

+ (BOOL)hasSequencesToUpload {
    return [OSVPersistentManager hasPhotos];
}

#pragma mark - OSVAPIConfigurator

- (NSString *)osvBaseURL {
    return [OSVUserDefaults sharedInstance].environment;
}

- (NSString *)osvAPIVerion {
    return @"1.0/";
}

- (NSString *)platformVersion {
    return [UIDevice osVersion];
}

- (NSString *)platformName {
    return [UIDevice modelString];
}

- (NSString *)appVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

#pragma mark - Private

- (void)didReceiveNetworkStatusChange:(NSNotification *)notificaiton {
    Reachability *r = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [r currentReachabilityStatus];

    if (self.didChangeReachabliyStatus) {
        if (status == ReachableViaWiFi) {
            self.didChangeReachabliyStatus(OSVReachabilityStatusWiFi);
        } else if (status == ReachableViaWWAN) {
            self.didChangeReachabliyStatus(OSVReachabilityStatusCellular);
        } else {
            self.didChangeReachabliyStatus(OSVReachabilityStatusNotReachable);
        }
    }
}


@end
