//
//  OSVRankCell.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 17/11/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVRankCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *rank;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *points;

@end
