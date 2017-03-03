//
//  OSVCameraGamificationManager.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 01/02/2017.
//  Copyright © 2017 Bogdan Sala. All rights reserved.
//

#import "OSVCameraGamificationManager.h"
#import "OSVCamViewController.h"
#import "OSVUserDefaults.h"
#import "OSVLogger.h"
#import "NSAttributedString+Additions.h"
#import "OSVLocationManager.h"

@interface OSVCameraGamificationManager ()

@property (assign, nonatomic) UIGamificationState   gamificationState;

@end

@implementation OSVCameraGamificationManager

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLoadNewTracks) name:@"kdidLoadNewBox" object:nil];
    }
    return self;
}

- (void)didLoadNewTracks {
    if (![OSVUserDefaults sharedInstance].useGamification){
        return;
    }
    
    if (self.gamificationState & UIGamificationStateNotVisible) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.scoreView.hidden = NO;
            [self.delegate didReceiveUIUpdate];
            //DebugAnimation NSLog(@"set UIGamificationStateWillChange 4");
            self.gamificationState = UIGamificationStateWillChange;
            //DebugAnimation NSLog(@"didLoadNewTracks A");
            [self appeareScoreWithCompletion:^{
                //DebugAnimation NSLog(@"set UIGamificationStateMultiplier 1");
                self.gamificationState = UIGamificationStateMultiplier;
            } animationState:UIGamificationAnimationStart];
        });
    } else if (self.gamificationState & UIGamificationStateNoCoverage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //DebugAnimation NSLog(@"set UIGamificationStateWillChange 5");
            self.gamificationState = UIGamificationStateWillChange;
            //DebugAnimation NSLog(@"didLoadNewTracks B");
            [self colapseScoreWithCompletion:^{
                [self appeareScoreWithCompletion:^{
                    //DebugAnimation NSLog(@"set UIGamificationStateScore 55");
                    self.gamificationState = UIGamificationStateScore;
                } animationState:UIGamificationAnimationStop];
            } animationState:UIGamificationAnimationStart];
        });
    }
}

- (void)noCoverageData {
    if (self.gamificationState == UIGamificationStateScore) {
        //DebugAnimation NSLog(@"set UIGamificationStateWillChange 2");
        self.gamificationState = UIGamificationStateWillChange;
        //DebugAnimation NSLog(@"NO DATA A");
        [self appeareNoCoverageWithCompletion:^{
            //DebugAnimation NSLog(@"set UIGamificationStateNoCoverage");
            self.gamificationState = UIGamificationStateNoCoverage;
        } animationState:UIGamificationAnimationStart];
    } else if (self.gamificationState == UIGamificationStateMultiplier) {
        //DebugAnimation NSLog(@"set UIGamificationStateWillChange 1");
        self.gamificationState = UIGamificationStateWillChange;
        //DebugAnimation NSLog(@"NO DATA B");
        [self animateNoCoverateWithCompletion:^{
            //DebugAnimation NSLog(@"set UIGamificationStateNoCoverage");
            self.gamificationState = UIGamificationStateNoCoverage;
        } animationState:UIGamificationAnimationStart];
    }
}

- (void)expandMultiplier {
    if (self.gamificationState & UIGamificationStateMultiplier) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self increaseScoreWithCompletion:^{
                //DebugAnimation NSLog(@"set UIGamificationStateScore -1");
                self.gamificationState = UIGamificationStateScore;
            } animationState:UIGamificationAnimationStart];
        });
    }
}

- (void)willDissmiss {
    if (self.gamificationState & UIGamificationStateMultiplier) {
        self.clippingView.hidden = YES;
    }
}

- (void)configureUIForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    self.clippingView.hidden = !UIInterfaceOrientationIsPortrait(orientation);
    self.animationImage.hidden = !UIInterfaceOrientationIsPortrait(orientation);
    self.pointsRecordingImage.hidden = UIInterfaceOrientationIsPortrait(orientation);
    self.multiplierLandscapeImage.hidden = UIInterfaceOrientationIsPortrait(orientation);
}

- (void)configureUIForDeviceOrientation:(UIDeviceOrientation)orientation {
    self.clippingView.hidden = UIDeviceOrientationIsLandscape(orientation);
    self.animationImage.hidden = UIDeviceOrientationIsLandscape(orientation);
    self.pointsRecordingImage.hidden = !UIDeviceOrientationIsLandscape(orientation);
    self.multiplierLandscapeImage.hidden = !UIDeviceOrientationIsLandscape(orientation);
}

