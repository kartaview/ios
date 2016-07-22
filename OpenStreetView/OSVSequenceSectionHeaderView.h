//
//  OSVSequenceSectionHeaderView.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 19/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVSequenceSectionHeaderView : UITableViewHeaderFooterView

@property (copy, nonatomic) BOOL (^action)(OSVSequenceSectionHeaderView *sender, BOOL open);
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *details;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingSeparatorConstrain;

@property (strong, nonatomic) id modelObject;

- (void)open;
- (void)close;

@end
