//
//  OSVSequenceSectionHeaderView.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 19/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVSequenceSectionHeaderView.h"

@interface OSVSequenceSectionHeaderView ()

@property (nonatomic, strong) IBOutlet UIButton *disclosureButton;

@end

@implementation OSVSequenceSectionHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(toggleOpen:)];
    [self addGestureRecognizer:tapGesture];

}

- (IBAction)toggleOpen:(id)sender {
    
    [self toggleOpenWithUserAction:YES];
}

- (void)toggleOpenWithUserAction:(BOOL)userAction {
    
    BOOL shouldAct = YES;
    // if this was a user action, send the delegate the appropriate message
    if (userAction) {
       shouldAct = self.action(self, !self.disclosureButton.selected);
    }

    if (!shouldAct) {
        return;
    }
    
    // toggle the disclosure button state
    if (self.disclosureButton.selected) {
        [self open];
    } else {
        [self close];
    }
}

- (void)open {
//    self.leadingSeparatorConstrain.constant = 50;
    self.disclosureButton.selected = YES;
    [self setNeedsDisplay];
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

- (void)close {
//    self.leadingSeparatorConstrain.constant = 0;
    self.disclosureButton.selected = NO;
    [self setNeedsDisplay];
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

- (void)prepareForReuse {
    self.modelObject = nil;
}
@end
