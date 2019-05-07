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

#import "FIRProductListViewController.h"

#import "FIRProductListHeaderView.h"
#import "FIRProductResultCell.h"

@import MaterialComponents;

NS_ASSUME_NONNULL_BEGIN

static NSString *const kProductCellReuseIdentifier = @"ProductCell";

@interface FIRProductListViewController ()

/** Cell that is used to calculate the height of each row. */
@property(nonatomic) FIRProductResultCell *measureCell;

/** Data model for this view. Content of the view is generated from its value. */
@property(nonatomic) NSArray<FIRProduct *> *products;

@end

@implementation FIRProductListViewController

#pragma mark - Public

- (instancetype)initWithProducts:(NSArray<FIRProduct *> *)products {
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  self = [super initWithCollectionViewLayout:layout];
  if (self != nil) {
    _products = [products copy];
    _measureCell = [[FIRProductResultCell alloc] init];
  }
  return self;
}

- (void)updateMinMaxHeightForHeaderView {
  MDCFlexibleHeaderView *flexibleHeaderView = self.headerViewController.headerView;
  flexibleHeaderView.maximumHeight =
      [self.headerView maxHeaderHeightForWidth:self.view.bounds.size.width];
  flexibleHeaderView.minimumHeight =
      [self.headerView minHeaderHeightForWidth:self.view.bounds.size.width];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.collectionView.backgroundColor = UIColor.whiteColor;

  // Register cell classes
  [self.collectionView registerClass:FIRProductResultCell.class
          forCellWithReuseIdentifier:kProductCellReuseIdentifier];

  [self addFlexibleHeader];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
  return self.products.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  FIRProductResultCell *cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:kProductCellReuseIdentifier
                                                forIndexPath:indexPath];
  [cell isCellPopulatedWithProduct:self.products[indexPath.row]];
  [cell setNeedsLayout];
  return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                    layout:(nonnull UICollectionViewLayout *)collectionViewLayout
    sizeForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
  [self.measureCell isCellPopulatedWithProduct:self.products[indexPath.row]];
  CGFloat contentWidth = self.view.frame.size.width - self.collectionView.contentInset.left -
                         self.collectionView.contentInset.right;
  return CGSizeMake(contentWidth,
                    [self.measureCell sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)].height);
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (scrollView == self.headerViewController.headerView.trackingScrollView) {
    [self.headerViewController.headerView trackingScrollViewDidScroll];
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  if (scrollView == self.headerViewController.headerView.trackingScrollView) {
    [self.headerViewController.headerView trackingScrollViewDidEndDecelerating];
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if (scrollView == self.headerViewController.headerView.trackingScrollView) {
    [self.headerViewController.headerView
        trackingScrollViewDidEndDraggingWillDecelerate:decelerate];
  }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {
  if (scrollView == self.headerViewController.headerView.trackingScrollView) {
    [self.headerViewController.headerView
        trackingScrollViewWillEndDraggingWithVelocity:velocity
                                  targetContentOffset:targetContentOffset];
  }
}

#pragma mark - Private

- (void)addFlexibleHeader {
  if (self.headerViewController == nil) {
    self.headerViewController = [[MDCFlexibleHeaderViewController alloc] init];
  }
  if (self.headerView == nil) {
    self.headerView = [[FIRProductListHeaderView alloc] init];
  }
  NSString *headerText = [NSString stringWithFormat:@"%ld search results", self.products.count];
  self.headerView.resultLabel.text = headerText;
  [self updateMinMaxHeightForHeaderView];

  [self.headerViewController willMoveToParentViewController:self];
  [self addChildViewController:self.headerViewController];

  self.headerView.autoresizingMask =
      (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

  MDCFlexibleHeaderView *flexibleHeaderView = self.headerViewController.headerView;
  flexibleHeaderView.canOverExtend = NO;
  flexibleHeaderView.trackingScrollView = self.collectionView;

  [flexibleHeaderView addSubview:self.headerView];
  [self.view addSubview:flexibleHeaderView];

  self.headerView.frame = flexibleHeaderView.bounds;
  flexibleHeaderView.frame = self.view.bounds;

  [self.headerViewController didMoveToParentViewController:self];
}

@end

NS_ASSUME_NONNULL_END
