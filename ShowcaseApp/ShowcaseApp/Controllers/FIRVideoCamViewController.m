/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FIRVideoCamViewController.h"

#import <AVFoundation/AVFoundation.h>

#import "FIRCameraReticle.h"
#import "FIRConfirmationSpinner.h"
#import "FIRDetectionOverlayView.h"
#import "FIRImageUtilities.h"
#import "FIRODTStatus.h"
#import "FIRProduct.h"
#import "FIRProductListHeaderView.h"
#import "FIRProductListViewController.h"
#import "FIRProductSearchRequest.h"
#import "FIRUIUtilities.h"

// Use the following imports for CocoaPods:
@import FirebaseMLCommon;
@import FirebaseMLVision;
@import FirebaseMLVisionObjectDetection;
@import MaterialComponents;
@import GTMSessionFetcher;

// Use the following imports for google3:
//#import "googlemac/iPhone/FirebaseML/Vision/ObjectDetection/Public/FIRVision+ObjectDetection.h"
//#import "googlemac/iPhone/FirebaseML/Vision/ObjectDetection/Public/FIRVisionObject.h"
//#import "googlemac/iPhone/FirebaseML/Vision/ObjectDetection/Public/FIRVisionObjectDetector.h"
//#import
//"googlemac/iPhone/FirebaseML/Vision/ObjectDetection/Public/FIRVisionObjectDetectorOptions.h"
//#import "googlemac/iPhone/FirebaseML/Vision/Public/FIRVision.h"
//#import "googlemac/iPhone/FirebaseML/Vision/Public/FIRVisionImage.h"
//#import "googlemac/iPhone/FirebaseML/Vision/Public/FIRVisionImageMetadata.h"
//#import "googlemac/iPhone/FirebaseML/Vision/Public/FIRVisionPoint.h"
//#import "googlemac/iPhone/Shared/GoogleMaterial/components/Buttons/src/GoogleMaterialButtons.h"
//#import "googlemac/iPhone/Shared/GoogleMaterial/components/Palettes/src/GoogleMaterialPalettes.h"
//#import "third_party/objective_c/material_components_ios/components/Chips/src/MaterialChips.h"

NS_ASSUME_NONNULL_BEGIN

static char *const FIRVideoDataOutputQueueLabel =
    "com.google.firebaseml.visiondetector.VideoDataOutputQueue";
static char *const FIRVideoSessionQueueLabel =
    "com.google.firebaseml.visiondetector.VideoSessionQueue";

/** Duration for presenting the bottom sheet. */
static const CGFloat kBottomSheetAnimationDurationInSec = 0.25f;

/** Duration for confirming stage. */
static const CGFloat kConfirmingDurationInSec = 1.5f;

// Constants for alpha values.
static const CGFloat kOpaqueAlpha = 1.0f;
static const CGFloat kTransparentAlpha = 0.0f;

/**  Radius of the searching indicator. */
static const CGFloat kSearchingIndicatorRadius = 24.0f;

/** Target height of the thumbnail when it sits on top of the bottom sheet. */
static const CGFloat kThumbnailbottomSheetTargetHeight = 200.0f;

/** Padding around the thumbnail when it sits on top of the bottom sheet. */
static const CGFloat kThumbnailPaddingAround = 24.0f;

/** The thumbnail will fade out when it reaches this threshhold from screen edge. */
static const CGFloat kThumbnailFadeOutEdgeThreshhold = 200.0f;

/** Number of faked product search results. */
static const NSUInteger kFakeProductSearchResultCount = 10;

// Chip message related values.
static const CGFloat kChipBackgroundAlpha = 0.6f;
static const CGFloat kChipCornerRadius = 8.0f;
static const CGFloat kChipFadeInDuration = 0.075f;
static const CGFloat kChipScaleDuration = 0.15f;
static const CGFloat kChipScaleFromRatio = 0.8f;
static const CGFloat kChipScaleToRatio = 1.25f;
static const CGFloat kChipBottomPadding = 36.0f;

/** The message shown in detecting stage.  */
static NSString *const kDetectingStageMessage = @"Point your camera at an object";

/** The Message shown in confirming stage. */
static NSString *const kConfirmingStageMessage = @"Keep camera still for a moment";

/** The message shown in searching stage. */
static NSString *const kSearchingMessage = @"Searching";

// Strings for fake search results.
static NSString *const kFakeProductNameFormat = @"Fake product name: %li";
static NSString *const kFakeProductTypeName = @"Fashion";
static NSString *const kFakeProductPriceText = @"$10";
static NSString *const kFakeProductItemNumberText = @"12345678";

