//
//  SKSearchResult+Aditions.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 21/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "SKSearchResult+Aditions.h"

@implementation SKSearchResult (Aditions)

- (NSString *)fullNameFromParrentList {
    NSString *state;
    NSString *street;
    NSString *number;
    NSString *locality;
    
    for (SKSearchResultParent *parent in self.parentSearchResults) {
        switch (parent.type) {
            case SKSearchResultCity:
                locality = parent.name;
                break;
            case SKSearchResultState:
                state = parent.name;
                break;
            case SKSearchResultStreet:
                street = parent.name;
                break;
            case SKSearchResultHouseNumber:
                number = parent.name;
                break;
            default:
                break;
        }
    }
    
    NSString *fullstring = @"";
    if (self.name && self.type == SKSearchResultStreet) {
        fullstring = [fullstring stringByAppendingString:[NSString stringWithFormat:@"%@, ", self.name]];
    } else if (street) {
        fullstring = [fullstring stringByAppendingString:[NSString stringWithFormat:@"%@, ", street]];
    }
    
    if (number) {
        fullstring = [fullstring stringByAppendingString:[NSString stringWithFormat:@"%@, ", number]];
    }
    if (locality) {
        fullstring = [fullstring stringByAppendingString:[NSString stringWithFormat:@"%@, ", locality]];
    }
    
    if (state) {
        fullstring = [fullstring stringByAppendingString:[NSString stringWithFormat:@"%@, ", state]];
    }

    fullstring = [fullstring substringToIndex:fullstring.length-(2*(fullstring.length>0))];
    
    return fullstring;
}


@end
