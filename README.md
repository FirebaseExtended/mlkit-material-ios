# ML Kit Showcase Apps with Material Design

These apps demonstrate how to build an end-to-end user experience with [Google ML Kit APIs](https://developers.google.com/ml-kit) and following the new [Material for ML design guidelines](https://material.io/collections/machine-learning/).

The goal is to make it as easy as possible to integrate ML Kit into your app with an experience that has been user tested.

## Apps

You can open each of the following apps as an Xcode project, and run
them on a mobile device or a simulator. Simply install the pods and open
the .xcworkspace file to see the project in Xcode.

```
$ pod install --repo-update
$ open your-project.xcworkspace
```
When doing so you need to add each sample app you wish to try to a Firebase
project on the [Firebase console](https://console.firebase.google.com).
You can add multiple sample apps to the same Firebase project.
There's no need to create separate projects for each app.

To add a sample app to a Firebase project, use the bundleID from the Xcode project.
Download the generated `GoogleService-Info.plist` file, and copy it to the root
directory of the sample you wish to run.

- [Visual search using the Object Detection & Tracking API](ShowcaseApp/README.md)- a complete workflow from object detection to product search in live camera.

![live_odt](screenshots/live_odt.gif)

## How to make contributions?
Please read and follow the steps in the [CONTRIBUTING.md](CONTRIBUTING.md)

## License
© Google, 2019. Licensed under an [Apache-2](./LICENSE) license.
