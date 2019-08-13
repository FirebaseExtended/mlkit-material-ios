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
import PINRemoteImage

//* Layout values.
private let kHorizontalPadding: CGFloat = 16.0
private let kVerticalPadding: CGFloat = 16.0
private let kVerticalPaddingSmall: CGFloat = 6.0
private let kThumbnailSize: CGFloat = 80.0

//* Cell that shows `Product` details from a search result.
class ProductResultCell: MDCBaseCell {
  //* Thumbnail of the product.
  private(set) var thumbnailImage = UIImageView()
  //* Label showing the name of the product.
  private(set) var nameLabel = UILabel()
  //* Label showing the category of the product.
  private(set) var categoryLabel = UILabel()
  //* Label showing the item number of the product.
  private(set) var itemNumberLabel = UILabel()
  //* Label showing the price of the product.
  private(set) var priceLabel = UILabel()

  /**
   * Populates the content of the cell with a `Product` model.
   *
   * @param product The product info to populate the cell with.
   * @return YES if product is not nil, otherwise, NO.
   */
  func isCellPopulated(with product: Product?) -> Bool {
    guard let product = product else { return false }
    if let imageURL = product.imageURL, !imageURL.isEmpty {
      thumbnailImage.pin_setImage(from: URL(string: imageURL))
    }
    nameLabel.text = product.productName
    categoryLabel.text = product.productTypeName
    priceLabel.text = product.priceFullText
    itemNumberLabel.text = product.itemNo
    return true
  }

  // MARK: - Public
  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(thumbnailImage)

    nameLabel.numberOfLines = 0
    nameLabel.font = MDCBasicFontScheme().subtitle1
    addSubview(nameLabel)

    categoryLabel.numberOfLines = 0
    categoryLabel.font = MDCBasicFontScheme().body2
    categoryLabel.textColor = MDCPalette.grey.tint700
    addSubview(categoryLabel)


    priceLabel.numberOfLines = 0
    priceLabel.font = MDCBasicFontScheme().body1
    addSubview(priceLabel)

    itemNumberLabel.numberOfLines = 0
    itemNumberLabel.font = MDCBasicFontScheme().body1
    addSubview(itemNumberLabel)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - UICollectionReusableView
  override func prepareForReuse() {
    super.prepareForReuse()
    thumbnailImage.image = nil
    nameLabel.text = nil
    priceLabel.text = nil
    categoryLabel.text = nil
    itemNumberLabel.text = nil
  }

  // MARK: - UIView
  override func layoutSubviews() {
    super.layoutSubviews()
    let _ = layoutSubviews(forWidth: frame.size.width, shouldSetFrame: true)
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    let width = frame.size.width
    let height = layoutSubviews(forWidth: width, shouldSetFrame: false)
    return CGSize(width: width, height: height)
  }

  // MARK: - Private

  /**
   * Calculates the height that best fits the specified width for subviews.
   *
   * @param width The available width for the view.
   * @param shouldSetFrame Whether to set frames for subviews.
   *    If it is set to NO, this function will simply measure the space without affecting subviews,
   *    otherwise, subviews will be laid out accordingly.
   * @return The best height of the view that fits the width.
   */
  func layoutSubviews(forWidth width: CGFloat, shouldSetFrame: Bool) -> CGFloat {
    var contentWidth = width - 2 * kHorizontalPadding

    var currentHeight = kVerticalPadding
    var startX = kHorizontalPadding

    if shouldSetFrame {
      thumbnailImage.frame = CGRect(x: startX, y: currentHeight, width: kThumbnailSize, height: kThumbnailSize)
    }

    startX += kThumbnailSize + kHorizontalPadding

    contentWidth -= kThumbnailSize + kHorizontalPadding

    let nameLabelSize = nameLabel.sizeThatFits(CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude))
    if shouldSetFrame {
      nameLabel.frame = CGRect(x: startX, y: currentHeight, width: contentWidth, height: nameLabelSize.height)
    }
    currentHeight += nameLabelSize.height + kVerticalPaddingSmall

    let categoryLabelSize = categoryLabel.sizeThatFits(CGSize(width: contentWidth,
                                                               height: CGFloat.greatestFiniteMagnitude))
    if shouldSetFrame {
      categoryLabel.frame = CGRect(x: startX, y: currentHeight, width: contentWidth,
                                    height: categoryLabelSize.height)
    }

    currentHeight += categoryLabelSize.height + kVerticalPadding

    let priceLabelSize = priceLabel.sizeThatFits(CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude))
    if shouldSetFrame {
      priceLabel.frame = CGRect(x: width - kHorizontalPadding - priceLabelSize.width,
                                 y: currentHeight, width: priceLabelSize.width,
                                 height: priceLabelSize.height)
    }

    let maxItemNumberLabelWidth = contentWidth - priceLabelSize.width - kHorizontalPadding
    let itemNumberLabelSize = itemNumberLabel.sizeThatFits(CGSize(width: maxItemNumberLabelWidth,
                                                                  height: CGFloat.greatestFiniteMagnitude))
    if shouldSetFrame {
      itemNumberLabel.frame = CGRect(x: startX, y: currentHeight,
                                     width: maxItemNumberLabelWidth, height: itemNumberLabelSize.height)
    }

    currentHeight += max(itemNumberLabelSize.height, priceLabelSize.height) + kVerticalPadding

    return max(currentHeight, kThumbnailSize + 2 * kVerticalPadding)
  }
}
