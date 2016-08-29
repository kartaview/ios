
#import "AVCamViewController.h"
#import "AVCamPreviewView.h"
#import "OSVUserDefaults.h"

static void *CapturingStillImageContext = &CapturingStillImageContext;

@interface AVCamViewController ()

// Session management.
@property (nonatomic) dispatch_queue_t              sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) AVCaptureSession              *session;
@property (nonatomic) AVCaptureDeviceInput          *videoDeviceInput;
@property (nonatomic) AVCaptureStillImageOutput     *stillImageOutput;
// Utilities.
@property (nonatomic) UIBackgroundTaskIdentifier                                    backgroundRecordingID;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL  sessionRunningAndDeviceAuthorized;
@property (nonatomic) BOOL                                                          lockInterfaceRotation;
@property (nonatomic) id                                                            runtimeErrorHandlingObserver;

@end

@implementation AVCamViewController

- (BOOL)isSessionRunningAndDeviceAuthorized {
	return [[self session] isRunning] && [self isDeviceAuthorized];
}

+ (NSSet *)keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized {
	return [NSSet setWithObjects:@"session.running", @"deviceAuthorized", nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
        
	// Create the AVCaptureSession
	AVCaptureSession *session = [[AVCaptureSession alloc] init];
	[self setSession:session];
    [session setSessionPreset:AVCaptureSessionPresetInputPriority];

	// Setup the preview view
	[[self previewView] setSession:session];
	
	// Check for device authorization
	[self checkDeviceAuthorizationStatus];
	
	// In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
	// Why not do all of this on the main queue?
	// -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue so that the main queue isn't blocked (which keeps the UI responsive).
	
    [self configureDeviceFormat];
    
	dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	[self setSessionQueue:sessionQueue];
    
    __weak typeof(self) welf = self;
    
	dispatch_async(sessionQueue, ^{
		[welf setBackgroundRecordingID:UIBackgroundTaskInvalid];
		
        [welf configureActiveFormat];
        
		AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		if ([session canAddOutput:stillImageOutput]) {
            [stillImageOutput setOutputSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)}];
			[session addOutput:stillImageOutput];
			[self setStillImageOutput:stillImageOutput];
		}

	});
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self configureDeviceFormat];
    
    __weak typeof(self) welf = self;

	dispatch_async([welf sessionQueue], ^{
        CMVideoDimensions dim = CMVideoFormatDescriptionGetDimensions(self.videoDeviceInput.device.activeFormat.formatDescription);
        CMVideoDimensions requestedDim = [OSVUserDefaults sharedInstance].videoQualityDimension;
        
        if (dim.width != requestedDim.width && dim.height != requestedDim.height) {
            [welf configureActiveFormat];
        }
		[welf addObserver:welf forKeyPath:@"stillImageOutput.capturingStillImage" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CapturingStillImageContext];
		[[NSNotificationCenter defaultCenter] addObserver:welf selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[welf videoDeviceInput] device]];
		
		[welf setRuntimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification object:[welf session] queue:nil usingBlock:^(NSNotification *note) {
			AVCamViewController *strongSelf = welf;
			dispatch_async([strongSelf sessionQueue], ^{
				// Manually restarting the session since it must have been stopped due to an error.
				[[strongSelf session] startRunning];
			});
		}]];
		[[welf session] startRunning];
	});
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

	dispatch_async([self sessionQueue], ^{
		[[self session] stopRunning];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
		[[NSNotificationCenter defaultCenter] removeObserver:[self runtimeErrorHandlingObserver]];
		
		[self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];
	});
}

- (BOOL)shouldAutorotate {
	// Disable autorotation of the interface when recording is in progress.
	return ![self lockInterfaceRotation];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == CapturingStillImageContext) {
		BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
		
		if (isCapturingStillImage) {
			[self runStillImageCaptureAnimation];
		}
    } else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark Actions