/**
 * A wrapper class that holds a reference to `CMSampleBufferRef` to let ARC take care of its
 * lifecyle for this `CMSampleBufferRef`.
 */
@interface FIRSampleBuffer : NSObject

// The encapsulated `CMSampleBufferRed` data.
@property(nonatomic) CMSampleBufferRef data;

@end

@implementation FIRSampleBuffer

#pragma mark - Public

- (instancetype)initWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  self = [super init];
  if (self != nil) {
    _data = sampleBuffer;
    CFRetain(sampleBuffer);
  }
  return self;
}

- (void)dealloc {
  CFRelease(self.data);
}

@end

@interface FIRVideoCamViewController () <AVCaptureVideoDataOutputSampleBufferDelegate,
                                         MDCBottomSheetControllerDelegate,
                                         MDCFlexibleHeaderViewDelegate>

// Views to be added as subviews of current view.
@property(nonatomic) UIView *previewView;
@property(nonatomic) FIRDetectionOverlayView *overlayView;
@property(nonatomic) FIRCameraReticle *detectingReticle;
@property(nonatomic) FIRConfirmationSpinner *confirmingSpinner;
@property(nonatomic) MDCActivityIndicator *searchingIndicator;

// Video capture related properties.
@property(nonatomic) AVCaptureSession *session;
@property(nonatomic, nullable) AVCaptureVideoDataOutput *videoDataOutput;
@property(nonatomic) dispatch_queue_t videoDataOutputQueue;
@property(nonatomic) dispatch_queue_t sessionQueue;
@property(nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

// Vision server to generate `VisionObjectDetector`.
@property(nonatomic) FIRVision *vision;

// Current status in object detection.
@property(nonatomic) FIRODTStatus status;

// View to show message during different stages.
@property(nonatomic) MDCChipView *messageView;

// Properties to record latest detected results.
@property(nonatomic, nullable) FIRVisionObject *lastDetectedObject;
@property(nonatomic, nullable) FIRSampleBuffer *lastDetectedSampleBuffer;

// Width to height ratio of the thumbnail.
@property(nonatomic) CGFloat thumbnailWidthHeightRatio;

// Target height of the bottom sheet.
@property(nonatomic) CGFloat bottomSheetTargetHeight;

// Array of timers scheduled before confirmation.
@property(nonatomic, nullable) NSMutableArray *timers;

// Used to fetch product search results.
@property(nonatomic) GTMSessionFetcherService *fetcherService;

@end

@implementation FIRVideoCamViewController

#pragma mark - Public

- (id)init {
  self = [super init];
  if (self != nil) {
    _videoDataOutputQueue = dispatch_queue_create(FIRVideoDataOutputQueueLabel,
                                                  DISPATCH_QUEUE_SERIAL);
    _sessionQueue = dispatch_queue_create(FIRVideoSessionQueueLabel, DISPATCH_QUEUE_SERIAL);
    _session = [[AVCaptureSession alloc] init];
    _vision = [FIRVision vision];
    _fetcherService = [[GTMSessionFetcherService alloc] init];
    _status = FIRODTStatus_NotStarted;
    _timers = [NSMutableArray array];
  }
  return self;
}

- (void)dealloc {
  [self clearLastDetectedObject];
  [self.fetcherService stopAllFetchers];
}

#pragma mark - UIViewController

- (void)loadView {
  [super loadView];

  self.view.clipsToBounds = YES;

  [self setUpPreviewView];
  [self setUpOverlayView];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = UIColor.whiteColor;

  [self setCameraSelection];

  // Set up video processing pipeline.
  [self setUpVideoProcessing];

  // Set up camera preview.
#if !TARGET_IPHONE_SIMULATOR
  [self setUpCameraPreviewLayer];
#endif

  [self setUpDetectingReticle];
  [self setUpConfirmingSpinner];
  [self setUpSearchingIndicator];
  [self setUpMessageView];
  [self startToDetect];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];

  self.previewLayer.frame = self.view.frame;
  self.previewLayer.position = CGPointMake(CGRectGetMidX(self.previewLayer.frame),
                                           CGRectGetMidY(self.previewLayer.frame));
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  __weak typeof(self) weakSelf = self;
#if !TARGET_IPHONE_SIMULATOR
  dispatch_async(self.sessionQueue, ^{
    [weakSelf.session stopRunning];
  });
#endif
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
           fromConnection:(AVCaptureConnection *)connection {
  [self detectObjectInSampleBuffer:[[FIRSampleBuffer alloc] initWithSampleBuffer:sampleBuffer]];
}

#pragma mark - MDCBottomSheetControllerDelegate

- (void)bottomSheetControllerDidDismissBottomSheet:(nonnull MDCBottomSheetController *)controller {
  self.bottomSheetTargetHeight = 0;
  [self startToDetect];
}

- (void)bottomSheetControllerDidChangeYOffset:(MDCBottomSheetController *)controller
                                      yOffset:(CGFloat)yOffset {
  CGFloat imageStartY = yOffset - kThumbnailbottomSheetTargetHeight - kThumbnailPaddingAround;
  CGRect rect =
      CGRectMake(kThumbnailPaddingAround,                                             // X
                 imageStartY,                                                         // Y
                 kThumbnailbottomSheetTargetHeight * self.thumbnailWidthHeightRatio,  // Width
                 kThumbnailbottomSheetTargetHeight);                                  // Height

  UIWindow *currentWindow = UIApplication.sharedApplication.keyWindow;
  UIEdgeInsets safeInset = currentWindow.safeAreaInsets;
  CGFloat screenHeight = currentWindow.bounds.size.height;
  CGFloat topFadeOutOffsetY = safeInset.top + kThumbnailFadeOutEdgeThreshhold;
  CGFloat bottomFadeOutOffsetY = screenHeight - safeInset.bottom - kThumbnailFadeOutEdgeThreshhold;

  CGFloat imageAlpha =
      [self ratioOfCurrentValue:yOffset
                           from:(yOffset > self.bottomSheetTargetHeight) ? bottomFadeOutOffsetY
                                                                         : topFadeOutOffsetY
                             to:self.bottomSheetTargetHeight];
  [self.overlayView showImageInRect:rect alpha:imageAlpha];
}

#pragma mark - Private

/** Prepares camera session for video processing. */
- (void)setUpVideoProcessing {
  __weak typeof(self) weakSelf = self;
  dispatch_async(self.sessionQueue, ^{
    __strong typeof(self) strongSelf = weakSelf;
    if (strongSelf == nil) {
      return;
    }
    strongSelf.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    NSDictionary *rgbOutputSettings =
        @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
    [strongSelf.videoDataOutput setVideoSettings:rgbOutputSettings];

    if (![strongSelf.session canAddOutput:strongSelf.videoDataOutput]) {
      if (strongSelf.videoDataOutput) {
        [strongSelf.session removeOutput:strongSelf.videoDataOutput];
        strongSelf.videoDataOutput = nil;
      }
      NSLog(@"Failed to set up video output");
      return;
    }
    [strongSelf.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [strongSelf.videoDataOutput setSampleBufferDelegate:strongSelf
                                                  queue:strongSelf.videoDataOutputQueue];
    [strongSelf.session addOutput:strongSelf.videoDataOutput];
  });
}

/** Prepares preview view for camera session. */
- (void)setUpPreviewView {
  self.previewView = [[UIView alloc] initWithFrame:self.view.frame];
  self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.previewView];
}

/** Initiates and prepares camera preview layer for later video capture. */
- (void)setUpCameraPreviewLayer {
  self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
  [self.previewLayer setBackgroundColor:UIColor.blackColor.CGColor];
  [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
  CALayer *rootLayer = [self.previewView layer];
  [rootLayer setMasksToBounds:YES];
  [self.previewView setFrame:[rootLayer bounds]];
  [rootLayer addSublayer:self.previewLayer];
}

/** Prepares camera for later video capture. */
- (void)setCameraSelection {
  __weak typeof(self) weakSelf = self;
  dispatch_async(self.sessionQueue, ^{
    __strong typeof(self) strongSelf = weakSelf;
    if (strongSelf == nil) {
      return;
    }

    [strongSelf.session beginConfiguration];
    strongSelf.session.sessionPreset = AVCaptureSessionPreset1280x720;

    NSArray *oldInputs = [strongSelf.session inputs];
    for (AVCaptureInput *oldInput in oldInputs) {
      [strongSelf.session removeInput:oldInput];
    }

    AVCaptureDeviceInput *input = [strongSelf pickCamera:AVCaptureDevicePositionBack];
    if (!input) {
      // Failed, restore old inputs
      for (AVCaptureInput *oldInput in oldInputs) {
        [strongSelf.session addInput:oldInput];
      }
    } else {
      // Succeeded, set input and update connection states
      [strongSelf.session addInput:input];
    }
    [strongSelf.session commitConfiguration];
  });
}

/** Determines camera for later video capture. Here only rear camera is picked. */
- (AVCaptureDeviceInput*)pickCamera:(AVCaptureDevicePosition)desiredPosition {
  BOOL hadError = NO;
  for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
    if ([device position] == desiredPosition) {
      NSError *error = nil;
      AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device
                                                                          error:&error];
      if (error != nil) {
        hadError = YES;
        NSLog(@"Could not initialize for AVMediaTypeVideo for device %@", device);
      } else if ([self.session canAddInput:input]) {
        return input;
      }
    }
  }
  if (!hadError) {
    NSLog(@"No camera found for requested orientation");
  }
  return nil;
}

