# ML Kit Showcase App with Material Design

This app demonstrates how to build an end-to-end user experience with [Google ML Kit APIs](https://developers.google.com/ml-kit) that aligns with the new [Material for ML design guidelines](https://material.io/collections/machine-learning/).

The goal is to make it as easy as possible to integrate ML Kit into your app with an experience that has been user tested:

* Visual search using the Object Detection & Tracking API - a complete workflow from object detection to product search using a live camera.

![live_odt](../screenshots/live_odt.gif)



## Steps to run the app

1. Clone "showcase app" repo: `git clone https://github.com/firebase/mlkit-material-ios`.
2. Go to the `mlkit-material-ios/ShowcaseApp` directory, which contains the `Podfile`, and install the pod dependencies by running the following command:`pod install`.
3. Open the generated `ShowcaseApp.xcworkspace` file.
4. If you haven't already, [create a Firebase project in the Firebase console](https://firebase.google.com/docs/ios/setup), if you don't already have one.
5. Add a new iOS app into your Firebase project with a new bundle ID similar to ***com.myfirstshowcaseapp***.
6. Download the `GoogleService-Info.plist` from the newly added app and add it to the
  ShowcaseApp project in Xcode. Remember to check `Copy items if needed` and
  select `Create folder references`.
7. Select the project in the left navigtion panel of Xcode and uncheck `Automatically manage signing` option in
  the `General` tab, and choose your own provisioning file.
8. Build and run the app on a physical device (the simulator isn't recommended, as the app needs to use the camera on the device).

## How to use the app

This app demonstrates live product search using the camera:
* Open the app and point the camera at an object of interest. The app draws a bounding box around the object it detects.
* By focusing on the object, the app triggers a product search to the server and displays the relevant results in the UI.

**Note**: the search data is mocked, since a real search backend has not been set up for this repository. However, it should be easy to configure your own search service (e.g. [Product Search](https://cloud.google.com/vision/product-search/docs)) by replacing the return values for `APIKey`, `productSearchURL`, and `acceptType` in `Models/FIRProductSearchRequest.m`.

## License
© Google, 2019. Licensed under the [Apache-2](./LICENSE) license.
