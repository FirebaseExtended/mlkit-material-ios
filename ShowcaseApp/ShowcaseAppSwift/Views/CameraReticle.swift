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

/**
 * A camera reticle that locates at the center of screen and uses ambient ripple to indicate that
 * the system is active but has not detected an object yet.
 */

// Layout values.
private let kInnerRingRadius: CGFloat = 14.0
private let kInnerRingDiameter = 2.0 * kInnerRingRadius
private let kInnerRingLineWidth: CGFloat = 2.0
private let kOuterRingRadius: CGFloat = 24.0
private let kOuterRingDiameter = 2.0 * kOuterRingRadius
private let kOuterRingLineWidth: CGFloat = 4.0
private let kOuterRingStrokeAlpha: CGFloat = 0.6
private let kOuterRingFillAlpha: CGFloat = 0.12
private let kRippleRingFinalScale: CGFloat = 2.0
private let kRippleRingFinalLineWidth: CGFloat = 2.0
private let kRippleRingFadeInDuration: CFTimeInterval = 0.333
private let kRippleRingExpandDuration: CFTimeInterval = 0.833
private let kRippleRingFadeOutBeginTime: CFTimeInterval = 0.333
private let kRippleRingFadeOutDuration: CFTimeInterval = 0.5
private let kHibernationDuration: CFTimeInterval = 1.167
private let kOpacityKeyPath = "opacity"
private let kPathKeyPath = "path"
private let kPositionKeyPath = "position"
private let kLineWidthKeyPath = "lineWidth"

class CameraReticle: UIView {
  //* Starts animating the reticle. Does nothing if the reticle is already animating.
  func startAnimating() {
    if isAnimating {
      return
    }

    isAnimating = true
    fadeInRippleRing()
  }

  //* Stops animating the reticle. Does nothing if the reticle is not animating.
  func stopAnimating() {
    if !isAnimating {
      return
    }
    isAnimating = false
    hibernate()
  }

  //* Whether the reticle is currently animating.
  private var isAnimating = false
  //* The layer hosting the fixed inner ring.
  private var innerRingLayer: CAShapeLayer?
  //* The layer hosting the fixed outer ring.
  private var outerRingLayer: CAShapeLayer?
  //* The layer hosting the animating ripple ring.
  private var rippleRingLayer: CAShapeLayer?

  // MARK: - Public
  override init(frame: CGRect) {
    super.init(frame: frame)
    outerRingLayer = CAShapeLayer()
    outerRingLayer?.opacity = Float(kOuterRingStrokeAlpha)
    if let outerRingLayer = outerRingLayer {
      createRing(in: CGRect(x: 0, y: 0, width: kOuterRingDiameter, height: kOuterRingDiameter),
                 layer: outerRingLayer, lineWidth: kOuterRingLineWidth, stroke: UIColor.white,
                 fill: UIColor.black.withAlphaComponent(kOuterRingFillAlpha))
    }
    if let outerRingLayer = outerRingLayer {
      layer.addSublayer(outerRingLayer)
    }

    rippleRingLayer = CAShapeLayer()
    rippleRingLayer?.opacity = 0
    if let rippleRingLayer = rippleRingLayer {
      createRing(in: CGRect(x: 0, y: 0, width: kOuterRingDiameter, height: kOuterRingDiameter),
                 layer: rippleRingLayer, lineWidth: kOuterRingLineWidth, stroke: UIColor.white, fill: UIColor.clear)
    }
    if let rippleRingLayer = rippleRingLayer {
      layer.addSublayer(rippleRingLayer)
    }

    innerRingLayer = CAShapeLayer()
    if let innerRingLayer = innerRingLayer {
      createRing(in: CGRect(x: 0, y: 0, width: kInnerRingDiameter, height: kInnerRingDiameter),
                 layer: innerRingLayer, lineWidth: kInnerRingLineWidth, stroke: UIColor.white, fill: UIColor.clear)
    }
    if let innerRingLayer = innerRingLayer {
      layer.addSublayer(innerRingLayer)
    }
  }

  // MARK: - UIView(UIViewHierarchy)
  override func layoutSubviews() {
    super.layoutSubviews()
    let centerX = self.centerX()
    let centerY = self.centerY()
    let outerRingRect = CGRect(x: centerX - kOuterRingRadius, y: centerY - kOuterRingRadius,
                               width: kOuterRingDiameter, height: kOuterRingDiameter)
    outerRingLayer?.frame = outerRingRect
    outerRingLayer?.bounds = outerRingRect
    outerRingLayer?.position = outerRingRect.origin

    rippleRingLayer?.frame = outerRingRect
    rippleRingLayer?.bounds = outerRingRect
    rippleRingLayer?.position = outerRingRect.origin

    let innerRingRect = CGRect(x: centerX - kInnerRingRadius, y: centerY - kInnerRingRadius,
                               width: kInnerRingDiameter, height: kInnerRingDiameter)
    innerRingLayer?.frame = innerRingRect
    innerRingLayer?.bounds = innerRingRect
    innerRingLayer?.position = innerRingRect.origin
  }

  override var isHidden: Bool {
    get {
      return super.isHidden
    }
    set(hidden) {
      super.isHidden = hidden
      if hidden {
        stopAnimating()
      } else {
        startAnimating()
      }
    }
  }