/** Initiates and prepares overlay view for later video capture. */
- (void)setUpOverlayView {
  self.overlayView = [[FIRDetectionOverlayView alloc] initWithFrame:self.view.frame];
  self.overlayView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.overlayView];
}

/** Clears up the overlay view. Caller must make sure this runs on the main thread. */
- (void)cleanUpOverlayView {
  NSAssert([NSThread.currentThread isEqual:NSThread.mainThread],
           @"cleanUpOverlayView is not running on the main thread");

  [self.overlayView clear];
  self.overlayView.frame = self.view.frame;
}

/** Initiates and prepares detecting reticle for later video capture. */
- (void)setUpDetectingReticle {
  self.detectingReticle = [[FIRCameraReticle alloc] init];
  self.detectingReticle.translatesAutoresizingMaskIntoConstraints = NO;
  CGSize size = [self.detectingReticle sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
  self.detectingReticle.frame = CGRectMake(0, 0, size.width, size.height);
  [self.view addSubview:self.detectingReticle];
  [NSLayoutConstraint activateConstraints:@[
    [self.detectingReticle.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.detectingReticle.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
  ]];
}

/** Initiates and prepares confirming spinner for later video capture. */
- (void)setUpConfirmingSpinner {
  self.confirmingSpinner =
      [[FIRConfirmationSpinner alloc] initWithDuration:kConfirmingDurationInSec];
  self.confirmingSpinner.translatesAutoresizingMaskIntoConstraints = NO;
  CGSize size = [self.confirmingSpinner sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
  self.confirmingSpinner.frame = CGRectMake(0, 0, size.width, size.height);
  [self.view addSubview:self.confirmingSpinner];
  [NSLayoutConstraint activateConstraints:@[
    [self.confirmingSpinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.confirmingSpinner.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
  ]];
}

/** Initiates and prepares searching indicator for later video capture. */
- (void)setUpSearchingIndicator {
  self.searchingIndicator = [[MDCActivityIndicator alloc] init];
  self.searchingIndicator.radius = kSearchingIndicatorRadius;
  self.searchingIndicator.cycleColors = @[ UIColor.whiteColor ];
  CGSize size = [self.confirmingSpinner sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
  CGFloat centerX = CGRectGetMidX(self.view.frame);
  CGFloat centerY = CGRectGetMidY(self.view.frame);
  self.searchingIndicator.frame = CGRectMake(centerX, centerY, size.width, size.height);
  [self.view addSubview:self.searchingIndicator];
  [NSLayoutConstraint activateConstraints:@[
    [self.searchingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.searchingIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
  ]];
}

/** Initiates and prepares message view for later video capture. */
- (void)setUpMessageView {
  self.messageView = [[MDCChipView alloc] init];
  self.messageView.backgroundColor =
      [UIColor.blackColor colorWithAlphaComponent:kChipBackgroundAlpha];
  self.messageView.userInteractionEnabled = NO;
  self.messageView.clipsToBounds = YES;
  self.messageView.titleLabel.textColor = UIColor.whiteColor;
  self.messageView.layer.cornerRadius = kChipCornerRadius;
  [self.view addSubview:self.messageView];
  self.messageView.alpha = kTransparentAlpha;
}

/**
 * Clears last detected object. Caller must make sure that this method runs on the main thread.
 */
- (void)clearLastDetectedObject {
  NSAssert([NSThread.currentThread isEqual:NSThread.mainThread],
           @"clearLastDetectedObject is not running on the main thread");

  self.lastDetectedObject = nil;
  self.lastDetectedSampleBuffer = nil;
  for (NSTimer *timer in self.timers) {
    [timer invalidate];
  }
}

#pragma mark - Object detection and tracking.

/**
 * Called to detect objects in given sample buffer.
 *
 * @param sampleBuffer The `SampleBuffer` for object detection.
 */
- (void)detectObjectInSampleBuffer:(FIRSampleBuffer *)sampleBuffer {
  FIRVisionDetectorImageOrientation orientation =
      [FIRUIUtilities imageOrientationFromOrientation:UIDevice.currentDevice.orientation
                            withCaptureDevicePosition:AVCaptureDevicePositionBack];

  FIRVisionImage *image = [[FIRVisionImage alloc] initWithBuffer:sampleBuffer.data];
  FIRVisionImageMetadata *metadata = [[FIRVisionImageMetadata alloc] init];
  metadata.orientation = orientation;
  // metadata.orientation = FIRVisionDetectorImageOrientationRightTop;
  image.metadata = metadata;
  FIRVisionObjectDetectorOptions *options = [[FIRVisionObjectDetectorOptions alloc] init];

  options.shouldEnableMultipleObjects = NO;
  options.shouldEnableClassification = NO;
  options.detectorMode = FIRVisionObjectDetectorModeStream;

  FIRVisionObjectDetector *objectDetector = [self.vision objectDetectorWithOptions:options];

  NSError *error;
  NSArray<FIRVisionObject *> *objects = [objectDetector resultsInImage:image error:&error];
  if (error == nil) {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(self) strongSelf = weakSelf;
      [strongSelf onDetectedObjects:objects inSampleBuffer:sampleBuffer];
    });
  }
}

/**
 * Call when objects are detected in given sample buffer. Caller must make sure that this method
 * runs on the main thread.
 *
 * @param objects The list of objects that is detected in given sample buffer.
 * @param sampleBuffer The given sampleBuffer.
 */
- (void)onDetectedObjects:(nullable NSArray<FIRVisionObject *> *)objects
           inSampleBuffer:(FIRSampleBuffer *)sampleBuffer {
  NSAssert([NSThread.currentThread isEqual:NSThread.mainThread],
           @"onDetectedObjects:inSampleBuffer is not running on the main thread");

  if (objects.count != 1) {
    [self startToDetect];
    return;
  }

  FIRVisionObject *object = [objects firstObject];
  if (object.trackingID.stringValue.length == 0) {
    [self startToDetect];
    return;
  }

  CGSize sampleBufferSize = [self sampleBufferSize:sampleBuffer.data];
  BOOL isOutOfBox =
      [self isPoint:CGPointMake(sampleBufferSize.width / 2, sampleBufferSize.height / 2)
          outOfRectArea:object.frame];
  if (isOutOfBox) {
    [self startToDetect];
    return;
  }

  switch (self.status) {
    case FIRODTStatus_Detecting: {
      [self cleanUpOverlayView];
      CGRect convertedRect = [self convertedRectOfObjectFrame:object.frame
                                      inSampleBufferFrameSize:sampleBufferSize];
      [self.overlayView showBoxInRect:convertedRect];
      [self startToConfirmObject:object sampleBuffer:sampleBuffer];
      break;
    }
    case FIRODTStatus_Confirming: {
      CGRect convertedRect = [self convertedRectOfObjectFrame:object.frame
                                      inSampleBufferFrameSize:sampleBufferSize];
      [self.overlayView showBoxInRect:convertedRect];
      self.lastDetectedObject = object;
      self.lastDetectedSampleBuffer = sampleBuffer;
      break;
    }
    case FIRODTStatus_Searching:  // Falls through
    case FIRODTStatus_Searched:   // Falls through
    case FIRODTStatus_NotStarted: {
      break;
    }
  }
}

#pragma mark - Status Handling

/**
 * Called when it needs to start the detection. Caller must make sure that this method runs on the
 * main thread.
 */
- (void)startToDetect {
  NSAssert([NSThread.currentThread isEqual:NSThread.mainThread],
           @"startToDetect is not running on the main thread");

  self.status = FIRODTStatus_Detecting;
  [self cleanUpOverlayView];
  [self clearLastDetectedObject];
  __weak typeof(self) weakSelf = self;
  dispatch_async(self.sessionQueue, ^{
    __strong typeof(self) strongSelf = weakSelf;
    if (strongSelf == nil) {
      return;
    }
#if !TARGET_IPHONE_SIMULATOR
    if (![strongSelf.session isRunning]) {
      [strongSelf.session startRunning];
    }
#endif
  });
}

/**
 * Starts a product search with last detected object. Caller must make sure that this method runs on
 * the main thread.
 */
- (void)startToSearch {
  NSAssert(
      [NSThread.currentThread isEqual:NSThread.mainThread],
      @"startToSearchWithImage:originalWidth:originalHeight is not running on the main thread");

  self.status = FIRODTStatus_Searching;

  CGSize originalSampleBufferSize = [self sampleBufferSize:self.lastDetectedSampleBuffer.data];

  UIImage *croppedImage = [self croppedImageFromSampleBuffer:self.lastDetectedSampleBuffer.data
                                                      inRect:self.lastDetectedObject.frame];
  CGRect convertedRect = [self convertedRectOfObjectFrame:self.lastDetectedObject.frame
                                  inSampleBufferFrameSize:originalSampleBufferSize];
  self.thumbnailWidthHeightRatio =
      self.lastDetectedObject.frame.size.height / self.lastDetectedObject.frame.size.width;
  self.overlayView.image.image = croppedImage;
  [self cleanUpOverlayView];
  [self.overlayView showImageInRect:convertedRect alpha:1];

  FIRProductSearchRequest *request = [[FIRProductSearchRequest alloc] initWithUIImage:croppedImage];
  GTMSessionFetcher *fetcher = [self.fetcherService fetcherWithRequest:request];
  if (request.URL.absoluteString.length == 0) {
    [self onSearchResponse:nil
                  forImage:croppedImage
             originalWidth:originalSampleBufferSize.width
            originalHeight:originalSampleBufferSize.height
           useFakeResponse:YES];
    [self clearLastDetectedObject];
    return;
  }
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [fetcher beginFetchWithCompletionHandler:^(NSData *_Nullable data, NSError *_Nullable error) {
      __strong typeof(self) strongSelf = weakSelf;
      if (strongSelf == nil) {
        return;
      }
      if (error) {
        NSLog(@"error in fetching: %@", error);
        [strongSelf clearLastDetectedObject];
        return;
      }
      __weak typeof(self) weakSelfInMainThrad = strongSelf;
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(self) strongSelfInMainThread = weakSelfInMainThrad;
        if (strongSelfInMainThread == nil) {
          return;
        }
        [strongSelfInMainThread onSearchResponse:data
                                        forImage:croppedImage
                                   originalWidth:originalSampleBufferSize.width
                                  originalHeight:originalSampleBufferSize.height
                                 useFakeResponse:NO];
        [strongSelfInMainThread clearLastDetectedObject];
      });
    }];
  });
}

