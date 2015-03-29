`#!/usr/bin/env node
`

fs = require 'fs-extra'
path = require 'path'

argv = require('minimist')(process.argv.slice(2))
colors = require 'colors'

info = require '../package.json'

doc = """
      #{ colors.bold('AssetPress ' + info.version) }
      High quality asset resizer for iOS and Android and powerful workflow tool.
      For more information see the README.

      #{ colors.bold('Usage and Common Options') }
      Usage: assetpress [options] input
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
      Input can be either a source directory or a .assetpress.json workflow file.
      For more information about Workflows and configuration files see README.
      Workflow accepts --clean and --verbose flags.

      #{ colors.bold('iOS Features and Options') }
      - Resizing from higher resolutions to lower (@4x recommended)
      - Xcassets folder generator, including AppIcon, LaunchImage and nested groups.
      For detailed documentation about these features see the README.
        -x, --xcassets  Generate .xcassets folder instead of a simple directory.
            --min       Smallest generated size for universal assets. Default: 1x.
            --max       Largest generated size for universal assets. Default: 3x.
            --min-phone Smallest generated size for iPhone assets. Default: 2x.
            --max-phone Largest generated size for iPhone assets. Default: 3x.
            --min-pad   Smallest generated size for iPad assets. Default: 1x.
            --max-pad   Largest generated size for iPad assets. Default: 2x.

      #{ colors.bold('Android Features and Options') }
      - Resizing from higher resolutions to lower (xxxhdpi initial size required)
      - 9-patches resizing with flexible initial patch thickness.
      - NoDPI support.

      AssetPress works either in iOS or Android mode, iOS being the default.
      Activate Android mode with -a or --android.
      Keep in mind that xxxhdpi (4x) initial resolution is required.
      AssetPress will skip files that are not sized in multiples of 4.
      For detailed documentation about these features see the README.
            --ldpi      Enable LDPI size generation.
            --xxxhdpi   Enable XXHDPI size generation. Despite being the source of
                        all other sizes, by default XXXHDPI size is not generated.

      """
return process.stdout.write(doc) if argv.help or argv.h

return process.stdout.write "AssetPress version #{ info.version }\n" if argv.version

console.log argv

require('./assetpress')
  inputDirectory: if argv._.length then argv._[0] else if argv.input then argv.input else undefined
  outputDirectory: argv.output or argv.o
  screensDirectory: argv.screens or argv.s
  noResize: !argv.resize
  verbose: argv.verbose or argv.v
  clean: argv.clean or argv.c
  os: if (argv.ios or argv.i) then 'ios' else if (argv.android or argv.a) then 'android' else undefined
  iosMinimum: argv.min
  iosMaximum: argv.max
  iosMinimumPhone: argv['min-phone']
  iosMaximumPhone: argv['max-phone']
  iosMinimumPad: argv['min-pad']
  iosMaximumPad: argv['max-pad']
  iosXcassets: argv.xcassets or argv.x
  androidLdpi: argv.ldpi
  androidXxxhdpi: argv.xxxhdpi
  gitMessage: argv.message or argv.m
