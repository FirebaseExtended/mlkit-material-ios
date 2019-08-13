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

import CoreMedia
import MetalKit
import UIKit

//* Provides image related utility APIs.
#if __ARM_NEON__
#endif

//* `CIContext` to render pixel buffer to images.
private var gCIContext: CIContext!

class ImageUtilities: NSObject {
  /**
   * Converts a `CMSampleBuffer` to a `UIImage`, returns `nil` when `sampleBuffer` is unsupported.
   * Currently this method only handles `CMSampleBufferRef` with RGB color space.
   *
   * @param sampleBuffer The given `CMSampleBufferRef`.
   * @return Converted `UIImage`.
   */
  class func image(from sampleBuffer: CMSampleBuffer?) -> UIImage? {
    guard let sampleBuffer = sampleBuffer else {
      print("Sample buffer is NULL.")
      return nil
    }
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      print("Invalid sample buffer.")
      return nil
    }

    CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags.readOnly)

    let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
    let bitPerComponent: size_t = 8 // TODO: This may vary on other formats.

    let width = CVPixelBufferGetWidth(imageBuffer)
    let height = CVPixelBufferGetHeight(imageBuffer)

    // TODO: Add more support for non-RGB color space.
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    // TODO: Add more support for other formats.
    guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: bitPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) else {
      print("Failed to create CGContextRef")
      CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
      return nil
    }

    guard let cgImage = context.makeImage() else {
      print("Failed to create CGImage")
      CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
      return nil
    }

    CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)

    let image = UIImage(cgImage: cgImage)
    return image
  }

  /**
   * Crops `CMSampleBuffer` to a specified rect. This will not alter the original data. Currently this
   * method only handles `CMSampleBufferRef` with RGB color space.
   *
   * @param sampleBuffer The original `CMSampleBuffer`.
   * @param rect The rect to crop to.
   * @return A `CMSampleBuffer` cropped to the given rect.
   */
  class func croppedSampleBuffer(_ sampleBuffer: CMSampleBuffer,
                                 with rect: CGRect) -> CMSampleBuffer? {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

    CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)

    let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
    let width = CVPixelBufferGetWidth(imageBuffer)
    let bytesPerPixel = bytesPerRow / width
    guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else { return nil }
    let baseAddressStart = baseAddress.assumingMemoryBound(to: UInt8.self)

    var cropX = Int(rect.origin.x)
    let cropY = Int(rect.origin.y)

    // Start pixel in RGB color space can't be odd.
    if cropX % 2 != 0 {
      cropX += 1
    }

    let cropStartOffset = Int(cropY * bytesPerRow + cropX * bytesPerPixel)

    var pixelBuffer: CVPixelBuffer!
    var error: CVReturn

    // Initiates pixelBuffer.
    let pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer)
    let options = [
      kCVPixelBufferCGImageCompatibilityKey: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey: true,
      kCVPixelBufferWidthKey: rect.size.width,
      kCVPixelBufferHeightKey: rect.size.height
      ] as [CFString : Any]

    error = CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                         Int(rect.size.width),
                                         Int(rect.size.height),
                                         pixelFormat,
                                         &baseAddressStart[cropStartOffset],
                                         Int(bytesPerRow),
                                         nil,
                                         nil,
                                         options as CFDictionary,
                                         &pixelBuffer)
    if error != kCVReturnSuccess {
      print("Crop CVPixelBufferCreateWithBytes error \(Int(error))")
      return nil
    }

    // Cropping using CIImage.
    var ciImage = CIImage(cvImageBuffer: imageBuffer)
    ciImage = ciImage.cropped(to: rect)
    // CIImage is not in the original point after cropping. So we need to pan.
    ciImage = ciImage.transformed(by: CGAffineTransform(translationX: CGFloat(-cropX), y: CGFloat(-cropY)))

    gCIContext.render(ciImage, to: pixelBuffer!)

    // Prepares sample timing info.
    var sampleTime = CMSampleTimingInfo()
    sampleTime.duration = CMSampleBufferGetDuration(sampleBuffer)
    sampleTime.presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
    sampleTime.decodeTimeStamp = CMSampleBufferGetDecodeTimeStamp(sampleBuffer)

    var videoInfo: CMVideoFormatDescription!
    error = CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                         imageBuffer: pixelBuffer, formatDescriptionOut: &videoInfo)
    if error != kCVReturnSuccess {
      print("CMVideoFormatDescriptionCreateForImageBuffer error \(Int(error))")
      CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags.readOnly)
      return nil
    }

    // Creates `CMSampleBufferRef`.
    var resultBuffer: CMSampleBuffer?
    error = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                               imageBuffer: pixelBuffer,
                                               dataReady: true,
                                               makeDataReadyCallback: nil,
                                               refcon: nil,
                                               formatDescription: videoInfo,
                                               sampleTiming: &sampleTime,
                                               sampleBufferOut: &resultBuffer)
    if error != kCVReturnSuccess {
      print("CMSampleBufferCreateForImageBuffer error \(Int(error))")
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
    return resultBuffer
  }

}

extension ImageUtilities {

  public final class func doBadSwizzleStuff() {
    guard gCIContext == nil else { return }
    guard let defaultDevice = MTLCreateSystemDefaultDevice() else { return }
    gCIContext = CIContext(mtlDevice: defaultDevice)
  }
}
