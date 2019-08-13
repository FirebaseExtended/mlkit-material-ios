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

import UIKit

//* Overlay view that shows on top of the object detection window.
// Box related values.
private let kBoxBorderWidth: CGFloat = 2.0
private let kImageBorderWidth: CGFloat = 4.0
private let kBoxBackgroundAlpha: CGFloat = 0.12
private let kBoxCornerRadius: CGFloat = 12.0
// Image related values.
private let kImageBackgroundAlpha: CGFloat = 0.6
private let kStrokeStartValueZero: CGFloat = 0.0
private let kStrokeEndValueOne: CGFloat = 1.0

class DetectionOverlayView: UIView {
  //* Thumbnail image of the product to be searched.
  private(set) var image = UIImageView()
  //* Layer to show a box in the view.
  private var boxLayer = CAShapeLayer()
  //* Layer to show a mask outside of the box in the view.
  private var boxMaskLayer = CAShapeLayer()

  /**
   * Shows a box in the given rect. It also shows a scrim background outside of the box area.
   *
   * @param rect The given area of the box.
   */
  func showBox(in rect: CGRect) {
    boxMaskLayer.isHidden = false
    let maskPath = UIBezierPath(rect: bounds)
    let boxPath = UIBezierPath(roundedRect: rect, cornerRadius: kBoxCornerRadius).reversing()
    maskPath.append(boxPath)

    boxMaskLayer.frame = frame
    boxMaskLayer.path = maskPath.cgPath
    boxMaskLayer.strokeStart = kStrokeStartValueZero
    boxMaskLayer.strokeEnd = kStrokeEndValueOne
    layer.backgroundColor = UIColor.black.withAlphaComponent(kBoxBackgroundAlpha).cgColor
    layer.mask = boxMaskLayer

    boxLayer.isHidden = false
    boxLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: kBoxCornerRadius).cgPath
    boxLayer.lineWidth = kBoxBorderWidth
    boxLayer.strokeStart = kStrokeStartValueZero
    boxLayer.strokeEnd = kStrokeEndValueOne
    boxLayer.strokeColor = UIColor.white.cgColor
    boxLayer.fillColor = nil
  }

  /**
   * Shows image in the given area of given alpha. It also shows a border around the image as well as
   * a dark background.
   *
   * @param rect The frame of the image.
   * @param alpha The alpha value of the image view.
   */
  func showImage(in rect: CGRect, alpha: CGFloat) {
    image.isHidden = false
    image.alpha = alpha
    image.frame = rect
    layer.backgroundColor = UIColor.black.withAlphaComponent(kImageBackgroundAlpha).cgColor
  }

  //* Clears all elements in the view.
  func hideSubviews() {
    hideBox()
    hideImage()
  }

  // MARK: - Public
  override init(frame: CGRect) {
    super.init(frame: frame)

    layer.addSublayer(boxMaskLayer)

    boxLayer.cornerRadius = kBoxCornerRadius
    layer.addSublayer(boxLayer)

    image.layer.cornerRadius = kBoxCornerRadius
    image.layer.borderWidth = kImageBorderWidth
    image.layer.masksToBounds = true
    image.layer.borderColor = UIColor.white.cgColor
    addSubview(image)
  }

  // MARK: - Private

  //* Hides box in the view.
  func hideBox() {
    layer.mask = nil
    boxMaskLayer.isHidden = true
    boxLayer.isHidden = true
  }

  //* Hides image in the view.
  func hideImage() {
    image.isHidden = true
    layer.backgroundColor = nil
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
