//
//  OSVPlayer.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 15/06/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OSVPlayerDelegate <NSObject>

- (void)didDisplayFrameAtIndex:(NSInteger)frameIndex;
- (void)totalNumberOfFrames:(NSInteger)totalFrames;

@end

@protocol OSVPlayer <NSObject>

@property (nonatomic, assign, readonly) BOOL            isPlaying;
@property (nonatomic, strong, readonly) id              currentPlayableItem;
@property (nonatomic, strong, readonly) CALayer         *playerLayer;
@property (nonatomic, strong, readonly) UIImageView     *imageView;

@property (nonatomic, weak) id <OSVPlayerDelegate>       delegate;

- (instancetype)initWithView:(UIView *)aview andSlider:(UISlider *)slider;

- (void)prepareForPlayableItem:(id)playableItem startingFromIndex:(NSInteger)index;

- (void)play;
- (void)resume;
- (void)pause;
- (void)stop;

- (void)displayNextFrame;
- (void)displayPreviousFrame;

- (void)fastForward;
- (void)fastBackward;

- (void)displayFrameAtIndex:(NSInteger)index;

@end
