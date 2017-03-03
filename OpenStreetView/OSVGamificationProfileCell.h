//
//  OSVGamificationProfileCell.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 22/11/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KAProgressLabel.h"

@interface OSVGamificationProfileCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel            *nextLevelPoints;
@property (weak, nonatomic) IBOutlet UILabel            *rankLabel;
@property (weak, nonatomic) IBOutlet UILabel            *scoreLabel;
@property (weak, nonatomic) IBOutlet KAProgressLabel    *progressView;
@property (weak, nonatomic) IBOutlet UILabel            *progressLabel;

@property (weak, nonatomic) IBOutlet UILabel            *scoreTextLabel;
@property (weak, nonatomic) IBOutlet UILabel            *rankTextLabel;
@property (weak, nonatomic) IBOutlet UIView             *rankView;

@property (copy, nonatomic) void (^didTapRank)(id view);

@end
