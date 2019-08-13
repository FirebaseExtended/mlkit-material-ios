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

private let kProductCellReuseIdentifier = "ProductCell"

//* View controller showing a list of products.
class ProductListViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
  /**
   * Header of the list, it stays on top of the screen when it expands to the whole screen and
   * contents will be scrolled underneath it.
   */
  var headerViewController = MDCFlexibleHeaderViewController()
  //* Header view for this panel view.
  var headerView = ProductListHeaderView()

  //* Cell that is used to calculate the height of each row.
  private var measureCell = ProductResultCell()
  //* Data model for this view. Content of the view is generated from its value.
  private var products = [Product]()

  /**
   * Initializes and returns a `ProductListViewController` object using the provided product list.
   *
   * @param products List of the products that serves as the model to this view.
   * @return An instance of the `ProductListViewController`.
   */
  init(products: [Product]) {
    let layout = UICollectionViewFlowLayout()
    super.init(collectionViewLayout: layout)
    self.products = products
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  //* Calculates and updates minmum and maximum height for header view.
  func updateMinMaxHeightForHeaderView() {
    let flexibleHeaderView = headerViewController.headerView
    flexibleHeaderView.maximumHeight = headerView.maxHeaderHeight(forWidth: view.bounds.size.width)
    flexibleHeaderView.minimumHeight = headerView.minHeaderHeight(forWidth: view.bounds.size.width)
  }

  // MARK: - Public

  // MARK: - UIViewController
  override func viewDidLoad() {
    super.viewDidLoad()

    collectionView.backgroundColor = UIColor.white

    // Register cell classes
    collectionView.register(ProductResultCell.self, forCellWithReuseIdentifier: kProductCellReuseIdentifier)

    addFlexibleHeader()
  }

  // MARK: - UICollectionViewDataSource
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return products.count
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kProductCellReuseIdentifier,
                                                  for: indexPath) as? ProductResultCell
    _ = cell?.isCellPopulated(with: products[indexPath.row])
    cell?.setNeedsLayout()
    return cell!
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    _ = measureCell.isCellPopulated(with: products[indexPath.row])
    let contentWidth = view.frame.size.width - self.collectionView.contentInset.left
      - self.collectionView.contentInset.right
    return CGSize(width: contentWidth,
                  height: measureCell.sizeThatFits(CGSize(width: contentWidth,
                                                           height: CGFloat.greatestFiniteMagnitude)).height)
  }

  // MARK: - UIScrollViewDelegate
  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView == headerViewController.headerView.trackingScrollView {
      headerViewController.headerView.trackingScrollDidScroll()
    }
  }

  override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    if scrollView == headerViewController.headerView.trackingScrollView {
      headerViewController.headerView.trackingScrollDidEndDecelerating()
    }
  }

  override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if scrollView == headerViewController.headerView.trackingScrollView {
      headerViewController.headerView.trackingScrollDidEndDraggingWillDecelerate(decelerate)
    }
  }

  override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    if scrollView == headerViewController.headerView.trackingScrollView {
      headerViewController.headerView.trackingScrollWillEndDragging(withVelocity: velocity,
                                                                    targetContentOffset: targetContentOffset)
    }
  }

  // MARK: - Private
  func addFlexibleHeader() {
    let headerText = String(format: "%ld search results", products.count)
    headerView.resultLabel?.text = headerText
    updateMinMaxHeightForHeaderView()

    headerViewController.willMove(toParent: self)
    addChild(headerViewController)

    headerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    let flexibleHeaderView = headerViewController.headerView
    flexibleHeaderView.canOverExtend = false
    flexibleHeaderView.trackingScrollView = collectionView

    flexibleHeaderView.addSubview(headerView)

    view.addSubview(flexibleHeaderView)


    headerView.frame = flexibleHeaderView.bounds
    flexibleHeaderView.frame = view.bounds

    headerViewController.didMove(toParent: self)
  }
}