/**
 * Called when search response is returned from server. Caller must make sure that this method runs
 * on the main thread.
 *
 * @param response The raw response from server on product search request.
 * @param image The image of the detected object that is to be searched.
 * @param width The width of the original sample buffer.
 * @param height The height of the original sample buffer.
 * @param useFakeResponse Whether to use fake response or send a product search request to the
 * server.
 */
- (void)onSearchResponse:(nullable NSData *)response
                forImage:(UIImage *)image
           originalWidth:(size_t)width
          originalHeight:(size_t)height
         useFakeResponse:(BOOL)useFakeResponse {
  NSAssert(
      [NSThread.currentThread isEqual:NSThread.mainThread],
      @"onSearchResponse:forImage:originalWidth:originalHeight is not running on the main thread");
  self.status = FIRODTStatus_Searched;
  NSArray<FIRProduct *> *products;
  if (useFakeResponse) {
    products = [self fakeProductSearchResults];
  } else {
    products = [FIRProduct productsFromResponse:response];
  }

  FIRProductListViewController *productsViewController =
      [[FIRProductListViewController alloc] initWithProducts:products];

  MDCBottomSheetController *bottomSheet =
      [[MDCBottomSheetController alloc] initWithContentViewController:productsViewController];
  bottomSheet.trackingScrollView = productsViewController.collectionView;

  bottomSheet.scrimColor = UIColor.clearColor;
  bottomSheet.dismissOnBackgroundTap = YES;
  bottomSheet.delegate = self;

  CGFloat contentHeight =
      productsViewController.collectionViewLayout.collectionViewContentSize.height;
  CGFloat screenHeight = self.view.frame.size.height;

  UIEdgeInsets safeInset = UIApplication.sharedApplication.keyWindow.safeAreaInsets;

  CGFloat toOffsetY = contentHeight > screenHeight
                          ? screenHeight / 2.0f - safeInset.bottom
                          : screenHeight - contentHeight - safeInset.top - safeInset.bottom;
  self.bottomSheetTargetHeight = toOffsetY;

  CGRect toFrame =
      CGRectMake(kThumbnailPaddingAround,                                                  // X
                 toOffsetY - kThumbnailbottomSheetTargetHeight - kThumbnailPaddingAround,  // Y
                 self.thumbnailWidthHeightRatio * kThumbnailbottomSheetTargetHeight,       // Width
                 kThumbnailbottomSheetTargetHeight);                                       // Height

  [UIView animateWithDuration:kBottomSheetAnimationDurationInSec
                   animations:^{
                     [self.overlayView showImageInRect:toFrame alpha:1];
                   }];
  [self presentViewController:bottomSheet animated:YES completion:nil];
}

