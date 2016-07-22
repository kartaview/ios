//
//  OSVVideoPlayerViewController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 12/05/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OSVSequence.h"

@protocol OSVPlayer;

@interface OSVVideoPlayerViewController : UIViewController

@property (nonatomic, strong) id<OSVSequence>               selectedSequence;
@property (strong, nonatomic, readonly) id<OSVPlayer>       player;
@property (weak, nonatomic) IBOutlet UIView                 *videoPlayerPreview;

- (void)displayFrameAtIndex:(NSInteger)frameindex;

@end
