<img src="https://cloud.githubusercontent.com/assets/218656/5440465/7d7e487e-8491-11e4-9de3-6e535d8589eb.png" width="112">

# AssetPress

AssetPress is a high quality asset resizer and a powerful design workflow tool. It works with iOS and Android assets and is meant to fit in the gap between designer drawing the design, and developer getting resources all nicely sliced and resized in every needed resolution. AssetPress is smart and powerful:

* **High quality resizing** - preserves sharp edges and smooth curves.
* **Resizing iOS assets** from higher resolutions to lower.
* **Xcassets folder generator**, including AppIcon, LaunchImage and nested groups. Even supports Apple Watch!
* **All the correct resolutions**, aware of differences between iPhone and iPad.
* **Resizing Android assets** to every resolution - mdpi, hdpi, xhdpi, xxhdpi (also ldpi and xxxhdpi if you choose)
* **The best Android 9-patch resizer** produces correct 9-patch images in every resolution.
* **AssetPress Workflow** automates all production tasks into one command.
* **Export Sketch files** and resize all resources quickly.
* **Separate screen previews** and asset images into different folders - for different purposes.
* **Allows moving final images into git,** create a commit with a message and push changes to developers.

It has been battle-tested with apps with over 300 different screens and 2000+ resources. Although AssetPress is extremely flexible and can be useful in almost any situation, I *recommend* a very specific workflow that allows simple and fast design process, happiest developers and highest quality result.

1. *(Optionally)* Use Sketch. It has many features and allows automation that is impossible with Photoshop.
2. Design in 1x resolution for happy developers and correct metrics.
3. Export both iOS and Android in 4x, then pass these 4x sources through AssetPress.
4. Name your screens (artboards) with numbers (such as "1.0 Home") to easily refer to them and allow advanced automation.

For more information about the tool, example design files, workflow configuration options and examples, **[visit the project homepage](http://lekevicius.com/projects/assetpress)**.

## Installation

AssetPress has only one dependency - ImageMagick. You can install ImageMagic with brew:

    brew install imagemagick

Then install AssetPress globally from npm:

    npm install -g assetpress

Currently AssetPress has only been tested on a Mac. I would like it to support Windows, and will gladly accept pull requests that improve the compatibility.

More detailed installation instructions (friendlier to a designer) are [at the project homepage](http://lekevicius.com/projects/assetpress).

## Usage and Common Options

Usage: `assetpress [options] input`

    -i, --ios       iOS mode. Default, flag is not necessary.
    -a, --android   Android mode.
        --input     Input directory. Flag not necessary, 
                    any free argument is considered input.
    -o, --output    Output directory. Default depends on OS mode.
    -s, --screens   Screens directory
        --no-resize Don't perform any image resizing. 
                    Use when you only want split screens and images.
    -c, --clean     Clean output directory before outputting.
    -v, --verbose   Verbose output.

Input can be either a source directory, Sketch file or a .assetpress.json workflow file. Workflow accepts --clean and --verbose flags, all other details are read from the workflow file. Details and examples for workflow file configuration are [at the project homepage](http://lekevicius.com/projects/assetpress).

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
        inputDirectory: 'source',
        outputDirectory: false,
        screensDirectory: false,
        noResize: false,
        verbose: false,
        clean: false,
        os: 'ios',
        androidLdpi: false,
        androidXxxhdpi: false,
        iosMinimum: 1,
        iosMaximum: 3,
        iosMinimumPhone: 2,
        iosMaximumPhone: 3,
        iosMinimumPad: 1,
        iosMaximumPad: 2,
        iosXcassets: false,
        gitMessage: false,
        complete: function () {}
    });

## Author

AssetPress is developed by [Jonas Lekevicius](http://lekevicius.com). It began as an internal tool for [Lemon Labs](http://lemonlabs.co), and we are now using it for all apps at [Wahanda](https://www.wahanda.com).
