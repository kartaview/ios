//
//  OSVGamificationProfileCell.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 22/11/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVGamificationProfileCell.h"
#import "UIColor+OSVColor.h"

@implementation OSVGamificationProfileCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.progressView.trackWidth = 6;
    self.progressView.borderWidth = 1;
    self.progressView.trackColor = [UIColor colorWithHex:0x80cee9];
    self.progressView.borderColor = [UIColor colorWithHex:0x80cee9];
    self.progressView.progressWidth = self.progressView.trackWidth;
    self.progressView.progressColor = [UIColor whiteColor];
    self.progressView.startRoundedCornersWidth = 0;
    self.progressView.endRoundedCornersWidth = self.progressView.trackWidth * 3;
    self.progressView.startDegree = 0;
    self.progressView.endDegree = 0;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapRankView)];
    tap.numberOfTapsRequired = 1;
    
    [self.rankView addGestureRecognizer:tap];
}

- (void)didTapRankView {
    if (self.didTapRank) {
        self.didTapRank(self.rankView);
    }
}

@end
