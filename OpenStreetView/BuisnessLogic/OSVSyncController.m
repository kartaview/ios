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
#import "OSVBaseUser.h"

#import "UIDevice+Aditions.h"
#import "OSVAPISerialOperation.h"

#import "OSVUserDefaults.h"

#import "OSVTrackSyncController.h"
#import "OSVPersistentManager.h"

#import "OSVLogger.h"

@interface OSVSyncController () <OSVAPIConfigurator>

@property (nonatomic, assign) BOOL              cancelGetRequests;

@end

@implementation OSVSyncController

- (instancetype)init {
    self = [super init];
    
    if (self) {
        OSVAPI *osvAPI = [OSVAPI new];
        osvAPI.configurator = self;

        self.tracksController = [[OSVTrackSyncController alloc] initWithOSVAPI:osvAPI];
        self.logger = [[OSVTrackLogger alloc] initWithBasePath:[OSVUtils createOSCBasePath]];

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

+ (BOOL)isUploading {
    return [[OSVSyncController sharedInstance].tracksController isUploading];
}

+ (long long)sizeOnDiskForSequences {
    return [OSVSyncUtils sizeOnDiskForSequencesAtPath:[OSVUtils createOSCBasePath]];
}

+ (long long)sizeOnDiskForSequence:(id<OSVSequence>)sequence  {
    return [OSVSyncUtils sizeOnDiskForSequence:sequence atPath:[OSVUtils createOSCBasePath]];
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
