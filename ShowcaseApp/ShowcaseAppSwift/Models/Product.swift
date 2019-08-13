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

import Foundation

//* Model for a product search results.
// Key for wrapped data in product search response.
private let kSearchResponseKeyData = "data"
private let kSearchResponseKeySearchResults = "productSearchResults"
private let kSearchResponseKeyProducts = "products"
// Key for product properties in product search response.
private let kProductNameKey = "productName"
private let kProductScoreKey = "score"
private let kProductItemNumberKey = "itemNo"
private let kProductPriceTextKey = "priceFullText"
private let kProductImageURLKey = "imageUrl"
private let kProductTypeNameKey = "productTypeName"

struct SearchResponse: Codable {
  var data: String
  var productSearchResults: String
  var products: [Product]
}

struct Product: Codable {
  var productName: String?
  var score: Int?
  var itemNo: String?
  var imageURL: String?
  var priceFullText: String?
  var productTypeName: String?

  /**
   * Generates a list of products from given search response.
   *
   * @param response The search response.
   * @return Generated list of products.
   */
  static func products(fromResponse response: Data?) -> [Product]? {
    guard let response = response else {
      return nil
    }

    do {
      let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: response)
      return searchResponse.products
    } catch {
      print("Error in parsing a response: \(error.localizedDescription)")
    }
    return nil
  }

  var description: String {
    return "Product name: \(productName ?? ""), type: \(productTypeName ?? ""), price:\(priceFullText ?? ""), item Number: \(itemNo ?? "")"
  }
}
