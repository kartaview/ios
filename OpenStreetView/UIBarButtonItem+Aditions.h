//
//  UIBarButtonItem+Aditions.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 21/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBarButtonItem (Aditions)

+ (UIBarButtonItem *)barButtonItemWithImageName:(NSString *)imageName target:(id)target action:( SEL)action;

@end
