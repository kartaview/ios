//
//  OSVSensorLibManager.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 07/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//


#import "OSVSensorLibManager.h"
#import <UIKit/UIKit.h>

#import "OSVUserDefaults.h"
#import "OSVUtils.h"
#import "OSVLocationManager.h"

#import "OSVLogger.h"

#import "OSVUtils.h"



@interface OSVSensorLibManager ()

@property(strong, nonatomic) dispatch_queue_t	imageProcessingQueue;
@property (strong, nonatomic) NSString			*basePath;

@end




@implementation OSVSensorLibManager

+ (instancetype)sharedInstance {
    static id sharedInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {

    }
    
    return self;
}

- (void)speedLimitsFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
                     withCompletion:(void (^)(NSArray *, CVImageBufferRef pixelsBuffer))completion {

}

- (UIImage *)imageForSpeedLimit:(NSString *)speedLimit {
    NSString *slBundle = [[[NSBundle mainBundle] resourcePath]
                          stringByAppendingPathComponent:@"SKSensorLibBundle.bundle/"];
    NSString *imagename =
    [slBundle stringByAppendingFormat:@"/%@.png", speedLimit];
    
    return [UIImage imageNamed:imagename];
}

- (void)createNewTrackWithInfo:(NSDictionary *)info trackID:(NSInteger)trackID {
	
	self.basePath = [OSVUtils fileNameForTrackID:trackID].absoluteString;


}
	


	
- (void)addPhotoWithInfo:(NSDictionary *)info withFrameIndex:(NSInteger)frameIndex {

}

- (void)read {


}
	

	
	
@end