/**
 * Calculates the ratio of current value based on `from` and `to` value.
 *
 * @param currentValue The current value.
 * @param fromValue The start point of the range.
 * @param toValue The end point of the range.
 * @return Position of current value in the whole range. It falls into [0,1].
 */
- (CGFloat)ratioOfCurrentValue:(CGFloat)currentValue from:(CGFloat)fromValue to:(CGFloat)toValue {
  CGFloat ratio = (currentValue - fromValue) / (toValue - fromValue);
  ratio = MIN(ratio, 1);
  return MAX(ratio, 0);
}

/**
 * Called to confirm on the given object.Caller must make sure that this method runs on the main
 * thread.
 *
 * @param object The object to confirm. It will be regarded as the same object if its objectID stays
 *     the same during this stage.
 * @param sampleBuffer The original sample buffer that this object was detected in.
 */
- (void)startToConfirmObject:(FIRVisionObject *)object
                sampleBuffer:(FIRSampleBuffer *)sampleBuffer {
  NSAssert([NSThread.currentThread isEqual:NSThread.mainThread],
           @"startToConfirmObject:sampleBuffer is not running on the main thread");
  [self clearLastDetectedObject];
  NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:kConfirmingDurationInSec
                                                    target:self
                                                  selector:@selector(onTimerFired)
                                                  userInfo:nil
                                                   repeats:NO];
  [self.timers addObject:timer];

  self.status = FIRODTStatus_Confirming;
  self.lastDetectedObject = object;
  self.lastDetectedSampleBuffer = sampleBuffer;
}

