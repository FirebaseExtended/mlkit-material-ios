/* Copyright 2019 Google LLC
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

// Use the following imports for CocoaPods:
@import MaterialComponents;

// Use the following imports for google3:
//#import
//"third_party/objective_c/material_components_ios/components/Collections/src/MaterialCollections.h"

NS_ASSUME_NONNULL_BEGIN

@class FIRProduct;
@class FIRProductListHeaderView;
@class MDCFlexibleHeaderViewController;

/** View controller showing a list of products. */
@interface FIRProductListViewController : UICollectionViewController

/**
 * Header of the list, it stays on top of the screen when it expands to the whole screen and
 * contents will be scrolled underneath it.
 */
@property(nonatomic) MDCFlexibleHeaderViewController *headerViewController;

/** Header view for this panel view. */
@property(nonatomic) FIRProductListHeaderView *headerView;

/**
 * Initializes and returns a `ProductListViewController` object using the provided product list.
 *
 * @param products List of the products that serves as the model to this view.
 * @return An instance of the `ProductListViewController`.
 */
- (instancetype)initWithProducts:(NSArray<FIRProduct *> *)products;

/** Calculates and updates minmum and maximum height for header view. */
- (void)updateMinMaxHeightForHeaderView;

@end

NS_ASSUME_NONNULL_END
