//
//  OSVMenuItem.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    OSVMenuItemBasic,
    OSVMenuItemSwitch,
    OSVMenuItemSlider,
    OSVMenuItemSegmentedControll,
    OSVMenuItemUpload,
    OSVMenuItemButton,
    OSVMenuItemAction,
    OSVMenuItemDetails,
    OSVMenuItemOption,
} OSVMenuItemType;

@interface OSVMenuItem : NSObject

@property (strong, nonatomic) NSString          *title;
@property (strong, nonatomic) NSString          *subtitle;

@property (assign, nonatomic) OSVMenuItemType   type;
@property (assign, nonatomic) NSString          *key;

@property (strong, nonatomic) NSDictionary      *additional;

@property (copy, nonatomic) void (^action)(id sender, id info);

@end