/** Called when timer is up and the detected object is confirmed. */
- (void)onTimerFired {
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    __strong typeof(self) strongSelf = weakSelf;
    if (strongSelf == nil) {
      return;
    }
    switch (strongSelf.status) {
      case FIRODTStatus_Confirming: {
#if !TARGET_IPHONE_SIMULATOR
        __weak typeof(self) weakSelfInSessionQueue = strongSelf;
        dispatch_async(strongSelf.sessionQueue, ^{
          __strong typeof(self) strongSelfInSessionQueue = weakSelfInSessionQueue;
          [strongSelfInSessionQueue.session stopRunning];
        });
#endif
        [strongSelf startToSearch];
        break;
      }
      case FIRODTStatus_Detecting:   // Falls through
      case FIRODTStatus_NotStarted:  // Falls through
      case FIRODTStatus_Searched:    // Falls through
      case FIRODTStatus_Searching: {
        break;
      }
    }
  });
}

/**
 * Overrides setter for `status` property. It also shows corresponding indicator/message with the
 * status change. Caller must make sure that this method runs on the main thread.
 *
 * @param status The new status.
 */
- (void)setStatus:(FIRODTStatus)status {
  NSAssert([NSThread.currentThread isEqual:NSThread.mainThread],
           @"setStatus is not running on the main thread");

  if (_status == status) {
    return;
  }
  _status = status;

  switch (status) {
    case FIRODTStatus_Detecting: {
      [self showMessage:kDetectingStageMessage];
      [self.detectingReticle setHidden:NO];
      [self.confirmingSpinner setHidden:YES];
      [self showSearchingIndicator:NO];
      break;
    }
    case FIRODTStatus_Confirming: {
      [self showMessage:kConfirmingStageMessage];
      [self.detectingReticle setHidden:YES];
      [self.confirmingSpinner setHidden:NO];
      [self showSearchingIndicator:NO];
      break;
    }
    case FIRODTStatus_Searching: {
      [self showMessage:kSearchingMessage];
      [self.confirmingSpinner setHidden:YES];
      [self.detectingReticle setHidden:YES];
      [self showSearchingIndicator:YES];
      break;
    }
    case FIRODTStatus_Searched: {
      [self hideMessage];
      [self.confirmingSpinner setHidden:YES];
      [self.detectingReticle setHidden:YES];
      [self showSearchingIndicator:NO];
      break;
    }
    default: {
      [self hideMessage];
      [self.confirmingSpinner setHidden:YES];
      [self.detectingReticle setHidden:YES];
      [self showSearchingIndicator:NO];
      break;
    }
  }
}

