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

#import "FIRUIUtilities.h"

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Use the following imports for CocoaPods:
@import FirebaseMLVision;

// Use the following imports for google3:
//#import "googlemac/iPhone/FirebaseML/Vision/Public/FIRVisionImageMetadata.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FIRUIUtilities

#pragma mark - Public

+ (FIRVisionDetectorImageOrientation)
    imageOrientationFromOrientation:(UIDeviceOrientation)deviceOrientation
          withCaptureDevicePosition:(AVCaptureDevicePosition)position {
  if (deviceOrientation == UIDeviceOrientationFaceDown ||
      deviceOrientation == UIDeviceOrientationFaceUp ||
      deviceOrientation == UIDeviceOrientationUnknown) {
    deviceOrientation = [FIRUIUtilities currentUIOrientation];
  }
  FIRVisionDetectorImageOrientation orientation = FIRVisionDetectorImageOrientationTopLeft;
  switch (deviceOrientation) {
    case UIDeviceOrientationPortrait:
      if (position == AVCaptureDevicePositionFront) {
        orientation = FIRVisionDetectorImageOrientationLeftTop;
      } else {
        orientation = FIRVisionDetectorImageOrientationRightTop;
      }
      break;
    case UIDeviceOrientationLandscapeLeft:
      orientation = position == AVCaptureDevicePositionFront
                        ? FIRVisionDetectorImageOrientationBottomLeft
                        : FIRVisionDetectorImageOrientationTopLeft;
      break;
    case UIDeviceOrientationPortraitUpsideDown:
      orientation = position == AVCaptureDevicePositionFront
                        ? FIRVisionDetectorImageOrientationRightBottom
                        : FIRVisionDetectorImageOrientationLeftBottom;
      break;
    case UIDeviceOrientationLandscapeRight:
      orientation = position == AVCaptureDevicePositionFront
                        ? FIRVisionDetectorImageOrientationTopRight
                        : FIRVisionDetectorImageOrientationBottomRight;
      break;
    case UIDeviceOrientationUnknown:
    case UIDeviceOrientationFaceUp:
    case UIDeviceOrientationFaceDown:
      orientation = FIRVisionDetectorImageOrientationTopLeft;
      break;
  }

  return orientation;
}

+ (UIDeviceOrientation)currentUIOrientation {
  UIDeviceOrientation (^deviceOrientation)(void) = ^{
    switch (UIApplication.sharedApplication.statusBarOrientation) {
      case UIInterfaceOrientationLandscapeLeft:
        return UIDeviceOrientationLandscapeRight;
        break;
      case UIInterfaceOrientationLandscapeRight:
        return UIDeviceOrientationLandscapeLeft;
        break;
      case UIInterfaceOrientationPortraitUpsideDown:
        return UIDeviceOrientationPortraitUpsideDown;
        break;
      case UIInterfaceOrientationPortrait:
      case UIInterfaceOrientationUnknown:
        return UIDeviceOrientationPortrait;
        break;
    }
  };
  if (NSThread.isMainThread) {
    return deviceOrientation();
  }
    __block UIDeviceOrientation currentOrientation = UIDeviceOrientationPortrait;

    // Must access the `statusBarOrientation` on the main thread only.
    dispatch_sync(dispatch_get_main_queue(), ^{
      currentOrientation = deviceOrientation();
    });
    return currentOrientation;
}

+ (UIImage *)adjustOrientationForCameraImage:(UIImage *)image {
  FIRVisionDetectorImageOrientation orientation =
      [FIRUIUtilities imageOrientationFromOrientation:UIDevice.currentDevice.orientation
                            withCaptureDevicePosition:AVCaptureDevicePositionBack];

  // No-op if the orientation is already correct
  if (orientation == FIRVisionDetectorImageOrientationTopLeft) return image;

  // Calculate the proper transformation to make the image upright.
  // Steps: 1. Rotate the image if it's Left, Right or Down oriented. 2. Flip the image if it is
  // mirrored.
  CGAffineTransform transform = CGAffineTransformIdentity;

  switch (orientation) {
    case FIRVisionDetectorImageOrientationRightTop:
      transform = CGAffineTransformTranslate(transform, 0, image.size.height);
      transform = CGAffineTransformRotate(transform, -M_PI_2);
      break;
    case FIRVisionDetectorImageOrientationTopLeft:      // Falls through
    case FIRVisionDetectorImageOrientationTopRight:     // Falls through
    case FIRVisionDetectorImageOrientationBottomRight:  // Falls through
    case FIRVisionDetectorImageOrientationBottomLeft:   // Falls through
    case FIRVisionDetectorImageOrientationLeftTop:      // Falls through
    case FIRVisionDetectorImageOrientationRightBottom:  // Falls through
    case FIRVisionDetectorImageOrientationLeftBottom:
      // TODO: handle other cases as well.
      break;
  }

  // Draws the underlying CGImage into a new context, applying the transform calculated above.
  CGContextRef ctx = CGBitmapContextCreate(
      NULL, image.size.width, image.size.height, CGImageGetBitsPerComponent(image.CGImage), 0,
      CGImageGetColorSpace(image.CGImage), CGImageGetBitmapInfo(image.CGImage));
  CGContextConcatCTM(ctx, transform);
  switch (orientation) {
    case FIRVisionDetectorImageOrientationRightTop:
      CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.height, image.size.width), image.CGImage);
      break;
    case FIRVisionDetectorImageOrientationTopLeft:      // Falls through
    case FIRVisionDetectorImageOrientationTopRight:     // Falls through
    case FIRVisionDetectorImageOrientationBottomRight:  // Falls through
    case FIRVisionDetectorImageOrientationBottomLeft:   // Falls through
    case FIRVisionDetectorImageOrientationLeftTop:      // Falls through
    case FIRVisionDetectorImageOrientationRightBottom:  // Falls through
    FIRVisionDetectorImageOrientationLeftBottom:
      // TODO: handle other cases as well.
      break;
  }

  // Creates a new UIImage from the drawing context
  CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
  UIImage *uiImage = [UIImage imageWithCGImage:cgImage];
  CGContextRelease(ctx);
  CGImageRelease(cgImage);
  return uiImage;
}

@end

NS_ASSUME_NONNULL_END
