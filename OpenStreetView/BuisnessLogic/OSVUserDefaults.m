//
//  OSVUserDefaults.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVUserDefaults.h"

#define kUserNameKey                @"kUserNameKey"
#define kRealPositionsKey           @"kRealPositionsKey"
#define kUseCellularData            @"kConnectionType"

#define kDistanceUnitSystem         @"kDistanceUnitSystem"
#define kAutoDistanceUnitSystem     @"kAutoDistanceUnitSystem"

#define kVideoQuality               @"kVideoQualityOption"
#define kAutomaticUploadKey         @"kAutomaticUploadKey"
#define kEnvironmentKey             @"kEnvironmentKey"
#define kHdrOptionKey               @"kHdrOptionKey"
#define kSLOptionKey                @"kSLOptionKey"

#define kisUploadingKey             @"kisUploadingKey"


#define kDebugLogOBD                @"kDebugLogOBD"
#define kDebugSLUS                  @"kDebugSLUS"

@implementation OSVUserDefaults

+ (instancetype)sharedInstance{
    static id sharedInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"defaultOverriden"]) {
            self.userName = @"";
            self.useCellularData = NO;
            self.automaticUpload = NO;
            self.distanceUnitSystem = kImperialSystem;
            self.automaticDistanceUnitSystem = YES;

            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"defaultOverriden"];
            self.isFreshInstall = YES;
            self.videoQuality = k5MPQuality;
        }
        
        if (!self.environment) {
#ifdef ENABLED_DEBUG
            self.environment = @"http://openstreetview.com";
            //@"http://tst.open-street-view.skobbler.net"
            //@"http://staging.open-street-view.skobbler.net"
            //@"http://openstreetview.com"
#else
            self.environment = @"http://openstreetview.com";
#endif
        }
        
        //if automatic not found then set automatic on
        if (![[NSUserDefaults standardUserDefaults] valueForKey:kAutoDistanceUnitSystem]) {
            self.automaticDistanceUnitSystem = YES;
        }
        
        if (!self.videoQuality || [self.videoQuality isEqualToString:@""]) {
            self.videoQuality = k5MPQuality;
        }
        if (!self.distanceUnitSystem || [self.distanceUnitSystem isEqualToString:@""]) {
            self.distanceUnitSystem = kImperialSystem;
        }
        
        //reset the realPositions to yes in order to have a correct behaviour
        self.realPositions = YES;
        [self save];
    }
    
    return self;
}

- (void)setRealPositions:(BOOL)realPositions {
    return [[NSUserDefaults standardUserDefaults] setBool:realPositions forKey:kRealPositionsKey];
}

- (BOOL)realPositions {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kRealPositionsKey];
}

- (void)setAutomaticUpload:(BOOL)automaticUpload {
    return [[NSUserDefaults standardUserDefaults] setBool:automaticUpload forKey:kAutomaticUploadKey];
}

- (BOOL)automaticUpload {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAutomaticUploadKey];
}

- (void)setUseCellularData:(BOOL)useCellularData {
    return [[NSUserDefaults standardUserDefaults] setBool:useCellularData forKey:kUseCellularData];
}

- (BOOL)useCellularData {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kUseCellularData];
}

- (void)setEnvironment:(NSString *)environment {
    return [[NSUserDefaults standardUserDefaults] setObject:environment forKey:kEnvironmentKey];
}

- (NSString *)environment {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kEnvironmentKey];
}

- (void)setDistanceUnitSystem:(NSString *)distanceUnitSystem {
    return [[NSUserDefaults standardUserDefaults] setValue:distanceUnitSystem forKey:kDistanceUnitSystem];
}

- (NSString *)distanceUnitSystem {
    return [[NSUserDefaults standardUserDefaults] valueForKey:kDistanceUnitSystem];
}

- (void)setAutomaticDistanceUnitSystem:(BOOL)autoDistUnit {
    return [[NSUserDefaults standardUserDefaults] setBool:autoDistUnit forKey:kAutoDistanceUnitSystem];
}

- (BOOL)automaticDistanceUnitSystem {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAutoDistanceUnitSystem];
}

- (void)setVideoQuality:(NSString *)videoQuality {
    return [[NSUserDefaults standardUserDefaults] setValue:videoQuality forKey:kVideoQuality];
}

- (NSString *)videoQuality {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kVideoQuality];
}

- (CMVideoDimensions)videoQualityDimension {
    CMVideoDimensions dimension;
    
    if ([self.videoQuality isEqualToString:k5MPQuality]) {
        dimension.width = 2592;
        dimension.height = 1936;
    } else if ([self.videoQuality isEqualToString:k8MPQuality]) {
        dimension.width = 3264;
        dimension.height = 2448;
        
    } else if ([self.videoQuality isEqualToString:k12MPQuality]) {
        dimension.width = 4032;
        dimension.height = 3024;
    }
    
    return dimension;
}

- (void)setHdrOption:(BOOL)hdrOption {
    return [[NSUserDefaults standardUserDefaults] setBool:hdrOption forKey:kHdrOptionKey];
}

- (BOOL)hdrOption {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kHdrOptionKey];
}

- (void)setUseImageRecognition:(BOOL)useImg {
    return [[NSUserDefaults standardUserDefaults] setBool:useImg forKey:kSLOptionKey];
}

- (BOOL)useImageRecognition {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kSLOptionKey];
}

- (void)setUserName:(NSString *)userName {
    return [[NSUserDefaults standardUserDefaults] setObject:userName forKey:kUserNameKey];
}

- (NSString *)userName {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kUserNameKey];
}

- (void)setIsUploading:(BOOL)isUploading {
    return [[NSUserDefaults standardUserDefaults] setBool:isUploading forKey:kisUploadingKey];
}

- (BOOL)isUploading {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kisUploadingKey];
}

- (void)save {
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - DEBUG

- (BOOL)debugLogOBD {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDebugLogOBD];
}

- (void)setDebugLogOBD:(BOOL)debugLogOBD {
    return [[NSUserDefaults standardUserDefaults] setBool:debugLogOBD forKey:kDebugLogOBD];
}

- (BOOL)debugSLUS{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDebugSLUS];
}

- (void)setDebugSLUS:(BOOL)debugSLUS {
    return [[NSUserDefaults standardUserDefaults] setBool:debugSLUS forKey:kDebugSLUS];
}

@end
