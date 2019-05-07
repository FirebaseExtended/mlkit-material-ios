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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Model for a product search results. */
@interface FIRProduct : NSObject

@property(nonatomic, copy, nullable) NSString *productName;
@property(nonatomic, nullable) NSNumber *score;
@property(nonatomic, copy, nullable) NSString *itemNumber;
@property(nonatomic, copy, nullable) NSString *imageURL;
@property(nonatomic, copy, nullable) NSString *priceFullText;
@property(nonatomic, copy, nullable) NSString *productTypeName;

/**
 * Generates a list of products from given search response.
 *
 * @param response The search response.
 * @return Generated list of products.
 */
+ (nullable NSArray<FIRProduct *> *)productsFromResponse:(nullable NSData *)response;

@end

NS_ASSUME_NONNULL_END
