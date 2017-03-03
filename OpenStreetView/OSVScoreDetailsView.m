//
//  OSVScoreDetailsView.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 09/12/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVScoreDetailsView.h"

@implementation OSVScoreDetailsView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.multiplier1Label.hidden = YES;
    self.multiplier2Label.hidden = YES;
    self.multiplier3Label.hidden = YES;
    self.multiplier4Label.hidden = YES;
    self.multiplier5Label.hidden = YES;
    self.multiplier6Label.hidden = YES;

    self.distance1Label.hidden = YES;
    self.distance2Label.hidden = YES;
    self.distance3Label.hidden = YES;
    self.distance4Label.hidden = YES;
    self.distance5Label.hidden = YES;
    self.distance6Label.hidden = YES;
    
    self.points1Label.hidden = YES;
    self.points2Label.hidden = YES;
    self.points3Label.hidden = YES;
    self.points4Label.hidden = YES;
    self.points5Label.hidden = YES;
    self.points6Label.hidden = YES;
    
    self.disclosureLabel.hidden = YES;
    
    self.distanceLabels = @[self.distance1Label,
                            self.distance2Label,
                            self.distance3Label,
                            self.distance4Label,
                            self.distance5Label,
                            self.distance6Label];
    self.multiplierLabels = @[ self.multiplier1Label,
                               self.multiplier2Label,
                               self.multiplier3Label,
                               self.multiplier4Label,
                               self.multiplier5Label,
                               self.multiplier6Label];
    self.pointsLabels = @[ self.points1Label,
                           self.points2Label,
                           self.points3Label,
                           self.points4Label,
                           self.points5Label,
                           self.points6Label];
}



@end
