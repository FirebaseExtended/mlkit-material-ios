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

#import "FIRProductResultCell.h"

#import "FIRProduct.h"

// Use the following imports for CocoaPods:
@import MaterialComponents;
@import PINRemoteImage;

// Use the following imports for google3:
//#import
//"googlemac/iPhone/Shared/GoogleMaterial/components/FontScheme/src/GoogleMaterialFontScheme.h"
//#import "googlemac/iPhone/Shared/GoogleMaterial/components/Palettes/src/GoogleMaterialPalettes.h"

/** Layout values. */
static CGFloat const kHorizontalPadding = 16.0f;
static CGFloat const kVerticalPadding = 16.0f;
static CGFloat const kVerticalPaddingSmall = 6.0f;
static CGFloat const kThumbnailSize = 80.0f;

NS_ASSUME_NONNULL_BEGIN

@implementation FIRProductResultCell

#pragma mark - Public

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self != nil) {
    _thumbNailImage = [[UIImageView alloc] init];
    [self addSubview:_thumbNailImage];

    _nameLabel = [[UILabel alloc] init];
    _nameLabel.numberOfLines = 0;
    _nameLabel.font = [[MDCBasicFontScheme alloc] init].subtitle1;
    [self addSubview:_nameLabel];

    _categoryLabel = [[UILabel alloc] init];
    _categoryLabel.numberOfLines = 0;
    _categoryLabel.font = [[MDCBasicFontScheme alloc] init].body2;
    _categoryLabel.textColor = MDCPalette.greyPalette.tint700;
    [self addSubview:_categoryLabel];

    _priceLabel = [[UILabel alloc] init];
    _priceLabel.numberOfLines = 0;
    _priceLabel.font = [[MDCBasicFontScheme alloc] init].body1;
    [self addSubview:_priceLabel];

    _itemNumberLabel = [[UILabel alloc] init];
    _itemNumberLabel.numberOfLines = 0;
    _itemNumberLabel.font = [[MDCBasicFontScheme alloc] init].body1;
    [self addSubview:_itemNumberLabel];
  }
  return self;
}

- (BOOL)populateFromProductModel:(FIRProduct *)product {
  if (product == nil) {
    return NO;
  }

  [self.thumbNailImage pin_setImageFromURL:[NSURL URLWithString:product.imageURL]];
  self.nameLabel.text = product.productName;
  self.categoryLabel.text = product.productTypeName;
  self.priceLabel.text = product.priceFullText;
  self.itemNumberLabel.text = product.itemNumber;
  return YES;
}

#pragma mark - UICollectionReusableView

- (void)prepareForReuse {
  [super prepareForReuse];
  self.thumbNailImage.image = nil;
  self.nameLabel.text = @"";
  self.priceLabel.text = @"";
  self.categoryLabel.text = @"";
  self.itemNumberLabel.text = @"";
}

#pragma mark - UIView

- (void)layoutSubviews {
  [super layoutSubviews];
  [self layoutSubviewsForWidth:self.frame.size.width shouldSetFrame:YES];
}

- (CGSize)sizeThatFits:(CGSize)size {
  CGFloat width = self.frame.size.width;
  CGFloat height = [self layoutSubviewsForWidth:width shouldSetFrame:NO];
  return CGSizeMake(width, height);
}

#pragma mark - Private

/**
 * Calculates the height that best fits the specified width for subviews.
 *
 * @param width The available width for the view.
 * @param shouldSetFrame Whether to set frames for subviews.
 *    If it is set to NO, this function will simply measure the space without affecting subviews,
 *    otherwise, subviews will be laid out accordingly.
 * @return The best height of the view that fits the width.
 */
- (CGFloat)layoutSubviewsForWidth:(CGFloat)width shouldSetFrame:(BOOL)shouldSetFrame {
  CGFloat contentWidth = width - 2 * kHorizontalPadding;

  CGFloat currentHeight = kVerticalPadding;
  CGFloat startX = kHorizontalPadding;

  if (shouldSetFrame) {
    self.thumbNailImage.frame = CGRectMake(startX, currentHeight, kThumbnailSize, kThumbnailSize);
  }

  startX += kThumbnailSize + kHorizontalPadding;

  contentWidth -= kThumbnailSize + kHorizontalPadding;

  CGSize nameLabelSize = [self.nameLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
  if (shouldSetFrame) {
    self.nameLabel.frame = CGRectMake(startX, currentHeight, contentWidth, nameLabelSize.height);
  }
  currentHeight += nameLabelSize.height + kVerticalPaddingSmall;

  CGSize categoryLabelSize =
      [self.categoryLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
  if (shouldSetFrame) {
    self.categoryLabel.frame =
        CGRectMake(startX, currentHeight, contentWidth, categoryLabelSize.height);
  }

  currentHeight += categoryLabelSize.height + kVerticalPadding;

  CGSize priceLabelSize = [self.priceLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
  if (shouldSetFrame) {
    self.priceLabel.frame = CGRectMake(width - kHorizontalPadding - priceLabelSize.width,
                                       currentHeight, priceLabelSize.width, priceLabelSize.height);
  }

  CGFloat maxItemNumberLabelWidth = contentWidth - priceLabelSize.width - kHorizontalPadding;
  CGSize itemNumberLabelSize =
      [self.itemNumberLabel sizeThatFits:CGSizeMake(maxItemNumberLabelWidth, CGFLOAT_MAX)];
  if (shouldSetFrame) {
    self.itemNumberLabel.frame =
        CGRectMake(startX, currentHeight, maxItemNumberLabelWidth, itemNumberLabelSize.height);
  }

  currentHeight += MAX(itemNumberLabelSize.height, priceLabelSize.height) + kVerticalPadding;

  return MAX(currentHeight, kThumbnailSize + 2 * kVerticalPadding);
}

@end

NS_ASSUME_NONNULL_END
