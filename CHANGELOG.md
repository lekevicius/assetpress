# Changelog

## 2.2.0

* New command line flag --git-no-push and option gitNoPush. Will not push created git commit

## 2.1.0

* Allows passing workflow as inline object
* Fixes Rimraf bug

## 2.0

* **AssetPress Workflow.** AssetPress can now read .assetpress.json files and perform actions based on configuration. See project page for documentation about config files and workflow capabilities.
* **AssetPress Splitter**. A small sub-tool that can split screens (named like "1.0 Home Screen") and images into different folders. Very useful when working with Sketch.
* **Sketch as input**. Instead of passing a directory of exported images, now you can just pass .sketch file itself, and AssetPress will run proper `sketchtool` commands and resize everything.

## 1.1.1

* Fixes a bug with LaunchImage generator.

## 1.1.0

* iOS supports multiple AppIcons. Addition icons must be named `AppIcon<MODIFIER>`, such as AppIconTestflight@2x.png

## 1.0

* Initial release.
* Android supports resizing from xxxhdpi to lower resolutions, 9-patch resizing, no-dpi.
* iOS supports resizing from any resolution to any lower, includes Xcassets folder generator.
