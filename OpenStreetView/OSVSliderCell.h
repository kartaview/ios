//
//  OSVSliderCell.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 28/01/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVSliderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel    *titleLabel;
@property (weak, nonatomic) IBOutlet UISlider   *slider;
@property (weak, nonatomic) IBOutlet UILabel    *subTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel    *sizeLabel;

@property (copy, nonatomic) void (^didChangeValue)(UISlider *slider);

@end