#pragma mark - Util methods

/**
 * Returns size of given `CMSampleBufferRef`.
 *
 * @param sampleBuffer The `CMSampleBufferRef` to get size from.
 * @return The size of the given `CMSampleBufferRef`. It describes its width and height.
 */
- (CGSize)sampleBufferSize:(CMSampleBufferRef)sampleBuffer {
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  size_t imageWidth = CVPixelBufferGetWidth(imageBuffer);
  size_t imageHeight = CVPixelBufferGetHeight(imageBuffer);
  return CGSizeMake(imageWidth, imageHeight);
}

/**
 * Whether the given point is outside of the given rect area.
 *
 * @param point The given point.
 * @param rect Rect of the given area.
 * @return YES if the point is out of given rect area,otherwise, NO.
 */
- (BOOL)isPoint:(CGPoint)point outOfRectArea:(CGRect)rect {
  size_t pointX = point.x;
  size_t pointY = point.y;
  size_t minX = rect.origin.x;
  size_t maxX = rect.origin.x + rect.size.width;
  size_t minY = rect.origin.y;
  size_t maxY = rect.origin.y + rect.size.height;

  if (minX > pointX && maxX > pointX) {
    return YES;
  }
  if (minX < pointX && maxX < pointX) {
    return YES;
  }
  if (minY > pointY && maxY > pointY) {
    return YES;
  }
  if (minY < pointY && maxY < pointY) {
    return YES;
  }
  return NO;
}

