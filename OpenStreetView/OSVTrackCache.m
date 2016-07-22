//
//  OSVTrackCache.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVTrackCache.h"


@interface OSVTrackCache ()

@property (nonatomic) NSLock                    *getLockLevelOne;
@property (nonatomic) NSLock                    *getLockLevelTwo;

@property (nonatomic) NSMutableArray            *boxCaches;
@property (nonatomic) NSMutableArray            *levelOneCache;
@property (nonatomic) NSMutableArray            *levelTwoCache;

@end

@implementation OSVTrackCache

- (instancetype)init {
    self = [super init];
    if (self) {
        self.getLockLevelOne = [NSLock new];
//        self.getLockLevelTwo = [NSLock new];
        self.levelOneCache = [NSMutableArray array];
//        self.levelTwoCache = [NSMutableArray array];
    }
    
    return self;
}

#pragma mark - Caching methods

- (void)cacheLevelOneID:(NSInteger)trackID {
    [self.getLockLevelOne lock];
    
    [self.levelOneCache addObject:@(trackID)];
    
    [self.getLockLevelOne unlock];
}

- (void)removeLevelOneID:(NSInteger)trackID {
    [self.getLockLevelOne lock];
    
    [self.levelOneCache removeObject:@(trackID)];
    
    [self.getLockLevelOne unlock];
}

- (void)moveCacheLevelOneToLevelTwo {
    [self.getLockLevelOne lock];
    [self.getLockLevelTwo lock];
    
    self.levelTwoCache = self.levelOneCache;
    self.levelOneCache = [NSMutableArray array];

    [self.getLockLevelTwo unlock];
    [self.getLockLevelOne unlock];
}

- (NSArray *)clearLevelOneCache {
    [self.getLockLevelOne lock];
    
    NSArray *array = [self.levelOneCache copy];
    [self.levelOneCache removeAllObjects];
    
    [self.getLockLevelOne unlock];

    return array;
}

- (NSArray *)clearLevelTwoCache {
    [self.getLockLevelTwo lock];

    NSArray *array = [self.levelTwoCache copy];
    [self.levelTwoCache removeAllObjects];
    
    [self.getLockLevelTwo unlock];
    
    return array;
}

- (NSArray *)allCachedIDs {
//    [self.getLockLevelTwo lock];
    [self.getLockLevelOne lock];

    NSMutableArray *array = [self.levelOneCache copy];
//    [array addObjectsFromArray:self.levelTwoCache];
    
    [self.getLockLevelOne unlock];
//    [self.getLockLevelTwo unlock];

    return array;
}

- (void)resetCacheToIDs:(NSArray *)allIDs {
    [self.getLockLevelOne lock];
    self.levelOneCache = [allIDs mutableCopy];
    [self.getLockLevelOne unlock];
}

@end
