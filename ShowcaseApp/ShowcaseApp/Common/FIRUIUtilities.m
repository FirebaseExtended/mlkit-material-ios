/**
 * Copyright 2019 Google ML Kit team
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

@import FirebaseMLVision;

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

+ (UIImage *)orientedUpImageFromImage:(UIImage *)image {
  FIRVisionDetectorImageOrientation orientation =
  [FIRUIUtilities imageOrientationFromOrientation:UIDevice.currentDevice.orientation
                        withCaptureDevicePosition:AVCaptureDevicePositionBack];
  // No-op if the orientation is already correct
  if (orientation == FIRVisionDetectorImageOrientationTopLeft) return image;

  CGSize size = image.size;
  switch (orientation) {
    case FIRVisionDetectorImageOrientationRightTop: {
      UIGraphicsBeginImageContext(CGSizeMake(size.height, size.width));
      [[UIImage imageWithCGImage:image.CGImage scale:1.0 orientation:UIImageOrientationRight]
       drawInRect:CGRectMake(0, 0, size.height, size.width)];
      UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
      return rotatedImage;
    }
    case FIRVisionDetectorImageOrientationTopLeft:
    case FIRVisionDetectorImageOrientationTopRight:
    case FIRVisionDetectorImageOrientationBottomRight:
    case FIRVisionDetectorImageOrientationBottomLeft:
    case FIRVisionDetectorImageOrientationLeftTop:
    case FIRVisionDetectorImageOrientationRightBottom:
    case FIRVisionDetectorImageOrientationLeftBottom: {
      // TODO: handle other cases as well.
      return image;
    }
  }
}

+ (UIEdgeInsets)safeAreaInsets {
#if defined(__IPHONE_11_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0)
  if (@available(iOS 11.0, *)) {
    return UIApplication.sharedApplication.keyWindow.safeAreaInsets;
  }
#endif  // defined(__IPHONE_11_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0)
  CGRect statusBarFrame = UIApplication.sharedApplication.statusBarFrame;
  return UIEdgeInsetsMake(MIN(statusBarFrame.size.width, statusBarFrame.size.height), 0, 0, 0);
}

@end

NS_ASSUME_NONNULL_END
