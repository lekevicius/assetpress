<img src="https://cloud.githubusercontent.com/assets/218656/5440465/7d7e487e-8491-11e4-9de3-6e535d8589eb.png" width="112">

# AssetPress

Version 1.0.0
High quality asset resizer for iOS and Android.

## Usage and Common Options

Usage: `assetpress [options] input_directory_name`

      -i, --ios       iOS mode. Default, flag is not necessary.
      -a, --android   Android mode.
          --cwd       Overwrite current working directory.
                      Input and Output paths are relative to it.
      -o, --output    Output directory name.
      -c, --clean     Clean output directory before resizing.
      -v, --verbose   Verbose output.

## iOS Features and Options

* Resizing from higher resolutions to lower (@4x recommended)
* Xcassets folder generator, including AppIcon, LaunchImage and nested groups.

iOS mode is default.

      -x, --xcassets  Generate .xcassets folder instead of simple resizing.
          --min       Smallest generated size for universal assets. Default: 1x.
          --max       Largest generated size for universal assets. Default: 3x.
          --min-phone Smallest generated size for iPhone assets. Default: 2x.
          --max-phone Largest generated size for iPhone assets. Default: 3x.
          --min-pad   Smallest generated size for iPad assets. Default: 1x.
          --max-pad   Largest generated size for iPad assets. Default: 2x.

## Android Features and Options

* Resizing from higher resolutions to lower (xxxhdpi initial size required)
* 9-patches resizing with flexible initial patch thickness.
* NoDPI support.

AssetPress works either in iOS or Android mode, iOS being the default.
Activate Android mode with -a or --android.
Keep in mind that xxxhdpi initial resolution is required.
AssetPress will skip files that are not sized in multiples of 4.

          --ldpi      Enable LDPI size generation.
          --xxxhdpi   Enable XXHDPI size generation Despite being the source of.
                      all other sizes, by default XXXHDPI size is not generated.
