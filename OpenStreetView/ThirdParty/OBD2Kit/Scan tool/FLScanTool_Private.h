//
//  FLScanTool_Private.h
//  OBD2Kit
//
//  Created by Alko on 13/11/13.
//
//

#import "FLScanTool.h"

typedef NSArray* (^SensorsBlock)(void);

@interface FLScanTool ()

@property (nonatomic, copy) SensorsBlock sensorsBlock;

- (void)didReceiveResponses:(NSArray*)responses;

@end
