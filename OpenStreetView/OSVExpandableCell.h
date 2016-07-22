//
//  OSVExpandableCell.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 18/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OSVExpandableCellDelegate;

@interface OSVExpandableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel                *title;
@property (weak, nonatomic) IBOutlet UIView                 *rightImageView;

@property (copy, nonatomic) void (^action)(OSVExpandableCell *sender);

@end
