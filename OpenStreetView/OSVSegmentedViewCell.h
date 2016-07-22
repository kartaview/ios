//
//  OSVSegmentedViewCell.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 18/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVSegmentedViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControll;
@property (weak, nonatomic) IBOutlet UILabel            *titleLable;
@property (weak, nonatomic) IBOutlet UILabel            *subTitleLabel;

@property (copy, nonatomic) void (^toggleBlock)(NSInteger index);

@end