/**
 * Converts given frame of a detected object to a `CGRect` in coordinate system of current view.
 *
 * @param frame The frame of detected object.
 * @param size The frame size of the sample buffer.
 * @return Converted rect.
 */
- (CGRect)convertedRectOfObjectFrame:(CGRect)frame inSampleBufferFrameSize:(CGSize)size {
  CGRect normalizedRect = CGRectMake(frame.origin.x / size.width,       // X
                                     frame.origin.y / size.height,      // Y
                                     frame.size.width / size.width,     // Width
                                     frame.size.height / size.height);  // Height
  CGRect convertedRect = [self.previewLayer rectForMetadataOutputRectOfInterest:normalizedRect];
  return CGRectStandardize(convertedRect);
}

/**
 * Crops given `CMSampleBufferRef` with given rect.
 *
 * @param sampleBuffer The sample buffer to be cropped.
 * @param rect The rect of the area to be cropped.
 * @return Returns cropped image to the given rect.
 */
- (UIImage *)croppedImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer inRect:(CGRect)rect {
  CMSampleBufferRef croppedSampleBuffer = [FIRImageUtilities croppedSampleBuffer:sampleBuffer
                                                                        withRect:rect];
  UIImage *croppedImage = [FIRImageUtilities imageFromSampleBuffer:croppedSampleBuffer];
  return [FIRUIUtilities adjustOrientationForCameraImage:croppedImage];
}

/**
 * Shows/Hides searching indicator.
 *
 * @param isVisible Whether to show/hide searching indicator. YES to show, NO to hide.
 */
- (void)showSearchingIndicator:(BOOL)isVisible {
  if (isVisible) {
    [self.searchingIndicator setHidden:NO];
    [self.searchingIndicator startAnimating];
  } else {
    [self.searchingIndicator setHidden:YES];
    [self.searchingIndicator stopAnimating];
  }
}

- (void)showMessage:(NSString *)message {
  if ([self.messageView.titleLabel.text isEqual:message]) {
    return;
  }
  self.messageView.titleLabel.text = message;
  [self.messageView sizeToFit];
  CGSize size = [self.messageView sizeThatFits:self.view.frame.size];
  CGFloat startX = (self.view.frame.size.width - size.width) / 2.0f;
  CGFloat startY = self.view.frame.size.height - kChipBottomPadding - size.height;
  self.messageView.frame = CGRectMake(startX, startY, size.width, size.height);

  if (self.messageView.alpha != kTransparentAlpha) {
    return;
  }
  self.messageView.alpha = kTransparentAlpha;
  [UIView animateWithDuration:kChipFadeInDuration
                   animations:^{
                     self.messageView.alpha = kOpaqueAlpha;
                   }];

  CGPoint messageCenter =
      CGPointMake(CGRectGetMidX(self.messageView.frame), CGRectGetMidY(self.messageView.frame));

  self.messageView.transform =
      CGAffineTransformScale(self.messageView.transform, kChipScaleFromRatio, kChipScaleFromRatio);
  [self.messageView sizeToFit];

  [UIView animateWithDuration:kChipScaleDuration
                   animations:^{
                     self.messageView.center = messageCenter;
                     self.messageView.transform = CGAffineTransformScale(
                         self.messageView.transform, kChipScaleToRatio, kChipScaleToRatio);
                   }];
}

- (void)hideMessage {
  [UIView animateWithDuration:kChipFadeInDuration
                   animations:^{
                     self.messageView.alpha = kTransparentAlpha;
                   }];
}

// Generates fake product search results for demo when there are no real backend server hooked up.
- (NSArray<FIRProduct *> *)fakeProductSearchResults {
  NSMutableArray<FIRProduct *> *fakeProductSearchResults = [NSMutableArray array];
  for (NSInteger index = 0; index < kFakeProductSearchResultCount; index++) {
    FIRProduct *product = [[FIRProduct alloc] init];
    product.productName = [NSString stringWithFormat:kFakeProductNameFormat, index + 1];
    product.productTypeName = kFakeProductTypeName;
    product.priceFullText = kFakeProductPriceText;
    product.itemNumber = kFakeProductItemNumberText;
    [fakeProductSearchResults addObject:product];
  }
  return [fakeProductSearchResults copy];
}

@end

NS_ASSUME_NONNULL_END
