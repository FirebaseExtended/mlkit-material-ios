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

import AVFoundation
import Firebase

/**
 * A utility for creating UI.
 */

class UIUtilities: NSObject {
  /**
   * Converts given `AVCaptureDevicePosition` and `UIDeviceOrientation` into
   * `VisionDetectorImageOrientation`.
   */
  class func imageOrientation(from deviceOrientation: UIDeviceOrientation,
                              withCaptureDevicePosition position: AVCaptureDevice.Position) -> VisionDetectorImageOrientation {
    var currentOrientation = deviceOrientation
    if deviceOrientation == .faceDown || deviceOrientation == .faceUp || deviceOrientation == .unknown {
      currentOrientation = UIUtilities.currentUIOrientation()
    }
    var orientation = VisionDetectorImageOrientation.topLeft
    switch currentOrientation {
    case .portrait:
      if position == .front {
        orientation = .leftTop
      } else {
        orientation = .rightTop
      }
    case .landscapeLeft:
      orientation = position == .front ? .bottomLeft : .topLeft
    case .portraitUpsideDown:
      orientation = position == .front ? .rightBottom : .leftBottom
    case .landscapeRight:
      orientation = position == .front ? .topRight : .bottomRight
    case .unknown, .faceUp, .faceDown:
      orientation = .topLeft
    @unknown default:
      break
    }

    return orientation
  }

  /**
   * Rotates the given image, based on the current device orientation, so its orientation is `.up`.
   *
   * @param image The image that comes from camera.
   * @return Image with orientation adjusted to upright.
   */
  class func orientedUpImage(from image: UIImage) -> UIImage {
    let orientation = UIUtilities.imageOrientation(from: UIDevice.current.orientation, withCaptureDevicePosition: .back)
    // No-op if the orientation is already correct
    if orientation == .topLeft {
      return image
    }

    let size = image.size
    switch orientation {
    case .rightTop:
      UIGraphicsBeginImageContext(CGSize(width: size.height, height: size.width))
      if let CGImage = image.cgImage {
        UIImage(cgImage: CGImage, scale: 1.0, orientation: .right)
          .draw(in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
      }
      let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      return rotatedImage!
    case .topLeft, .topRight, .bottomRight, .bottomLeft, .leftTop, .rightBottom, .leftBottom:
      // TODO: handle other cases as well.
      return image
    default:
      return image
    }
  }

  //* Returns safe area insets of the view.
  class func safeAreaInsets() -> UIEdgeInsets {
    #if swift(>=3.2)
    if #available(iOS 11.0, *) {
      return (UIApplication.shared.keyWindow?.safeAreaInsets)!
    }
    #endif
    let statusBarFrame = UIApplication.shared.statusBarFrame
    return UIEdgeInsets(top: min(statusBarFrame.size.width, statusBarFrame.size.height), left: 0, bottom: 0, right: 0)
  }

  // MARK: - Public

  class func currentUIOrientation() -> UIDeviceOrientation {
    let deviceOrientation: (() -> UIDeviceOrientation) = {
      switch UIApplication.shared.statusBarOrientation {
      case .landscapeLeft:
        return .landscapeRight
      case .landscapeRight:
        return .landscapeLeft
      case .portraitUpsideDown:
        return .portraitUpsideDown
      case .portrait, .unknown:
        return .portrait
      }
    }
    if Thread.isMainThread {
      return deviceOrientation()
    }
    var currentOrientation: UIDeviceOrientation = .portrait

    // Must access the `statusBarOrientation` on the main thread only.
    DispatchQueue.main.sync(execute: {
      currentOrientation = deviceOrientation()
    })
    return currentOrientation
  }
}
