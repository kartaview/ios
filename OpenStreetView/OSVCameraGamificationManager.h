//
//  OSVCameraGamificationManager.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 01/02/2017.
//  Copyright © 2017 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OSVCameraManager.h"

@class OSVCamViewController;

typedef enum  {
    UIGamificationStateMultiplier           = 1 << 0,
    UIGamificationStateNoCoverageCollappsed = 1 << 1,
    UIGamificationStateNoCoverage           = 1 << 2,
    UIGamificationStateScore                = 1 << 3,
    UIGamificationStateNotVisible           = 1 << 4,
    UIGamificationStateWillChange           = 1 << 5,
}UIGamificationState;

typedef enum {
    UIGamificationAnimationStart,
    UIGamificationAnimationContinue,
    UIGamificationAnimationStop
}UIGamificationAnimation;

@interface OSVCameraGamificationManager : NSObject

@property (weak, nonatomic) IBOutlet UIImageView            *multiplierTipImage;
@property (weak, nonatomic) IBOutlet UILabel                *multiplierTipLabel;

@property (weak, nonatomic) IBOutlet UIImageView            *multiplierLandscapeImage;
@property (weak, nonatomic) IBOutlet UIImageView            *animationImage;
@property (weak, nonatomic) IBOutlet UIImageView            *pointsRecordingImage;
@property (weak, nonatomic) IBOutlet UILabel                *multiplierLabel;
@property (weak, nonatomic) IBOutlet UIImageView            *pointsBackgroundImage;

@property (weak, nonatomic) IBOutlet UILabel                *scoreLabel;

@property (weak, nonatomic) IBOutlet UIView                 *clippingView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint     *clippingLeading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint     *leadingMultiplierImage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint     *trailingLandscapeImage;

@property (nonatomic, strong) OSVCameraManager              *cameraManager;

@property (assign, nonatomic) BOOL                          animatingGamification;
@property (weak, nonatomic) IBOutlet UIView                 *scoreView;

@property (weak, nonatomic) id<OSVCameraManagerDelegate>    delegate;

- (void)prepareFirstTimeUse;
- (void)stopRecording;
- (void)changeMultiplierAnimation;
- (void)noCoverageData;
- (void)didLoadNewTracks;
- (void)expandMultiplier;
- (void)willDissmiss;

- (void)configureUIForInterfaceOrientation:(UIInterfaceOrientation)orientation;
- (void)configureUIForDeviceOrientation:(UIDeviceOrientation)orientation;

- (void)updateUIInfo;

@end
