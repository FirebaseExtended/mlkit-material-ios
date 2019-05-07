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

#import "FIRProduct.h"

// Key for wrapped data in product search response.
static NSString *const kSearchResponseKeyData = @"data";
static NSString *const kSearchResponseKeySearchResults = @"productSearchResults";
static NSString *const kSearchResponseKeyProducts = @"products";

// Key for product properties in product search response.
static NSString *const kProductNameKey = @"productName";
static NSString *const kProductScoreKey = @"score";
static NSString *const kProductItemNumberKey = @"itemNo";
static NSString *const kProductPriceTextKey = @"priceFullText";
static NSString *const kProductImageURLKey = @"imageUrl";
static NSString *const kProductTypeNameKey = @"productTypeName";

NS_ASSUME_NONNULL_BEGIN

@implementation FIRProduct

+ (nullable NSArray<FIRProduct *> *)productsFromResponse:(nullable NSData *)response {
  if (response == nil) {
    return nil;
  }
  NSError *JSONError;
  NSDictionary *responseJSONObject = [NSJSONSerialization JSONObjectWithData:response
                                                                     options:0
                                                                       error:&JSONError];
  if (JSONError != nil) {
    NSLog(@"Error in parsing a response: %@", JSONError);
    return nil;
  }

  NSData *responseData = [responseJSONObject valueForKey:kSearchResponseKeyData];
  if (responseData == nil || ![responseData isKindOfClass:[NSDictionary class]]) {
    return nil;
  }
  NSDictionary *responseDataDictionary = (NSDictionary *)responseData;

  NSData *productSearchResultsData =
      [responseDataDictionary valueForKey:kSearchResponseKeySearchResults];

  if (productSearchResultsData == nil ||
      ![productSearchResultsData isKindOfClass:[NSDictionary class]]) {
    return nil;
  }

  NSArray *productSearchResultsArray = (NSArray *)(
      [(NSDictionary *)productSearchResultsData valueForKey:kSearchResponseKeyProducts]);
  NSMutableArray *results = [NSMutableArray arrayWithCapacity:productSearchResultsArray.count];
  for (NSData *resultData in productSearchResultsArray) {
    [results addObject:[self productFromData:resultData]];
  }
  return results;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Product name: %@, type: %@, price:%@, item Number: %@",
                                    self.productName, self.productTypeName, self.priceFullText,
                                    self.itemNumber];
}

#pragma mark - Private

+ (nullable FIRProduct *)productFromData:(NSData *)data {
  if (data == nil || ![data isKindOfClass:NSDictionary.class]) {
    return nil;
  }
  FIRProduct *product = [[FIRProduct alloc] init];
  NSDictionary *dictionary = (NSDictionary *)data;
  product.productName = dictionary[kProductNameKey];
  product.score = dictionary[kProductScoreKey];
  product.itemNumber = dictionary[kProductItemNumberKey];
  product.priceFullText = dictionary[kProductPriceTextKey];
  product.imageURL = dictionary[kProductImageURLKey];
  product.productTypeName = dictionary[kProductTypeNameKey];
  return product;
}

@end

NS_ASSUME_NONNULL_END
