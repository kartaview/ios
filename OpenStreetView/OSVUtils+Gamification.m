//
//  OSVUtils_Gamification.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 16/01/2017.
//  Copyright © 2017 Bogdan Sala. All rights reserved.
//

#import "OSVUtils.h"

@implementation OSVUtils (Gamification)

+ (NSString *)pointsFormatedFromPoints:(NSInteger)points {
    NSString *formated = @"";
    if (points > 9999) {

        while (points > 1000) {
            NSInteger grup = points % 1000;
            points = points/1000;
            if (formated.length > 0) {
                formated = [NSString stringWithFormat:@"%03ld %@", (long)grup, formated];
            } else {
                formated = [NSString stringWithFormat:@"%03ld", (long)grup];
            }
        }
        
        NSInteger grup = points % 1000;
        formated = [[@(grup) stringValue] stringByAppendingFormat:@" %@", formated];

    } else {
        formated = [@(points) stringValue];
    }
    
    return formated;
}

@end
