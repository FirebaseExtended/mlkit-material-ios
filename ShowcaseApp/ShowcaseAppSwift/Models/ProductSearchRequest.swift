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

//* Request sent for the product search.

// Key-value pairs in the product search request.
private let kJSONBodyImageContentKey = "content"
private let kJSONBodyRetailUnitKey = "RU"
private let kJSONBodyRetailUnitValue = "US"
private let kURLKey = "URL"
private let kHeaderAcceptTypeKey = "Accept"
private let kHeaderContentTypeKey = "Content-Type"
private let kHeaderContentTypeValue = "application/json"
private let kHeaderAPIKeyKey = "X-IVS-APIKey"
private let kHTTPMethodPost = "POST"
private let kKeyFileName = "key"
private let kKeyFileType = "plist"

func productSearchRequest(from image: UIImage) -> URLRequest? {
  guard let serverInfoFileName = Bundle.main.path(forResource: kKeyFileName, ofType: kKeyFileType),
    let serverInfo = NSDictionary(contentsOfFile: serverInfoFileName) as? [String: String]  else {
      return nil
  }
  var urlRequest = URLRequest.init(url: URL.init(string: serverInfo[kURLKey]!)!)
  urlRequest.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
  urlRequest.httpMethod = kHTTPMethodPost
  let encodedString = image.fir_base64EncodedString()
  let JSONDictionary = [kJSONBodyImageContentKey: encodedString,
                        kJSONBodyRetailUnitKey: kJSONBodyRetailUnitValue]

  do {
    let JSONData = try JSONSerialization.data(withJSONObject: JSONDictionary, options: [])
    urlRequest.httpBody = JSONData
  } catch let JSONError {
      print("Unable to generate JSONData from JSONDictionary: \(JSONError.localizedDescription)")
  }

  urlRequest.setValue(serverInfo[kHeaderAPIKeyKey], forHTTPHeaderField: kHeaderAPIKeyKey)
  urlRequest.setValue(kHeaderContentTypeValue, forHTTPHeaderField: kHeaderContentTypeKey)
  urlRequest.setValue(serverInfo[kHeaderAcceptTypeKey], forHTTPHeaderField: kHeaderAcceptTypeKey)
  return urlRequest
}
