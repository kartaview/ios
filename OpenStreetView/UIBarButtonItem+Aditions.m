//
//  UIBarButtonItem+Aditions.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 21/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "UIBarButtonItem+Aditions.h"

@implementation UIBarButtonItem (Aditions)

+ (UIBarButtonItem *)barButtonItemWithImageName:(NSString *)imageName target:(id)target action:(SEL)action {
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:imageName] style:UIBarButtonItemStylePlain target:target action:action];
    barButton.tintColor = [UIColor blackColor];

    return barButton;
}

@end
