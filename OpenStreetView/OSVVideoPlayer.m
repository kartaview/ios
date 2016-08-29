//
//  OSVVideoPlayer.m
//  VideoEncoder
//
//  Created by Bogdan Sala on 09/05/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import "OSVVideoPlayer.h"

@interface OSVVideoPlayer ()

@property (nonatomic, strong) CALayer                       *playerLayer;

@property (strong, nonatomic) UIView                        *view;

@property (nonatomic, strong) AVPlayer                      *player;

@property (nonatomic, strong) UISlider                      *slider;

@property (nonatomic, strong) id                            timeObserverObject;

@property (nonatomic, assign) CMTime                        duration;

@property (nonatomic, assign) float                         restoreAfterScrubbingRate;
@property (nonatomic, assign) BOOL                          isSeeking;

@property (nonatomic, assign) BOOL                          isPlaying;

@property (nonatomic, strong) NSArray<AVPlayerItem *>       *itemsArray;

@property (nonatomic, strong) NSURL                         *currentPlayableItem;
@property (strong, nonatomic) UIImageView                   *imageView;

@end

@implementation OSVVideoPlayer

@synthesize delegate;


- (instancetype)initWithView:(UIView *)aview andSlider:(UISlider *)slider {
    self = [super init];
    if (self) {
        self.view = aview;
        self.imageView = [[UIImageView alloc] initWithFrame:aview.bounds];
        self.imageView.userInteractionEnabled = YES;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.hidden = YES;
        
        self.slider = slider;
        [self.slider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        [self.slider addTarget:self action:@selector(beginScrubbing:) forControlEvents:UIControlEventTouchDown];
        [self.slider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpInside];
        [self.slider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
        
        AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        layer.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
        layer.videoGravity = AVLayerVideoGravityResizeAspect;
        self.playerLayer = layer;
        
        self.duration = kCMTimeZero;
        [self.view.layer insertSublayer:self.playerLayer atIndex:0];
        [self.view addSubview:self.imageView];
    }
    
    return self;
}

- (void)prepareForPlayableItem:(id)playableItem startingFromIndex:(NSInteger)index {
    if (![playableItem isKindOfClass:[NSURL class]]) {
        return;
    }
    
    _currentPlayableItem = playableItem;

    NSArray<NSURL *> *videoPaths = [self videoPathsFromFolder:self.currentPlayableItem];
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime insertTime = kCMTimeZero;
    
    for (NSURL *object in videoPaths) {
        
        AVAsset *asset = [AVAsset assetWithURL:object];
        NSArray *videos = [asset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetTrack *track = [videos firstObject];
        if (track) {
            CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
            
            [videoTrack insertTimeRange:timeRange
                                ofTrack:track
                                 atTime:insertTime
                                  error:nil];
            
            insertTime = CMTimeAdd(insertTime, asset.duration);
        } else {
            NSLog(@"bad asset");
        }
    }
    
    self.duration = insertTime;
    AVComposition *immutableSnapshotOfMyComposition = [mixComposition copy];
    
    // Create a player to inspect and play the composition.
    AVPlayerItem *playerItemForSnapshottedComposition = [[AVPlayerItem alloc] initWithAsset:immutableSnapshotOfMyComposition];
    
    self.player = [[AVPlayer alloc] initWithPlayerItem:playerItemForSnapshottedComposition];
    AVPlayerLayer *videoLayer = (AVPlayerLayer *)self.playerLayer;
    videoLayer.player = self.player;
    
    self.playerLayer.frame = self.view.bounds;
    
    if (index) {
        [self displayFrameAtIndex:index];
    }
}

- (void)play {
    if (!self.currentPlayableItem) {
        return;
    }
    
    double interval = .2f;
    __weak typeof(self) welf = self;
    
    self.timeObserverObject = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                                        queue:NULL
                                                                   usingBlock:^(CMTime time) {
                                                                       [welf syncScrubber:time];
                                                                   }];
    self.isPlaying = YES;

    [self.player play];
    
    CMTimeShow(self.duration);
    NSInteger value = (NSInteger)round(CMTimeGetSeconds(self.duration)/0.2);

    if ([self.delegate respondsToSelector:@selector(totalNumberOfFrames:)]) {
        [self.delegate totalNumberOfFrames:value];
    }

//    TODO fix this
    NSInteger frameIndex = 1;
    if ([self.delegate respondsToSelector:@selector(didDisplayFrameAtIndex:)]) {
        [self.delegate didDisplayFrameAtIndex:frameIndex];
    }
}

- (void)stop {
    self.playerLayer.frame = self.view.bounds;

    self.isPlaying = NO;
    [self.player pause];
}

- (void)pause {
    self.playerLayer.frame = self.view.bounds;

    self.isPlaying = NO;
    [self.player pause];
}

- (void)resume {
    self.playerLayer.frame = self.view.bounds;
    self.isPlaying = YES;
    [self.player play];
}

- (void)displayNextFrame {
    CMTimeShow(self.player.currentItem.currentTime);
    CMTime time = CMTimeAdd(self.player.currentItem.currentTime, CMTimeMake(1, 5));
    if (CMTimeCompare(self.player.currentItem.duration, time) == 1) {
        [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
}

- (void)displayPreviousFrame {
    CMTime someTime = self.player.currentItem.currentTime;
    CMTime time = CMTimeAdd(someTime, CMTimeMake(-1, 5));
    if (CMTimeCompare(time, kCMTimeZero) != -1) {
        [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
}

- (void)displayFrameAtIndex:(NSInteger)index {
    CMTime time = CMTimeMake(1 * index, 5);
    
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            double stime = CMTimeGetSeconds(self.player.currentTime);
            
            NSInteger frameIndex = round(stime/0.2) + 1;
            
            if ([self.delegate respondsToSelector:@selector(didDisplayFrameAtIndex:)]) {
                NSInteger valueTotal = (NSInteger)round(CMTimeGetSeconds(self.duration)/0.2);
                frameIndex = MIN(frameIndex, valueTotal);
                [self.delegate didDisplayFrameAtIndex:frameIndex];
            }
            _isSeeking = NO;
        });

    }];
}

- (void)fastForward {
    self.isPlaying = YES;
    self.player.rate = 2;
}

- (void)fastBackward {
    self.isPlaying = YES;
    self.player.rate = -2;
}

#pragma mark - Private

- (NSArray<NSURL *> *)videoPathsFromFolder:(NSURL *)basePath {
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

- (CMTime)playerItemDuration {
    AVPlayerItem *thePlayerItem = [self.player currentItem];
    if (thePlayerItem.status == AVPlayerItemStatusReadyToPlay) {
        
        return thePlayerItem.duration;
    }
    
    return kCMTimeInvalid;
}

- (void)syncScrubber:(CMTime)obsTime {
    if (CMTIME_IS_INVALID([self playerItemDuration])) {
        self.slider.minimumValue = CMTimeGetSeconds(self.player.currentTime);
        return;
    }
    
    double duration = CMTimeGetSeconds([self playerItemDuration]);
    if (isfinite(duration) && (duration > 0)) {
        float minValue = [self.slider minimumValue];
        float maxValue = [self.slider maximumValue];
        double time = CMTimeGetSeconds(self.player.currentTime);
                
        NSInteger value = (NSInteger)round(duration/0.2);
        
        NSInteger frameIndex = round(CMTimeGetSeconds(obsTime)/0.2) + 1;

        if ([self.delegate respondsToSelector:@selector(totalNumberOfFrames:)]) {
            [self.delegate totalNumberOfFrames:value];
        }
        
        if ([self.delegate respondsToSelector:@selector(didDisplayFrameAtIndex:)]) {
            frameIndex = MIN(frameIndex, value);
            [self.delegate didDisplayFrameAtIndex:frameIndex];
        }
        
        [self.slider setValue:(maxValue - minValue) * time / duration + minValue];
    }
}

- (UIImage *)currentItemScreenShot {
    AVPlayer *abovePlayer = self.player;
    CMTime time = [[abovePlayer currentItem] currentTime];
    AVAsset *asset = [[abovePlayer currentItem] asset];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    if ([imageGenerator respondsToSelector:@selector(setRequestedTimeToleranceBefore:)] && [imageGenerator respondsToSelector:@selector(setRequestedTimeToleranceAfter:)]) {
        [imageGenerator setRequestedTimeToleranceBefore:kCMTimeZero];
        [imageGenerator setRequestedTimeToleranceAfter:kCMTimeZero];
    }
    
    CGImageRef imgRef = [imageGenerator copyCGImageAtTime:time
                                               actualTime:NULL
                                                    error:NULL];
    if (imgRef == nil) {
        if ([imageGenerator respondsToSelector:@selector(setRequestedTimeToleranceBefore:)] && [imageGenerator respondsToSelector:@selector(setRequestedTimeToleranceAfter:)]) {
            [imageGenerator setRequestedTimeToleranceBefore:kCMTimePositiveInfinity];
            [imageGenerator setRequestedTimeToleranceAfter:kCMTimePositiveInfinity];
        }
        imgRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    }
    UIImage *image = [[UIImage alloc] initWithCGImage:imgRef];
    CGImageRelease(imgRef);
    
    return image;
}

#pragma mark - Override

- (UIImageView *)imageView {
    _imageView.image = [self currentItemScreenShot];
    
    return _imageView;
}

#pragma mark - Slider

- (void)beginScrubbing:(id)sender {
    _restoreAfterScrubbingRate = [self.player rate];
    [self.player setRate:0.f];
    
    /* Remove previous timer. */
    [self removePlayerTimeObserver];
}

- (void)scrub:(id)sender {
    if ([sender isKindOfClass:[UISlider class]] && !_isSeeking) {
        _isSeeking = YES;
        UISlider *slider = sender;
        
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration)) {
            float minValue = [slider minimumValue];
            float maxValue = [slider maximumValue];
            float value = [slider value];
            
            double time = duration * (value - minValue) / (maxValue - minValue);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSInteger frameIndex = round(time/0.2) + 1;
                
                if ([self.delegate respondsToSelector:@selector(didDisplayFrameAtIndex:)]) {
                    NSInteger valueTotal = (NSInteger)round(CMTimeGetSeconds(self.duration)/0.2);
                    frameIndex = MIN(frameIndex, valueTotal);
                    
                    [self.delegate didDisplayFrameAtIndex:frameIndex];
                }
            });

            [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    double stime = CMTimeGetSeconds(self.player.currentTime);

                    NSInteger frameIndex = round(stime/0.2) + 1;

                    if ([self.delegate respondsToSelector:@selector(didDisplayFrameAtIndex:)]) {
                        NSInteger valueTotal = (NSInteger)round(CMTimeGetSeconds(self.duration)/0.2);
                        frameIndex = MIN(frameIndex, valueTotal);
                        [self.delegate didDisplayFrameAtIndex:frameIndex];
                    }
                    _isSeeking = NO;
                });
            }];
        }
    }
}

- (void)endScrubbing:(id)sender {
    if (!_timeObserverObject) {
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration)) {
            
            double tolerance = 0.2f;
            CMTime time = CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC);
            __weak typeof(self) welf = self;
            _timeObserverObject = [self.player addPeriodicTimeObserverForInterval:time queue:NULL
                                                                       usingBlock:^(CMTime time) {
                                                                           [welf syncScrubber:time];
                                                                       }];
        }
    }
    
    if (_restoreAfterScrubbingRate) {
        [self.player setRate:_restoreAfterScrubbingRate];
        _restoreAfterScrubbingRate = 0.f;
    }
}

- (BOOL)isScrubbing {
    return _restoreAfterScrubbingRate != 0.f;
}

- (void)removePlayerTimeObserver {
    if (_timeObserverObject) {
        [self.player removeTimeObserver:_timeObserverObject];
        _timeObserverObject = nil;
    }
}

@end
