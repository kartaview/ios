//
//  OSVSettingsMenuFactory.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSVMenuItem.h"
#import "OSVSectionItem.h"

@interface OSVSettingsMenuFactory : NSObject

+ (NSArray *)settingsMenuWithWiFiOBDStatus:(int)connectionStatus
                                 BLEStatus:(int)bleStat
                          enableSecretMenu:(BOOL)secretMenu;

+ (OSVSectionItem *)settingsSection;

@end
