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

#import "AppDelegate.h"

#import "FIRVideoCamViewController.h"

@import FirebaseCore;

NS_ASSUME_NONNULL_BEGIN

@implementation AppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions {
  [FIRApp configure];

  FIRVideoCamViewController *videoCamViewController = [[FIRVideoCamViewController alloc] init];

  UIApplication.sharedApplication.idleTimerDisabled = YES;

  self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
  self.window.backgroundColor = UIColor.whiteColor;
  self.window.rootViewController = videoCamViewController;
  [self.window makeKeyAndVisible];
  return YES;
}

@end

NS_ASSUME_NONNULL_END
