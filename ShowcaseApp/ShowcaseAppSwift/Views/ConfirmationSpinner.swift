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

import CoreFoundation
import QuartzCore
import UIKit

//* A progress ring located at the center of the screen for confirming the user intention.

// Layout values.
private let kInnerRingRadius: CGFloat = 14.0
private let kInnerRingDiameter = 2.0 * kInnerRingRadius
private let kInnerRingLineWidth: CGFloat = 2.0
private let kOuterRingRadius: CGFloat = 24.0
private let kOuterRingDiameter = 2.0 * kOuterRingRadius
private let kOuterRingLineWidth: CGFloat = 4.0
private let kOuterRingStrokeAlpha: CGFloat = 0.6
private let kOuterRingFillAlpha: CGFloat = 0.12
private let kSpinnerRingStartAngle: CGFloat = -1.57079632679 // -0.5 * pi in radians
private let kSpinnerRingEndAngle: CGFloat = 4.71238898038 // 1.5 * pi in radians
private let kStartValueZero: CGFloat = 0.0
private let kEndValueFull: CGFloat = 1.0
private let kDefaultConfirmingDuration: CFTimeInterval = 1.5
private let kStrokeEndKeyPath = "strokeEnd"

/**
 * The spinner consists of 3 rings, an inner ring and an outer ring of fixed size, and an animating
 * spinner ring that animates. They all live in their own layers.
 */
class ConfirmationSpinner: UIView {

  //* The duration of the confirming period.
  private var duration = kDefaultConfirmingDuration
  //* Whether the spinner is currently confirming.
  private var isConfirming = false
  //* The layer hosting the fixed inner ring.
  private var innerRingLayer = CAShapeLayer()
  //* The layer hosting the fixed outer ring.
  private var outerRingLayer = CAShapeLayer()
  //* The layer hosting the animating spinner ring.
  private var spinnerRingLayer = CAShapeLayer()

  //* Starts confirming by animating spinner. Does nothing if confirming is already underway.
  func startConfirming() {
    if isConfirming {
      return
    }

    isConfirming = true
    startAnimation()
  }

  //* Stops any pending confirmation and resets the spinner.
  func reset() {
    spinnerRingLayer.removeAllAnimations()
    let circle = UIBezierPath(arcCenter: CGPoint(x: kOuterRingRadius, y: kOuterRingRadius), radius: kOuterRingRadius,
                              startAngle: kSpinnerRingStartAngle, endAngle: kSpinnerRingEndAngle, clockwise: true)
    spinnerRingLayer.path = circle.cgPath
    spinnerRingLayer.lineWidth = kOuterRingLineWidth
    spinnerRingLayer.strokeStart = kStartValueZero
    spinnerRingLayer.strokeEnd = kStartValueZero
    spinnerRingLayer.strokeColor = UIColor.white.cgColor
    spinnerRingLayer.fillColor = UIColor.clear.cgColor
    isConfirming = false
  }

  /**
   * Initializes a `FIRConfirmationSpinner` with the given confirming duration.
   *
   * @param duration The duration of the confirming period.
   * @return A new instance of `FIRConfirmationSpinner` with the given confirming duration.
   */
  convenience init(duration: CFTimeInterval) {
    self.init(frame: CGRect.zero)
    self.duration = duration
  }

  // MARK: - Public
  override init(frame: CGRect) {
    super.init(frame: frame)
    outerRingLayer.opacity = Float(kOuterRingStrokeAlpha)
    createRing(in: CGRect(x: 0, y: 0, width: kOuterRingDiameter, height: kOuterRingDiameter), layer: outerRingLayer,
               lineWidth: kOuterRingLineWidth, stroke: UIColor.white,
               fill: UIColor.black.withAlphaComponent(kOuterRingFillAlpha))
    layer.addSublayer(outerRingLayer)

    spinnerRingLayer.opacity = Float(kOuterRingStrokeAlpha)
    layer.addSublayer(spinnerRingLayer)

    reset()

      createRing(in: CGRect(x: 0, y: 0, width: kInnerRingDiameter, height: kInnerRingDiameter), layer: innerRingLayer,
                 lineWidth: kInnerRingLineWidth, stroke: UIColor.white, fill: UIColor.clear)

      layer.addSublayer(innerRingLayer)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var isHidden: Bool {
    get {
      return super.isHidden
    }
    set(hidden) {
      super.isHidden = hidden
      if !hidden {
        startConfirming()
      } else {
        reset()
      }
    }
  }

  // MARK: - UIView(UIViewHierarchy)
  override func layoutSubviews() {
    super.layoutSubviews()
    let centerX = self.centerX()
    let centerY = self.centerY()
    let outerRingRect = CGRect(x: centerX - kOuterRingRadius, y: centerY - kOuterRingRadius,
                               width: kOuterRingDiameter, height: kOuterRingDiameter)
    outerRingLayer.frame = outerRingRect
    outerRingLayer.bounds = outerRingRect
    outerRingLayer.position = outerRingRect.origin

    spinnerRingLayer.frame = outerRingRect
    spinnerRingLayer.bounds = outerRingRect
    spinnerRingLayer.position = outerRingRect.origin

    let innerRingRect = CGRect(x: centerX - kInnerRingRadius, y: centerY - kInnerRingRadius,
                               width: kInnerRingDiameter, height: kInnerRingDiameter)
    innerRingLayer.frame = innerRingRect
    innerRingLayer.bounds = innerRingRect
    innerRingLayer.position = innerRingRect.origin
  }

  override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)
    // If the reticle is removed from the window, we should stop animating to avoid chewing up CPU.
    if newWindow == nil {
      reset()
    }
  }

  // MARK: - Private

  /**
   * Creates a ring inscribed in the given rectangle with the given line width, stroke color, and
   * fill color.
   *
   * @param rect The rectangle in which to inscribe the ring.
   * @param layer The layer in which to draw the ring.
   * @param lineWidth The line width of the ring.
   * @param strokeColor The color of the ring.
   * @param fillColor The color to fill inside the ring.
   */
  func createRing(in rect: CGRect, layer: CAShapeLayer, lineWidth: CGFloat, stroke strokeColor: UIColor,
                  fill fillColor: UIColor) {
    layer.path = UIBezierPath(ovalIn: rect).cgPath
    layer.lineWidth = lineWidth
    layer.strokeStart = kStartValueZero
    layer.strokeEnd = kEndValueFull
    layer.strokeColor = strokeColor.cgColor
    layer.fillColor = fillColor.cgColor
  }

  //* Fills in the spinner ring with a linear timing function.
  func startAnimation() {
    CATransaction.begin()
    let fill = CABasicAnimation()
    fill.keyPath = kStrokeEndKeyPath
    fill.fromValue = NSNumber(value: 0.0)
    fill.toValue = NSNumber(value: 1.0)
    fill.duration = duration
    fill.timingFunction = CAMediaTimingFunction(name: .linear)
    fill.fillMode = .forwards
    fill.isRemovedOnCompletion = false
    spinnerRingLayer.add(fill, forKey: nil)
    CATransaction.commit()
  }

  //* Determines whether the main screen is in the portrait mode.
  func isPortraitMode() -> Bool {
    let screenSize = UIScreen.main.bounds.size
    return screenSize.height > screenSize.width
  }

  //* Returns the center X coordinate of the main screen.
  func centerX() -> CGFloat {
    return isPortraitMode() ? center.x : center.y
  }

  //* Returns the center Y coordinate of the main screen.
  func centerY() -> CGFloat {
    return isPortraitMode() ? center.y : center.x
  }
}
