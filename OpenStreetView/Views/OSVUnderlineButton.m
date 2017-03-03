//
//  OSVUnderlineButton.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 17/11/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVUnderlineButton.h"

@interface OSVUnderlineButton ()

@property (nonatomic, strong) UIView    *underline;

@end

@implementation OSVUnderlineButton

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
 
    self.underline = [UIView new];
    self.underline.backgroundColor = [UIColor whiteColor];
    self.underline.hidden = !self.selected;
    
    [self addSubview:self.underline];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.underline.frame = CGRectMake(0, self.frame.size.height - 2, self.frame.size.width, 2);
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.underline.hidden = !selected;
}

@end