- (void)prepareFirstTimeUse {
    self.scoreView.hidden = YES;
    
    if ([OSVUserDefaults sharedInstance].useGamification){
        self.multiplierTipLabel.text = NSLocalizedString(@"You will get more points when the streets have less coverage!", @"");
        
        //DebugAnimation NSLog(@"set UIGamificationStateNotVisible");
        self.gamificationState = UIGamificationStateNotVisible;
        [self colapseScoreWithCompletion:^{}
                          animationState:UIGamificationAnimationStart];
    }
}

- (void)stopRecording {
    //DebugAnimation NSLog(@"set UIGamificationStateWillChange 3");
    self.gamificationState = UIGamificationStateWillChange;
    [self colapseScoreWithCompletion:^{
        //DebugAnimation NSLog(@"set UIGamificationStateMultiplier 2");
        self.gamificationState = UIGamificationStateMultiplier;
    } animationState:UIGamificationAnimationStart];
}

- (void)changeMultiplierAnimation {
    if (self.gamificationState == UIGamificationStateScore) {
        //DebugAnimation NSLog(@"set UIGamificationStateWillChange 22");
        self.gamificationState = UIGamificationStateWillChange;
        [self enlageMultiplyerWithCompletion:^{
            [self diminishMultiplyerWithCompletion:^{
                //DebugAnimation NSLog(@"set UIGamificationStateScore 22");
                self.gamificationState = UIGamificationStateScore;
            } animationState:UIGamificationAnimationStop];
        } animationState:UIGamificationAnimationStart];
    }
}

- (void)setGamificationState:(UIGamificationState)gamificationState {
    //    NSLog(@"pre setGamiState:%d", _gamificationState);
    //    NSLog(@"post setGamiState:%d", gamificationState);
    
    _gamificationState = gamificationState;
}

- (void)appeareScoreWithCompletion:(void (^)(void))completion animationState:(UIGamificationAnimation)state {
    //DebugAnimation NSLog(@"appear score");
    if (state == UIGamificationAnimationStart && self.animatingGamification) {
        //DebugAnimation NSLog(@"block appear score");
        
        return;
    }
    self.animatingGamification = YES;
    
    [self appeareMultiplierWithCompletion:^{
        if (self.cameraManager.isRecording) {
            [self increaseScoreWithCompletion:^{
                
                self.animatingGamification = state == UIGamificationAnimationContinue;
                //DebugAnimation NSLog(@"EnD appear score A");
                
                completion();
            } animationState:UIGamificationAnimationContinue];
        } else {
            self.animatingGamification = state == UIGamificationAnimationContinue;
            //DebugAnimation NSLog(@"EnD appear score B");
            completion();
        }
    } animationState:UIGamificationAnimationContinue];
}

- (void)appeareMultiplierWithCompletion:(void (^)(void))completion animationState:(UIGamificationAnimation)state {
    //DebugAnimation NSLog(@"appear multiplier");
    if (state == UIGamificationAnimationStart && self.animatingGamification) {
        //DebugAnimation NSLog(@"block appear multiplier");
        return;
    }
    self.animatingGamification = YES;
    
    self.animationImage.image = [UIImage imageNamed:@"multiplier"];
    self.multiplierLandscapeImage.image = self.animationImage.image;
    self.pointsBackgroundImage.image = [UIImage imageNamed:@"pointsRecording"];
    self.pointsRecordingImage.image = self.pointsBackgroundImage.image;
    self.pointsBackgroundImage.alpha = 0;
    self.pointsRecordingImage.alpha = 0;
    self.animationImage.alpha = 0;
    self.multiplierLabel.alpha = 0;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.multiplierLabel.alpha = 1;
        self.animationImage.alpha = 1;
    } completion:^(BOOL finished) {
        [self enlageMultiplyerWithCompletion:^{
            [self diminishMultiplyerWithCompletion:^{
                
                self.animatingGamification = state == UIGamificationAnimationContinue;
                //DebugAnimation NSLog(@"End appear multiplier");
                
                completion();
            } animationState:UIGamificationAnimationContinue];
        } animationState:UIGamificationAnimationContinue];
    }];
}

- (void)appeareNoCoverageWithCompletion:(void (^)(void))completion animationState:(UIGamificationAnimation)state {
    //DebugAnimation NSLog(@"appeareNoCoverage");
    if (state == UIGamificationAnimationStart && self.animatingGamification) {
        //DebugAnimation NSLog(@"block appeareNoCoverage");
        return;
    }
    self.animatingGamification = YES;
    
    [self colapseScoreWithCompletion:^{
        [self animateNoCoverateWithCompletion:^{
            self.animatingGamification = state == UIGamificationAnimationContinue;
            //DebugAnimation NSLog(@"EnD appeareNoCoverage");
            completion();
        } animationState:UIGamificationAnimationContinue];
    } animationState:UIGamificationAnimationContinue];
}