- (void)subjectAreaDidChange:(NSNotification *)notification {
	CGPoint devicePoint = CGPointMake(.5, .5);
	[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

#pragma mark File Output Delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    if (error) {
        NSLog(@"%@", error);
    }
	
	[self setLockInterfaceRotation:NO];
	
	// Note the backgroundRecordingID for use in the ALAssetsLibrary completion handler to end the background task associated with this recording. This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's -isRecording is back to NO — which happens sometime after this method returns.
	UIBackgroundTaskIdentifier backgroundRecordingID = [self backgroundRecordingID];
	[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
	
	[[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        }
		
		[[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
		
        if (backgroundRecordingID != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
        }
	}];
}

#pragma mark Device Configuration

- (void)configureDeviceFormat {
    CMVideoDimensions requestedDim = [OSVUserDefaults sharedInstance].videoQualityDimension;

    AVCaptureDevice *videoDevice = [AVCamViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
    for (AVCaptureDeviceFormat *format in videoDevice.formats) {
        CMVideoDimensions dim = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        
        if (dim.width == requestedDim.width && dim.height == requestedDim.height) {
            self.deviceFormat = format;
        }
    }
}

- (BOOL)configureActiveFormat {
    NSError *error = nil;

    AVCaptureDevice *videoDevice = [AVCamViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
    
    NSError *errorVideo;
    [videoDevice lockForConfiguration:&errorVideo];
    if (self.deviceFormat) {
        videoDevice.activeFormat = self.deviceFormat;
        
        if ([videoDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            [videoDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        
        if ([videoDevice isAutoFocusRangeRestrictionSupported]) {
            [videoDevice setAutoFocusRangeRestriction:AVCaptureAutoFocusRangeRestrictionFar];
        }
        //          TO DO make exposure more fast
        //            [videoDevice setExposureModeCustomWithDuration:CMTimeMakeWithSeconds( 1, 1000*1000*1000 )  ISO:AVCaptureISOCurrent completionHandler:nil];
    }
    //Set HDR
    if (videoDevice.activeFormat.videoHDRSupported) {
        if ([OSVUserDefaults sharedInstance].hdrOption) {
            videoDevice.automaticallyAdjustsVideoHDREnabled = NO;
            videoDevice.videoHDREnabled = YES;
        } else {
            videoDevice.automaticallyAdjustsVideoHDREnabled = NO;
            videoDevice.videoHDREnabled = NO;
        }
    }
    [videoDevice unlockForConfiguration];
    
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    
    if (self.videoDeviceInput) {
        [self.session removeInput:self.videoDeviceInput];
    }

    BOOL succes = [self.session canAddInput:videoDeviceInput];

    if (succes) {
        [self.session addInput:videoDeviceInput];
        
        if (!self.videoDeviceInput) {
            __weak typeof(self) welf = self;

            dispatch_async(dispatch_get_main_queue(), ^{
                // Why are we dispatching this to the main queue?
                // Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView can only be manipulated on main thread.
                // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                
                [[(AVCaptureVideoPreviewLayer *)[[welf previewView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)[welf interfaceOrientation]];
                ((AVCaptureVideoPreviewLayer *)[[welf previewView] layer]).videoGravity = AVLayerVideoGravityResizeAspectFill;
            });
        }
        self.videoDeviceInput = videoDeviceInput;
    }
    
    return succes;
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
    __weak typeof(self) welf = self;

	dispatch_async([welf sessionQueue], ^{
		AVCaptureDevice *device = [[welf videoDeviceInput] device];
		NSError *error = nil;
		if ([device lockForConfiguration:&error]) {
			if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode]) {
				[device setFocusMode:focusMode];
				[device setFocusPointOfInterest:point];
			}
			if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode]) {
				[device setExposureMode:exposureMode];
				[device setExposurePointOfInterest:point];
			}
			[device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
			[device unlockForConfiguration];
		} else {
			NSLog(@"%@", error);
		}
	});
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device {
	if ([device hasFlash] && [device isFlashModeSupported:flashMode]) {
		NSError *error = nil;
		if ([device lockForConfiguration:&error]) {
			[device setFlashMode:flashMode];
			[device unlockForConfiguration];
		} else {
			NSLog(@"%@", error);
		}
	}
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position {
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	AVCaptureDevice *captureDevice = [devices firstObject];
	
	for (AVCaptureDevice *device in devices) {
		if ([device position] == position) {
			captureDevice = device;
			break;
		}
	}
	
	return captureDevice;
}

#pragma mark UI

- (void)runStillImageCaptureAnimation {
	dispatch_async(dispatch_get_main_queue(), ^{
        static SystemSoundID soundID = 0;
        
        if (soundID == 0) {
            NSString *path = [[NSBundle mainBundle] pathForResource:@"photoShutter2" ofType:@"caf"];
            NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
        }
        AudioServicesPlaySystemSound(soundID);
    });
}

- (void)checkDeviceAuthorizationStatus {
	NSString *mediaType = AVMediaTypeVideo;
	
    __weak typeof(self) welf = self;

	[AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
		if (granted) {
			//Granted access to mediaType
			[welf setDeviceAuthorized:YES];
		} else {
			//Not granted access to mediaType
			dispatch_async(dispatch_get_main_queue(), ^{
				[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Camera!", @"")
											message:NSLocalizedString(@"OSV doesn't have permission to use Camera, please change privacy settings", @"")
										   delegate:welf
                                  cancelButtonTitle:NSLocalizedString(@"OK", @"")
								  otherButtonTitles:nil] show];
				[welf setDeviceAuthorized:NO];
			});
		}
	}];
}

@end
