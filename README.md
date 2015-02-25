<img src="https://cloud.githubusercontent.com/assets/218656/5440465/7d7e487e-8491-11e4-9de3-6e535d8589eb.png" width="112">

# AssetPress

Version 1.1.0

AssetPress is a high quality asset resizer for iOS and Android. It fits in the gap between designer drawing the design, and developer getting resources all nicely sliced and resized in every needed resolution. AssetPress is smart and powerful:

* **High quality resizing.** A lot of care went into finding the best resizing algorithm that preserves sharp edges and smooth curves.
* **Resizing iOS assets** from higher resolutions to lower. Starting @4x resolution is recommended (more on that below).
* **Xcassets folder generator**, including AppIcon, LaunchImage and nested groups. You can go from design source file (PSD or Sketch) to .xcassets folder in one step, and just replace existing Images.xcassets with a new one. Even supports all Apple Watch icons and launch images!
* **Smart resolution resizing.** No 1x files for iPhone, no 3x files for iPad - unless you choose otherwise.
* **Resizing Android assets** to every resolution - mdpi, hdpi, xhdpi, xxhdpi. Handles no-dpi correctly, and can even resize to ldpi and xxxhdpi if you choose.
* **The best Android 9-patch resizer.** Very flexible and produces 9-patch images in every resolution.

## AssetPress Workflow

Although AssetPress is very flexible, I recommend a very specific workflow that allows simple and fast design process, happiest developers and highest quality result. In short: design in 1x resolution, export in 4x, then pass these 4x sources through AssetPress. Here's why and how:

* **Designing in 1x** is easy for designers and great for developers.
    * Designers can more easily refer to UI guidelines that usually describe dimensions in  points for iOS and dp's for Android.
    * Developers can open original designs and check the dimesions and sizes without having to convert from 2x or 3x sizes.
    * This works especially well when working in [Sketch](http://bohemiancoding.com/sketch/), but Photoshop Generator also allows such workflow.
* **Exporting in 4x** allows for perfect scaling to 2x and 1x and close-to-perfect to 3x. Although it would be possible to export 3x seperately for perfect result, in practice it is impossible to notice scaling imperfections on these super high resolution screens. 1.5x scaling (Android's hdpi) is not perfect, and cannot be. The only way to get perfect result with hdpi is to re-draw everything manually, no tool could go from 1x or 2x to 1.5x keeping high quality.
    * In Sketch, exporting 4x is very simple. Just create a new slice or turn a layer into exportable layer, and set scaling to "4x". On iOS also set the suffix to "@4x". On Android keep the suffix empty.
    * In Photohop you need to use Generator naming and enable Generator support for that file. For iOS call the layer "...". For Android, call it "...".

Exporting in 4x is optional for iOS - AssetPress can take 3x images and scale them down to 2x and 1x. However, scaling from 3x to 2x involve 0.6666 scaling factor, and that prohibits high quality results. Because of that I recommend exporting "@4x" starting images, for example `asset@4x.png`. It is possible, however, to generate all  final scale resources (1x, 2x, 3x) directly -- either from Sketch or Photoshop -- and just use AssetPress as Xcassets folder generator. AssetPress will not touch any prerendered assets.

For Android, however, exporting in 4x is **required**. Android does not have scale-indicating naming convention, like iOS has with "@4x". Instead, you should export all images in xxxhdpi and name them without any suffix, for example, `asset.png`.

## Installation

AssetPress has only one dependency - ImageMagick. You can install ImageMagic with brew:

    brew install imagemagick

Then install AssetPress globally from npm:

    npm install -g assetpress

Currently AssetPress has only been tested on a Mac. I would like it to support Windows, and will gladly accept pull requests that improve the compatibility.

## Usage and Common Options

Usage: `assetpress [options] input_directory_name`

For example, if you are in a folder with "sources" folder, full of Android 4x resources, run `assetpress --android sources`. It will create a "res" folder in the same folder "sources" folder exists. As you can see from the example, `input_directory_name` is not a path, but just a name, relative to current directory. This might change.

    -i, --ios       iOS mode. Default, flag is not necessary.
    -a, --android   Android mode.
        --cwd       Overwrite current working directory.
                    Input and Output paths are relative to it.
    -o, --output    Output directory name.
    -c, --clean     Clean output directory before resizing.
    -v, --verbose   Verbose output.

## iOS Features and Options



iOS mode is default.

    -x, --xcassets  Generate .xcassets folder instead of simple resizing.
        --min       Smallest generated size for universal assets. Default: 1x.
        --max       Largest generated size for universal assets. Default: 3x.
        --min-phone Smallest generated size for iPhone assets. Default: 2x.
        --max-phone Largest generated size for iPhone assets. Default: 3x.
        --min-pad   Smallest generated size for iPad assets. Default: 1x.
        --max-pad   Largest generated size for iPad assets. Default: 2x.

## Android Features and Options

AssetPress works either in iOS or Android mode, iOS being the default.
Activate Android mode with -a or --android.
Keep in mind that xxxhdpi initial resolution is required.
AssetPress will skip files that are not sized in multiples of 4.

        --ldpi      Enable LDPI size generation.
        --xxxhdpi   Enable XXHDPI size generation Despite being the source of
                    all other sizes, by default XXXHDPI size is not generated.

## AssetPress as a Library

You can use AssetPress not only from command line, but also as a library. Example below shows all options with their default values. Call to assetpress is synchronous - this is another place how the tool can be improved.

    var assetpress = require('assetpress');
    assetpress({
        cwd: process.cwd()
        inputDirectoryName: 'source'
        outputDirectoryName: false
        verbose: false
        clean: false
        os: 'ios'
        androidLdpi: false
        androidXxxhdpi: false
        iosMinimumUniversal: 1
        iosMaximumUniversal: 3
        iosMinimumPhone: 2
        iosMaximumPhone: 3
        iosMinimumPad: 1
        iosMaximumPad: 2
        iosXcassets: false
    });

## Changelog

### 1.1.0

iOS supports multiple AppIcons. Addition icons must be named `AppIcon<MODIFIER>`, such as AppIconTestflight@2x.png

### 1.0

Initial release. Android supports resizing from xxxhdpi to lower resolutions, 9-patch resizing, no-dpi. iOS supports resizing from any resolution to any lower, includes Xcassets folder generator.

## Contributing

As mentioned, AssetPress currently has only been tested on a Mac. I would like it to support Windows, and will gladly accept pull requests that improve the compatibility.

All the code is written in CoffeeScript in src directory. I like CoffeeScript.

There are no tests. That's no good. But I also have no idea how to automate testing of what actually matters - quality of generated images.

## Authors

AssetPress is developed by [Jonas Lekevicius](http://lekevicius.com). It began as an internal tool for [Lemon Labs](http://lemonlabs.co), and we are now using it for all apps at [Wahanda](https://www.wahanda.com).

## License

MIT
