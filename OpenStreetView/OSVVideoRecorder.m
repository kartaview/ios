//
//  OSVVideoRecorder.m
//  ScreenCaptureViewTest
//
//  Created by Bogdan Sala on 07/03/16.
//
//

#import "OSVVideoRecorder.h"
#import <UIKit/UIKit.h>
#import <Accelerate/Accelerate.h>
#import <ImageIO/ImageIO.h>
#import "OSVLogger.h"

@interface OSVVideoRecorder()

@property (strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor  *avAdaptor;
@property (strong, nonatomic) AVAssetWriter                         *videoWriter;
@property (strong, nonatomic) AVAssetWriterInput                    *videoWriterInput;
@property (assign, nonatomic) CMVideoDimensions                     size;

@property (assign, nonatomic) CMTime                                time;

@property (strong, nonatomic) NSURL                                 *videoURL;

@property (strong, nonatomic) NSString                              *videoEncoding;
@property (assign, nonatomic) NSInteger                             bitrate;

@end

@implementation OSVVideoRecorder

- (instancetype)initWithVideoSize:(CMVideoDimensions)size encoding:(NSString *)encod bitrate:(NSInteger)bitrate {
    self = [super init];
    if (self) {
        self.size = size;
        self.videoEncoding = encod;
        self.bitrate = bitrate;
    }
    
    return self;
}


- (instancetype)initWithVideoSize:(CMVideoDimensions)size {
    self = [super init];
    if (self) {
        self.size = size;
        self.videoEncoding = AVVideoProfileLevelH264HighAutoLevel;
        self.bitrate = 40000000;
    }
    
    return self;
}

- (BOOL)createRecordingWithURL:(NSURL *)url orientation:(AVCaptureVideoOrientation)orientaton {
    NSError *error = nil;
    
    self.videoURL = url;
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:self.videoURL fileType:AVFileTypeMPEG4 error:&error];
    NSParameterAssert(self.videoWriter);
   
    NSDictionary *videoCompressionProps = [NSDictionary
                                           dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithInteger:self.bitrate], AVVideoAverageBitRateKey, // 40 Mbps
                                           self.videoEncoding, AVVideoProfileLevelKey, // profiles...
                                           nil];
    
    CMVideoDimensions videoSize;
    if (orientaton == AVCaptureVideoOrientationPortrait) {
        videoSize.width = self.size.height;
        videoSize.height = self.size.width;
    } else {
        videoSize.width = self.size.width;
        videoSize.height = self.size.height;
    }

    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:videoSize.height], AVVideoHeightKey,
                                   [NSNumber numberWithInt:videoSize.width], AVVideoWidthKey,
                                   videoCompressionProps, AVVideoCompressionPropertiesKey,
                                   nil];
    
    self.videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    NSParameterAssert(self.videoWriterInput);
    self.videoWriterInput.expectsMediaDataInRealTime = YES;
    NSDictionary *bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
    
    self.avAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoWriterInput
                                                                                      sourcePixelBufferAttributes:bufferAttributes];
    
    //add input
    [self.videoWriter addInput:self.videoWriterInput];
    [self.videoWriter startWriting];
    self.time = CMTimeMake(0, 1000);
    [self.videoWriter startSessionAtSourceTime:self.time];
    
    return YES;
}

- (void)completeRecordingSessionWithBlock:(void (^)(BOOL success, NSError *error))completion {
    @autoreleasepool {
        [self.videoWriterInput markAsFinished];
            
        @synchronized(self) {
            [self.videoWriter finishWritingWithCompletionHandler:^{
                BOOL success =  self.videoWriter.status == AVAssetWriterStatusCompleted;
                
                [self cleanupWriter];

                if (self.videoWriter.status == AVAssetWriterStatusFailed) {
                    completion(success, self.videoWriter.error);
                } else {
                    completion(success, nil);
                }
            }];
        }
    }
}

- (void)addPixelBuffer:(CVPixelBufferRef)pixelsBuffer withRotation:(NSInteger)rotation completion:(void (^)(BOOL))block {
    if (![self.videoWriterInput isReadyForMoreMediaData]) {
        [[OSVLogger sharedInstance] logMessage:@"Could not write frame in video. videoWriter is not ready for more media data" withLevel:LogLevelDEBUG];
        block(false);
    } else {
        @autoreleasepool {
            CVPixelBufferRef corrected = pixelsBuffer;
            if (!pixelsBuffer) {
                [[OSVLogger sharedInstance] logMessage:@"Could not write frame in video. pixelsBuffer is nil." withLevel:LogLevelDEBUG];
            }
            
            if (rotation != kRotate0DegreesClockwise) {
                if (rotation == kRotate180DegreesClockwise) {
                    corrected = [self correctBufferOrientation:pixelsBuffer withRotation:kRotate90DegreesClockwise];
                    pixelsBuffer = [self correctBufferOrientation:corrected withRotation:kRotate90DegreesClockwise];
                    CVPixelBufferRelease(corrected);
                    corrected = pixelsBuffer;
                } else {
                    corrected = [self correctBufferOrientation:pixelsBuffer withRotation:rotation];
                }
            } else {
                CVPixelBufferRetain(corrected);
            }
            
            CVPixelBufferLockBaseAddress(corrected, 0);
            if (corrected) {
                BOOL success = [self.avAdaptor appendPixelBuffer:corrected withPresentationTime:self.time];
                if (success) {
                    self.time = CMTimeAdd(self.time, CMTimeMake(200, 1000));
                }
                block(success);
            } else {
                [[OSVLogger sharedInstance] logMessage:@"Could not write frame in video. corected is nil." withLevel:LogLevelDEBUG];

                block(false);
            }
            CVPixelBufferUnlockBaseAddress(corrected, 0);
            CVPixelBufferRelease(corrected);
        }
    }
}