  override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)
    // If the reticle is removed from the window, we should stop animating to avoid chewing up CPU.
    if newWindow == nil {
      stopAnimating()
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
    layer.strokeStart = 0.0
    layer.strokeEnd = 1.0
    layer.strokeColor = strokeColor.cgColor
    layer.fillColor = fillColor.cgColor
  }

  //* Fades in the ripple ring with a linear timing function.
  func fadeInRippleRing() {
    CATransaction.begin()
    weak var weakSelf = self
    CATransaction.setCompletionBlock({
      let strongSelf = weakSelf
      strongSelf?.expandRippleRing()
    })
    let fadeIn = CABasicAnimation()
    fadeIn.keyPath = kOpacityKeyPath
    fadeIn.fromValue = NSNumber(value: 0.0)
    fadeIn.toValue = NSNumber(value: Float(kOuterRingStrokeAlpha))
    fadeIn.duration = kRippleRingFadeInDuration
    fadeIn.timingFunction = CAMediaTimingFunction(name: .linear)
    fadeIn.fillMode = .forwards
    fadeIn.isRemovedOnCompletion = false
    rippleRingLayer?.add(fadeIn, forKey: nil)
    CATransaction.commit()
  }

  //* Expands and fades out the ripple ring while thinning the line width.
  func expandRippleRing() {
    CATransaction.begin()
    weak var weakSelf = self
    CATransaction.setCompletionBlock({
      let strongSelf = weakSelf
      strongSelf?.hibernate()
    })

    let finalRect = CGRect(x: 0, y: 0, width: kRippleRingFinalScale * kOuterRingDiameter,
                           height: kRippleRingFinalScale * kOuterRingDiameter)
    let finalPath = UIBezierPath(ovalIn: finalRect).cgPath
    let scale = CABasicAnimation()
    scale.keyPath = kPathKeyPath
    scale.fromValue = rippleRingLayer?.path
    scale.toValue = finalPath

    let recenter = CABasicAnimation()
    recenter.keyPath = kPositionKeyPath
    recenter.fromValue = NSValue(cgPoint: rippleRingLayer?.position ?? CGPoint.zero)
    recenter.toValue = NSValue(cgPoint: CGPoint(x: centerX() - kOuterRingDiameter, y: centerY() - kOuterRingDiameter))

    let thin = CABasicAnimation()
    thin.keyPath = kLineWidthKeyPath
    thin.fromValue = NSNumber(value: Float(kOuterRingLineWidth))
    thin.toValue = NSNumber(value: Float(kRippleRingFinalLineWidth))

    let fadeOut = CABasicAnimation()
    fadeOut.keyPath = kOpacityKeyPath
    fadeOut.fromValue = NSNumber(value: Float(kOuterRingStrokeAlpha))
    fadeOut.toValue = NSNumber(value: 0.0)
    fadeOut.beginTime = kRippleRingFadeOutBeginTime
    fadeOut.duration = kRippleRingFadeOutDuration
    fadeOut.timingFunction = CAMediaTimingFunction(name: .linear)
    fadeOut.fillMode = .forwards

    let expand = CAAnimationGroup()
    expand.animations = [scale, recenter, thin, fadeOut]
    expand.duration = kRippleRingExpandDuration
    // Animation begins and ends with easing.
    expand.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
    expand.fillMode = .forwards
    expand.isRemovedOnCompletion = false
    rippleRingLayer?.add(expand, forKey: nil)
    CATransaction.commit()
  }

  //* Hibernates and prepares for the next cycle of animation, or stops the animation upon request.
  func hibernate() {
    if !isAnimating {
      rippleRingLayer?.removeAllAnimations()
      return
    }
    CATransaction.begin()
    weak var weakSelf = self
    CATransaction.setCompletionBlock({
      let strongSelf = weakSelf
      strongSelf?.fadeInRippleRing()
    })

    let outerRect = CGRect(x: 0, y: 0, width: kOuterRingDiameter, height: kOuterRingDiameter)
    let path = UIBezierPath(ovalIn: outerRect).cgPath
    let scale = CABasicAnimation()
    scale.keyPath = kPathKeyPath
    scale.fromValue = rippleRingLayer?.path
    scale.toValue = path

    let thicken = CABasicAnimation()
    thicken.keyPath = kLineWidthKeyPath
    thicken.fromValue = NSNumber(value: Float(kRippleRingFinalLineWidth))
    thicken.toValue = NSNumber(value: Float(kOuterRingLineWidth))

    let recenter = CABasicAnimation()
    recenter.keyPath = kPositionKeyPath
    recenter.fromValue = NSValue(cgPoint: rippleRingLayer?.position ?? CGPoint.zero)
    recenter.toValue = NSValue(cgPoint: CGPoint(x: centerX() - kOuterRingRadius, y: centerY() - kOuterRingRadius))

    let hibernate = CAAnimationGroup()
    hibernate.animations = [scale, recenter, thicken]
    hibernate.duration = kHibernationDuration
    hibernate.timingFunction = CAMediaTimingFunction(name: .linear)
    hibernate.fillMode = .forwards
    hibernate.isRemovedOnCompletion = false
    rippleRingLayer?.add(hibernate, forKey: nil)

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

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}

/**
 * The reticle consists of 3 rings, an inner ring and an outer ring of fixed size, and an animating
 * ripple ring that can change in opacity, line width, and radius. They all live in their own
 * layers.
 */
