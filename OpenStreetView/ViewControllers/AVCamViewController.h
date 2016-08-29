
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@class AVCamPreviewView;

@interface AVCamViewController : UIViewController

@property (nonatomic, weak) IBOutlet AVCamPreviewView       *previewView;

@property (nonatomic, strong) AVCaptureDeviceFormat         *deviceFormat;
@property (nonatomic, getter = isDeviceAuthorized) BOOL     deviceAuthorized;


+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device;
- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange;

@end
