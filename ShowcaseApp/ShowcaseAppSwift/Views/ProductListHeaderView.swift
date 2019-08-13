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

import MaterialComponents

//* Header view for product search results list view.

//* Layout constants.
private let kHorizontalPadding: CGFloat = 16
private let kVerticalPadding: CGFloat = 16

class ProductListHeaderView: UIView {
  //* Labels that shows search results number.
  var resultLabel: UILabel?

  //* Minimum header height for the given width.
  func minHeaderHeight(forWidth width: CGFloat) -> CGFloat {
    let labelSize = resultLabel?.sizeThatFits(CGSize(width: width - 2 * kHorizontalPadding,
                                                     height: CGFloat.greatestFiniteMagnitude))
    return 2 * kVerticalPadding + (labelSize?.height ?? 0.0)
  }

  //* Maximum header height for the given width.
  func maxHeaderHeight(forWidth width: CGFloat) -> CGFloat {
    let labelSize = resultLabel?.sizeThatFits(CGSize(width: width - 2 * kHorizontalPadding,
                                                     height: CGFloat.greatestFiniteMagnitude))
    return 2 * kVerticalPadding + (labelSize?.height ?? 0.0)
  }

  // MARK: - Public
  override init(frame: CGRect) {
    super.init(frame: frame)
    resultLabel = UILabel()
    resultLabel?.font = MDCBasicFontScheme().subtitle1
    resultLabel?.backgroundColor = UIColor.white
    if let resultLabel = resultLabel {
      addSubview(resultLabel)
    }

    backgroundColor = UIColor.white
  }

  // MARK: - UIView
  override func layoutSubviews() {
    super.layoutSubviews()
    var currentHeight = frame.size.height
    let contentWidth = frame.size.width - 2 * kHorizontalPadding
    let labelSize = resultLabel?.sizeThatFits(CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude))
    currentHeight -= kVerticalPadding + (labelSize?.height ?? 0.0)
    resultLabel?.frame = CGRect(x: kHorizontalPadding, y: currentHeight, width: contentWidth,
                                height: labelSize?.height ?? 0.0)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
