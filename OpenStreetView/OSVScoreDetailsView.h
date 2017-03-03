//
//  OSVScoreDetailsView.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 09/12/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVScoreDetailsView : UIView

@property (weak, nonatomic) IBOutlet UILabel *totalPointsLabel;
@property (weak, nonatomic) IBOutlet UILabel *disclosureLabel;

@property (weak, nonatomic) IBOutlet UILabel *distanceTitle;
@property (weak, nonatomic) IBOutlet UILabel *multiplierTitle;
@property (weak, nonatomic) IBOutlet UILabel *pointsTitle;

@property (weak, nonatomic) IBOutlet UILabel *distance1Label;
@property (weak, nonatomic) IBOutlet UILabel *distance2Label;
@property (weak, nonatomic) IBOutlet UILabel *distance3Label;
@property (weak, nonatomic) IBOutlet UILabel *distance4Label;
@property (weak, nonatomic) IBOutlet UILabel *distance5Label;
@property (weak, nonatomic) IBOutlet UILabel *distance6Label;

@property (strong, nonatomic) NSArray<UILabel *> *distanceLabels;

@property (weak, nonatomic) IBOutlet UILabel *multiplier1Label;
@property (weak, nonatomic) IBOutlet UILabel *multiplier2Label;
@property (weak, nonatomic) IBOutlet UILabel *multiplier3Label;
@property (weak, nonatomic) IBOutlet UILabel *multiplier4Label;
@property (weak, nonatomic) IBOutlet UILabel *multiplier5Label;
@property (weak, nonatomic) IBOutlet UILabel *multiplier6Label;

@property (strong, nonatomic) NSArray<UILabel *> *multiplierLabels;

@property (weak, nonatomic) IBOutlet UILabel *points1Label;
@property (weak, nonatomic) IBOutlet UILabel *points2Label;
@property (weak, nonatomic) IBOutlet UILabel *points3Label;
@property (weak, nonatomic) IBOutlet UILabel *points4Label;
@property (weak, nonatomic) IBOutlet UILabel *points5Label;
@property (weak, nonatomic) IBOutlet UILabel *points6Label;

@property (strong, nonatomic) NSArray<UILabel *> *pointsLabels;

@end
