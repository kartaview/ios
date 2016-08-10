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
#import <SKMaps/SKPositionerService.h>

#import "OSVLogger.h"


@interface OSVSensorLibManager ()

@property(strong, nonatomic) dispatch_queue_t imageProcessingQueue;

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
        self.imageProcessingQueue = dispatch_queue_create("ImageProcessQueue", DISPATCH_QUEUE_SERIAL);
        
        __weak typeof(self) welf = self;
        
        dispatch_async(self.imageProcessingQueue, ^{
            if ([OSVUtils isUSCoordinate:[SKPositionerService sharedInstance].currentCoordinate] ||
                [OSVUserDefaults sharedInstance].debugSLUS) {
                NSLog(@"is US");
                //initialize a library to detect signs for US
            } else {
                NSLog(@"is EU");
                //initialize a library to detect signs for EU
            }
            //some other settup for the library
            welf.isProcessing = NO;
        });
    }
    
    return self;
}

- (void)speedLimitsFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
                     withCompletion:(void (^)(NSArray *, CVImageBufferRef pixelsBuffer))completion {
    
    if (self.isProcessing) {
        return;
    }
    
    self.isProcessing = YES;
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVBufferRetain(imageBuffer);
    
    NSMutableArray *signs = [NSMutableArray array];
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Processing here
    const int buffer_width = static_cast<int>(CVPixelBufferGetWidth(imageBuffer));
    const int buffer_height =
    static_cast<int>(CVPixelBufferGetHeight(imageBuffer));
    
    unsigned char *pixel =
    static_cast<unsigned char *>(CVPixelBufferGetBaseAddress(imageBuffer));
    
    // put buffer in open cv, no memory copied
    __weak typeof(self) welf = self;

    dispatch_async(self.imageProcessingQueue, ^{
        @autoreleasepool {
            CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
            //Process image buffer in order to get the signs
            
            completion(signs, imageBuffer);
            welf.isProcessing = NO;
            CVBufferRelease(imageBuffer);
        }
    });
    
}

- (UIImage *)imageForSpeedLimit:(NSString *)speedLimit {
    NSString *slBundle = [[[NSBundle mainBundle] resourcePath]
                          stringByAppendingPathComponent:@"SKSensorLibBundle.bundle/"];
    NSString *imagename =
    [slBundle stringByAppendingFormat:@"/%@.png", speedLimit];
    
    return [UIImage imageNamed:imagename];
}

#pragma mark - private

- (UIImage *)UIImageFromPixelBuffer:(CVPixelBufferRef)imageBuffer {
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    void *bufferAddress;
    size_t width;
    size_t height;
    size_t bytesPerRow;
        
    bufferAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    width = CVPixelBufferGetWidth(imageBuffer);
    height = CVPixelBufferGetHeight(imageBuffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    CGColorSpaceRef colorSpaceOrig;
    CGImage *origImage;
    
    colorSpaceOrig = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef origContext = CGBitmapContextCreate(
                                                     bufferAddress, width, height, 8, bytesPerRow, colorSpaceOrig,
                                                     kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    
    origImage = CGBitmapContextCreateImage(origContext);
    
    CGColorSpaceRelease(colorSpaceOrig);
    CGContextRelease(origContext);
    
    UIImage *originalUIImage = [UIImage imageWithCGImage:origImage];
    
    CGImageRelease(origImage);
    
    // Cleanup and free the buffers
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    return originalUIImage;
}

//- (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat {
//    NSData *data =
//    [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
//    CGColorSpaceRef colorSpace;
//    
//    if (cvMat.elemSize() == 1) {
//        colorSpace = CGColorSpaceCreateDeviceGray();
//    } else {
//        colorSpace = CGColorSpaceCreateDeviceRGB();
//    }
//    
//    CGDataProviderRef provider =
//    CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
//    
//    // Creating CGImage from cv::Mat
//    CGImageRef imageRef = CGImageCreate(
//                                        cvMat.cols,                                    // width
//                                        cvMat.rows,                                    // height
//                                        8,                                             // bits per component
//                                        8 * cvMat.elemSize(),                          // bits per pixel
//                                        cvMat.step[0],                                 // bytesPerRow
//                                        colorSpace,                                    // colorspace
//                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault, // bitmap info
//                                        provider,                                      // CGDataProviderRef
//                                        NULL,                                          // decode
//                                        false,                                         // should interpolate
//                                        kCGRenderingIntentDefault                      // intent
//                                        );
//    
//    // Getting UIImage from CGImage
//    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
//    CGImageRelease(imageRef);
//    CGDataProviderRelease(provider);
//    CGColorSpaceRelease(colorSpace);
//    
//    return finalImage;
//}
//
//- (cv::Mat)cvMatWithImage:(CGImage *)image format:(int)format {
//    BOOL alphaExist = NO;
//    cv::Mat m;
//    CGFloat cols = CGImageGetWidth(image);
//    CGFloat rows = CGImageGetHeight(image);
//    
//    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
//    CGColorSpaceRetain(colorSpace);
//    
//    CGContextRef contextRef;
//    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
//    if (CGColorSpaceGetModel(colorSpace) == 0) {
//        m.create(rows, cols, format); // 8 bits per component, 1 channel
//        bitmapInfo = kCGImageAlphaNone;
//        if (!alphaExist)
//            bitmapInfo = kCGImageAlphaNone;
//        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8, m.step[0],
//                                           colorSpace, bitmapInfo);
//    } else {
//        m.create(rows, cols, format); // 8 bits per component, 4 channels
//        if (!alphaExist)
//            bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little;
//        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8, m.step[0],
//                                           colorSpace, bitmapInfo);
//    }
//    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image);
//    CGContextRelease(contextRef);
//    CGColorSpaceRelease(colorSpace);
//    
//    return m;
//}

@end