- (void)addPixelBuffer:(CVPixelBufferRef)pixelsBuffer withRotation:(NSInteger)rotation withDuration:(CMTime)duration completion:(void (^)(BOOL))block {
    if (![self.videoWriterInput isReadyForMoreMediaData]) {
        [[OSVLogger sharedInstance] logMessage:@"Could not write frame in video. videoWriter is not ready for more media data" withLevel:LogLevelDEBUG];
        block(false);
    } else {
        @autoreleasepool {
            CVPixelBufferRef corrected = pixelsBuffer;
            if (!pixelsBuffer) {
                [[OSVLogger sharedInstance] logMessage:@"Could not write frame in video. pixelsBuffer is nil." withLevel:LogLevelDEBUG];
            }
            
            if (rotation != kRotate0DegreesClockwise) {
                if (rotation == kRotate180DegreesClockwise) {
                    corrected = [self correctBufferOrientation:pixelsBuffer withRotation:kRotate90DegreesClockwise];
                    pixelsBuffer = [self correctBufferOrientation:corrected withRotation:kRotate90DegreesClockwise];
                    CVPixelBufferRelease(corrected);
                    corrected = pixelsBuffer;
                } else {
                    corrected = [self correctBufferOrientation:pixelsBuffer withRotation:rotation];
                }
            } else {
                CVPixelBufferRetain(corrected);
            }
            
            CVPixelBufferLockBaseAddress(corrected, 0);
            if (corrected) {
                BOOL success = [self.avAdaptor appendPixelBuffer:corrected withPresentationTime:self.time];
                if (success) {
                    self.time = CMTimeAdd(self.time, CMTimeMake(100, 1000));
                }
                block(success);
            } else {
                [[OSVLogger sharedInstance] logMessage:@"Could not write frame in video. corected is nil." withLevel:LogLevelDEBUG];
                
                block(false);
            }
            CVPixelBufferUnlockBaseAddress(corrected, 0);
            CVPixelBufferRelease(corrected);
        }
    }
}

- (long long)currentVideoSize {
    if (self.videoURL) {
        return [[[[NSFileManager defaultManager] attributesOfItemAtPath:[self.videoURL resourceSpecifier] error:nil] objectForKey:NSFileSize] unsignedIntegerValue];
    }
    
    return 0;
}

- (void)cleanupWriter {
    self.avAdaptor = nil;
    self.videoWriterInput = nil;
    self.videoWriter = nil;
}

#pragma mark - Private

- (CVPixelBufferRef)correctBufferOrientation:(CVImageBufferRef)imageBuffer withRotation:(NSInteger)rotation {
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    size_t bytesPerRow                  = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width                        = CVPixelBufferGetWidth(imageBuffer);
    size_t height                       = CVPixelBufferGetHeight(imageBuffer);
    size_t currSize                     = bytesPerRow * height * sizeof(unsigned char);
    size_t bytesPerRowOut               = bytesPerRow;
    
    void *srcBuff                       = CVPixelBufferGetBaseAddress(imageBuffer);
    
    /* rotationConstant:
     *  0 -- rotate 0 degrees (simply copy the data from src to dest)
     *  1 -- rotate 90 degrees counterclockwise
     *  2 -- rotate 180 degress
     *  3 -- rotate 270 degrees counterclockwise
     */
    uint8_t rotationConstant            = rotation;
    
    unsigned char *dstBuff              = (unsigned char *)malloc(currSize);
    
    vImage_Buffer inbuff                = {srcBuff, height, width, bytesPerRow};
    vImage_Buffer outbuff;
    
    if (rotationConstant == kRotate0DegreesClockwise || rotationConstant == kRotate180DegreesClockwise) {
        outbuff.data = dstBuff;
        outbuff.height = height;
        outbuff.width = width;
        outbuff.rowBytes = inbuff.rowBytes;
    } else {
        outbuff.data = dstBuff;
        outbuff.height = width;
        outbuff.width = height;
        bytesPerRowOut = 4 * height * sizeof(unsigned char);
        outbuff.rowBytes = 4 * height * sizeof(unsigned char);
    }
    
    uint8_t bgColor[4]                  = {0, 0, 0, 0};
    
    vImage_Error err                    = vImageRotate90_ARGB8888(&inbuff, &outbuff, rotationConstant, bgColor, 0);
    if (err != kvImageNoError) NSLog(@"%ld", err);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    CVPixelBufferRef rotatedBuffer      = NULL;
    CVPixelBufferCreateWithBytes(NULL,
                                 height,
                                 width,
                                 kCVPixelFormatType_32BGRA,
                                 outbuff.data,
                                 bytesPerRowOut,
                                 freePixelBufferDataAfterRelease,
                                 NULL,
                                 NULL,
                                 &rotatedBuffer);
    
    return rotatedBuffer;
}

void freePixelBufferDataAfterRelease(void *releaseRefCon, const void *baseAddress) {
    // Free the memory we malloced for the vImage rotation
    free((void *)baseAddress);
}

@end