- (void)animateNoCoverateWithCompletion:(void (^)(void))completion animationState:(UIGamificationAnimation)state {
    //DebugAnimation NSLog(@"animateNoCoverate");
    if (state == UIGamificationAnimationStart && self.animatingGamification) {
        //DebugAnimation NSLog(@"block animateNoCoverate");
        return;
    }
    self.animatingGamification = YES;
    
    self.multiplierLabel.alpha = 0;
    
    [UIView transitionWithView:self.scoreView duration:0.3f
                       options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                           self.animationImage.image = [UIImage imageNamed:@"noWifi"];
                           self.multiplierLandscapeImage.image = self.animationImage.image;
                       } completion:^(BOOL finished) {
                           self.pointsBackgroundImage.image = [UIImage imageNamed:@"inactivePoints"];
                           self.pointsRecordingImage.image = self.pointsBackgroundImage.image;
                           [self enlageMultiplyerWithCompletion:^{
                               [self diminishMultiplyerWithCompletion:^{
                                   [self increaseScoreWithCompletion:^{
                                       self.animatingGamification = state == UIGamificationAnimationContinue;
                                       //DebugAnimation NSLog(@"EnD animateNoCoverate");
                                       completion();
                                   } animationState:UIGamificationAnimationContinue];
                               } animationState:UIGamificationAnimationContinue];
                           } animationState:UIGamificationAnimationContinue];
                       }];
}


- (void)colapseScoreWithCompletion:(void (^)(void))completion animationState:(UIGamificationAnimation)state {
    //DebugAnimation NSLog(@"coloapse Score");
    
    if (!(self.gamificationState & (UIGamificationStateScore|
                                    UIGamificationStateNoCoverage|
                                    UIGamificationStateNotVisible|
                                    UIGamificationStateWillChange))) {
        
        //DebugAnimation NSLog(@"block coloapse Score A");
        return;
    }
    
    if (state == UIGamificationAnimationStart && self.animatingGamification) {
        //DebugAnimation NSLog(@"block coloapse Score B");
        return;
    }
    self.animatingGamification = YES;
    
    self.clippingLeading.constant = self.scoreView.frame.size.height / 2.0;
    [UIView animateWithDuration:0.1 animations:^{
        [self.scoreView setNeedsLayout];
        [self.scoreView layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        [self.delegate didReceiveUIUpdate];
        self.scoreLabel.hidden = YES;
        self.leadingMultiplierImage.constant = self.scoreView.frame.size.width - self.scoreView.frame.size.height;
        
        self.clippingLeading.constant = self.scoreView.frame.size.width - self.scoreView.frame.size.height / 2.0;
        self.trailingLandscapeImage.constant = self.scoreView.frame.size.width - 44;
        
        [UIView animateWithDuration:0.3 animations:^{
            [self.clippingView setNeedsLayout];
            [self.clippingView layoutIfNeeded];
            [self.pointsRecordingImage setNeedsLayout];
            [self.pointsRecordingImage layoutIfNeeded];
            [self.scoreView setNeedsLayout];
            [self.scoreView layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.clippingLeading.constant = self.scoreView.frame.size.width;
            self.animatingGamification = state == UIGamificationAnimationContinue;
            //DebugAnimation NSLog(@"EnD coloapse Score");
            completion();
        }];
    }];
}


- (void)increaseScoreWithCompletion:(void (^)(void))completion animationState:(UIGamificationAnimation)state {
    //DebugAnimation NSLog(@"incresee Score");
    if (state == UIGamificationAnimationStart && self.animatingGamification) {
        //DebugAnimation NSLog(@"block incresee Score");
        return;
    }
    self.animatingGamification = YES;
    
    self.clippingLeading.constant = self.scoreView.frame.size.height / 2.0;
    self.leadingMultiplierImage.constant = 0;
    self.trailingLandscapeImage.constant = 0;
    
    [UIView animateWithDuration:0.6
                          delay:0.0
         usingSpringWithDamping:0.3
          initialSpringVelocity:0.75
                        options:UIViewAnimationOptionCurveEaseInOut animations:^{
                            [self.clippingView setNeedsLayout];
                            [self.clippingView layoutIfNeeded];
                            [self.pointsRecordingImage setNeedsLayout];
                            [self.pointsRecordingImage layoutIfNeeded];
                            [self.scoreView setNeedsLayout];
                            [self.scoreView layoutIfNeeded];
                        }
                     completion:^(BOOL finished) {
                         self.scoreLabel.hidden = NO;
                         [self.delegate didReceiveUIUpdate];
                         self.clippingLeading.constant = 0;
                         self.animatingGamification = state == UIGamificationAnimationContinue;
                         //DebugAnimation NSLog(@"EnD incresee Score");
                         
                         completion();
                     }];
}

- (void)enlageMultiplyerWithCompletion:(void (^)(void))completion animationState:(UIGamificationAnimation)state {
    //DebugAnimation NSLog(@"Enlarge");
    if (state == UIGamificationAnimationStart && self.animatingGamification) {
        //DebugAnimation NSLog(@"block enlarge");
        return;
    }
    self.animatingGamification = YES;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.multiplierLabel.transform = CGAffineTransformMakeScale(1.5, 1.5);
        self.animationImage.transform = CGAffineTransformMakeScale(1.5, 1.5);
        self.multiplierLandscapeImage.transform = CGAffineTransformMakeScale(1.5, 1.5);
    } completion:^(BOOL finished) {
        self.animatingGamification = state == UIGamificationAnimationContinue;
        //DebugAnimation NSLog(@"End enlarge");
        completion();
    }];
}

