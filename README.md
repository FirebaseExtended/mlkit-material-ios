# ML Kit Showcase App with Material Design

This app demonstrates how to build an end-to-end user experience with [Google ML Kit APIs](https://developers.google.com/ml-kit) and following the new [Material for ML design guidelines](https://material.io/collections/machine-learning/).

The goal is to make it as easy as possible to integrate ML Kit into your app with an experience that has been user tested:

* Visual search using the Object Detection & Tracking API - a complete workflow from object detection to product search in live camera.

![live_odt](screenshots/live_odt.gif)



## Steps to run the app

1. Clone this repo locally
  ```
  git clone https://github.com/firebase/mlkit-material-ios
  ```
2. Find a `Podfile` in the folder and install all the dependency pods by running the following command:
  ```
  cd mlkit-material-ios
  cd ShowcaseApp
  pod cache clean --all
  pod install --repo-update
  ```
3. Open the generated `ShowcaseApp.xcworkspace` file.
4. [Create a Firebase project in the Firebase console](https://firebase.google.com/docs/ios/setup),if you don't already have one.
5. Add a new iOS app into your Firebase project with a bundle ID like ***com.google.firebase.ml.md***.
6. Download `GoogleService-Info.plist` from the newly added app and add it to the
  ShowcaseApp project in Xcode. Remember to check `Copy items if needed` and
  select `Create folder references`.
7. Select the project in Xcode and uncheck `Automatically manage signing` option in
  `General` tab, and choose your own provisioning file.
8. Build and run it on a physical device (the simulator isn't recommended, as the app needs to use the camera on the device).

## How to use the app

This app demonstrates live product search using the camera:
* Open the app and point the camera at an object of interest. The app draws a bounding box around the object it detects.
* Hold still for a while to confirm on the same object. The app will trigger a product search to the server, and bring up the result on response.

**Note**: the visual search functionality is mocked up, since no real search backend has set up for this repository, but it should be easy to hook up with your own search service (e.g. [Product Search](https://cloud.google.com/vision/product-search/docs)) by only replacing return value of `APIKey`, `productSearchURL` and `acceptType` in `Models/FIRProductSearchRequest.m`.

## License
© Google, 2019. Licensed under an [Apache-2](./LICENSE) license.
