
#import <UIKit/UIKit.h>

@class AVCaptureSession;

@interface AVCamPreviewView : UIView

@property (nonatomic, strong) UIView                    *focusView;

@property (nonatomic) AVCaptureSession *session;

@end