- (void)diminishMultiplyerWithCompletion:(void (^)(void))completion animationState:(UIGamificationAnimation)state {
    //DebugAnimation NSLog(@"dmininish");
    if (state == UIGamificationAnimationStart && self.animatingGamification) {
        
        //DebugAnimation NSLog(@"blick dmininish");
        return;
    }
    self.animatingGamification = YES;
    
    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:0.15
          initialSpringVelocity:0.7
                        options:UIViewAnimationOptionCurveLinear animations:^{
                            self.multiplierLabel.transform = CGAffineTransformIdentity;
                            self.animationImage.transform = CGAffineTransformIdentity;
                            self.multiplierLandscapeImage.transform = CGAffineTransformIdentity;
                        } completion:^(BOOL finished) {
                            self.pointsBackgroundImage.alpha = 1;
                            self.pointsRecordingImage.alpha = 1;
                            
                            self.animatingGamification = state == UIGamificationAnimationContinue;
                            //DebugAnimation NSLog(@"End dmininish");
                            completion();
                        }];
}

- (IBAction)didTapMultiplier:(id)sender {
    if (self.multiplierTipImage.hidden) {
        
        self.multiplierTipImage.hidden = NO;
        self.multiplierTipLabel.superview.hidden = NO;
        self.multiplierTipImage.alpha = 0;
        self.multiplierTipLabel.superview.alpha = 0;
        NSInteger i = self.multiplierTipImage.tag;
        
        [UIView animateWithDuration:0.4 animations:^{
            self.multiplierTipImage.alpha = 1;
            self.multiplierTipLabel.superview.alpha = 1;
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (i == self.multiplierTipImage.tag) {
                [UIView animateWithDuration:0.4 animations:^{
                    self.multiplierTipImage.alpha = 0;
                    self.multiplierTipLabel.superview.alpha = 0;
                } completion:^(BOOL finished) {
                    self.multiplierTipImage.hidden = YES;
                    self.multiplierTipLabel.superview.hidden = YES;
                }];
            }
        });
        
    } else {
        self.multiplierTipImage.alpha = 1;
        self.multiplierTipLabel.superview.alpha = 1;
        self.multiplierTipImage.tag += 1;
        
        [UIView animateWithDuration:0.4 animations:^{
            self.multiplierTipImage.alpha = 0;
            self.multiplierTipLabel.superview.alpha = 0;
        } completion:^(BOOL finished) {
            self.multiplierTipImage.hidden = YES;
            self.multiplierTipLabel.superview.hidden = YES;
        }];
    }
}

- (void)updateUIInfo {
    self.scoreLabel.attributedText = [NSAttributedString combineString:[NSString stringWithFormat:@"%.f", self.cameraManager.score]  withSize:18.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                            withString:NSLocalizedString(@" pts", nil) withSize:12.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                        adjustBaseline:YES];
    
    
    NSAttributedString *multiplierString = [NSAttributedString combineString:NSLocalizedString(@"X ", nil)  withSize:10.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                                  withString:[@(self.cameraManager.multiplier) stringValue] withSize:18.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"adjustBaseline:YES];
    if (![self.multiplierLabel.attributedText isEqual:multiplierString]) {
        [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"multiplier changed:%@", multiplierString.string]  withLevel:LogLevelDEBUG];
        self.multiplierLabel.attributedText = multiplierString;
        [self changeMultiplierAnimation];
    }
    
    if (self.cameraManager.hasCoverage) {
        [self didLoadNewTracks];
    } else {
        [self noCoverageData];
    }
}

@end
