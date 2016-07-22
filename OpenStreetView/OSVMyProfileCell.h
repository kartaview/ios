//
//  OSVMyProfileCell.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 06/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVMyProfileCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *globalRankTitle;
@property (weak, nonatomic) IBOutlet UILabel *localRankTitle;

@property (weak, nonatomic) IBOutlet UILabel *globalRank;
@property (weak, nonatomic) IBOutlet UILabel *localRank;

@end
