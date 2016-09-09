//
//  OSVPhotoPlayer.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 15/06/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVPhotoPlayer.h"
#import "OSVSyncController.h"
#import <CoreMedia/CoreMedia.h>

@class OSVPhoto;
@protocol OSVPhoto;

@interface OSVPhotoPlayer ()

@property (nonatomic, strong) CALayer                       *playerLayer;
@property (nonatomic, strong) NSArray                       *currentPlayableItem;
@property (nonatomic, strong) UISlider                      *slider;
@property (nonatomic, assign) BOOL                          isPlaying;

@property (nonatomic, strong) NSTimer                       *timer;

@property (nonatomic, assign) NSInteger                     currentIndex;

@property (strong, nonatomic) UIView                        *view;

@property (strong, nonatomic) UIImageView                   *imageView;

@property (nonatomic, assign) CMTime                        duration;

@property (nonatomic, assign) BOOL                          didBeginScrubbing;

@end

@implementation OSVPhotoPlayer

@synthesize delegate;

- (instancetype)initWithView:(UIView *)aview andSlider:(UISlider *)slider {
    self = [super init];
    if (self) {
        self.view = aview;
        self.slider = slider;
        [self.slider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [self.slider addTarget:self action:@selector(beginScrubbing:) forControlEvents:UIControlEventTouchDown];
        [self.slider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpInside];
        [self.slider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
        
        self.imageView = [[UIImageView alloc] initWithFrame:aview.bounds];
        self.imageView.userInteractionEnabled = YES;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [self.view insertSubview:self.imageView atIndex:0];
        self.duration = kCMTimeZero;
        self.slider.minimumValue = 1;
    }
    
    return self;
}

- (void)prepareForPlayableItem:(id)playableItem startingFromIndex:(NSInteger)index {
    if ([playableItem isKindOfClass:[NSArray class]]) {
        self.currentPlayableItem = playableItem;
        self.currentIndex = index;
        self.slider.maximumValue = self.currentPlayableItem.count;
        NSInteger index = MAX(MIN(self.currentIndex, self.currentPlayableItem.count - 1), 0);
        [[OSVSyncController sharedInstance].tracksController loadThumbnailForPhoto:self.currentPlayableItem[index] intoImageView:[UIImageView new] withCompletion:^(id<OSVPhoto> completePhoto, NSError *error) {
            self.imageView.image = completePhoto.thumbnail;
            completePhoto.thumbnail = nil;
            [self syncScrubber:index];
        }];
        
        [self.delegate totalNumberOfFrames:self.currentPlayableItem.count];
    }
}

- (void)play {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(displayNextFrame) userInfo:nil repeats:YES];
    self.imageView.frame = self.view.bounds;
    self.isPlaying = YES;
}

- (void)stop {
    [self.timer invalidate];
    self.timer = nil;
    self.isPlaying = NO;
}

- (void)pause {
    [self stop];
}

- (void)resume {
    [self play];
}

- (void)displayNextFrame {
    if (self.currentIndex + 1 >= self.currentPlayableItem.count) {
        return;
    }
    
    if (self.currentIndex + 1 < 0) {
        self.currentIndex = 0;
    }
    
    NSInteger index = ++self.currentIndex;
        
    [[OSVSyncController sharedInstance].tracksController loadThumbnailForPhoto:self.currentPlayableItem[index] intoImageView:[UIImageView new] withCompletion:^(id<OSVPhoto> completePhoto, NSError *error) {
        self.imageView.image = completePhoto.thumbnail;
        completePhoto.thumbnail = nil;
        [self syncScrubber:index];
    }];
}

- (void)displayPreviousFrame {
    if (self.currentIndex - 1 < 0) {
        return;
    }

    if (self.currentIndex - 1 >= self.currentPlayableItem.count) {
        self.currentIndex = self.currentPlayableItem.count - 1;
    }
    
    NSInteger index = --self.currentIndex;
    [[OSVSyncController sharedInstance].tracksController loadThumbnailForPhoto:self.currentPlayableItem[index] intoImageView:[UIImageView new] withCompletion:^(id<OSVPhoto> completePhoto, NSError *error) {
        self.imageView.image = completePhoto.thumbnail;
        completePhoto.thumbnail = nil;
        [self syncScrubber:index];
    }];
}

- (void)displayFrameAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.currentPlayableItem.count) {
        return;
    }
    
    self.currentIndex = index;
    [[OSVSyncController sharedInstance].tracksController loadThumbnailForPhoto:self.currentPlayableItem[MAX(index-1, 0)] intoImageView:[UIImageView new] withCompletion:^(id<OSVPhoto> completePhoto, NSError *error) {
        self.imageView.image = completePhoto.thumbnail;
        completePhoto.thumbnail = nil;
        [self syncScrubber:index];
    }];
}

- (void)fastForward {
    [self.timer invalidate];
    self.timer = nil;
    self.isPlaying = YES;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(displayNextFrame) userInfo:nil repeats:YES];
}

- (void)fastBackward {
    [self.timer invalidate];
    self.timer = nil;
    self.isPlaying = YES;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(displayPreviousFrame) userInfo:nil repeats:YES];
}


#pragma mark - Private

- (void)syncScrubber:(NSInteger)index {
    
    double duration = self.currentPlayableItem.count;
    if (duration > 0) {
        if ([self.delegate respondsToSelector:@selector(didDisplayFrameAtIndex:)]) {
            [self.delegate didDisplayFrameAtIndex:index + 1];
        }
        
        [self.slider setValue:index];
    }
}

#pragma mark - Slider

- (void)beginScrubbing:(id)sender {
    self.didBeginScrubbing = YES;
}

- (void)scrub:(id)sender {
    if ([sender isKindOfClass:[UISlider class]]) {
        UISlider *slider = sender;
        NSInteger value = (NSInteger)[slider value];
        [self displayFrameAtIndex:value];
    }
}

- (void)endScrubbing:(id)sender {
    self.didBeginScrubbing = NO;
}

- (BOOL)isScrubbing {
    return NO;
}

@end
