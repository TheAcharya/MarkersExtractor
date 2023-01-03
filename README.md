# MarkersExtractor CLI

![MarkersExtractorCLI.gif](assets/MarkersExtractorCLI.gif)

Marker metadata extraction and conversion tool for Final Cut Pro.

## Core Features

- Accurately extract Markers from FCP's FCPXML/FCPXMLD to CSV (additional formats coming in future)
- Ability to batch extract and render stills or animated GIFs based on each marker's timecode
- Ability to batch burn-in labels of each marker's metadata onto the stills or animated GIFs

## Table of contents

- [Installation](#Installation)
  - [Pre-compiled Binary (Recommended)](#pre-compiled-binary-recommended)
  - [From Source](#from-source)
- [Usage](#usage)
- [Developer Library](#developer-library)
- [Credits](#Credits)
- [License](#License)
- [Reporting Bugs](#reporting-bugs)
- [Contributing](#contributing)

## Installation

### Pre-compiled Binary (Recommended)

Download the latest alpha release of the CLI universal binary [here](https://github.com/TheAcharya/MarkersExtractor/releases/download/0.2.0-alpha-20230101.1/markers-extractor-cli-0.2.0-alpha-20230101.1.zip).

### From Source

```shell
VERSION=0.1.0  # replace this with the version you need
git clone https://github.com/TheAcharya/MarkersExtractor.git
cd MarkersExtractor
git checkout "tags/$VERSION"
swift build -c release
```

Once the build has finished, the `markers-extractor-cli` executable will be located at `.build/release/`.

## Usage

### CLI v0.2.0-alpha-* (Development in Progress)

```shell
$ markers-extractor-cli --help
OVERVIEW: Tool to extract markers from Final Cut Pro FCPXML(D).

https://github.com/TheAcharya/MarkersExtractor

USAGE: markers-extractor-cli [<options>] <fcpxml-path> <output-dir>

ARGUMENTS:
  <fcpxml-path>           Input FCPXML file / FCPXMLD bundle.
  <output-dir>            Output directory.

OPTIONS:
  --export-format <airtable,notion>
                          Metadata export format. (default: notion)
  --enable-subframes      Enable output of timecode subframes.
  --image-format <png,jpg,gif>
                          Marker thumb image format. 'gif' is animated and
                          additional options can be specified with --gif-fps
                          and --gif-span. (default: png)
  --image-quality <0...100>
                          Image quality percent for JPG. (default: 100)
  --image-width <w>       Limit image width keeping aspect ratio.
  --image-height <h>      Limit image height keeping aspect ratio.
  --image-size-percent <1...100>
                          Limit image size to % keeping aspect ratio. (default
                          for GIF: 50)
  --gif-fps <0.1...60.0>  GIF frame rate. (default: 10.0)
  --gif-span <sec>        GIF capture span around marker. (default: 2.0)
  --id-naming-mode <projectTimecode,name,notes>
                          Marker naming mode. This affects Marker IDs and image
                          filenames. (default: projectTimecode)
  --label <id,name,type,checked,status,notes,position,clipName,clipDuration,videoRoles,audioRoles,eventName,projectName,libraryName,iconImage,imageFileName>
                          Label to overlay on thumb images. This argument can
                          be supplied more than once to apply multiple labels.
  --label-copyright <text>
                          Copyright label. Will be appended after other labels.
  --label-font <name>     Font for image labels. (default: Menlo-Regular)
  --label-font-size <pt>  Maximum font size for image labels, font size is
                          automatically reduced to fit all labels. (default: 30)
  --label-opacity <0...100>
                          Label opacity percent (default: 100)
  --label-font-color <#RRGGBB / #RGB>
                          Label font color (default: #FFF)
  --label-stroke-color <#RRGGBB / #RGB>
                          Label stroke color (default: #000)
  --label-stroke-width <w>
                          Label stroke width, 0 to disable. (default: auto)
  --label-align-horizontal <left,center,right>
                          Horizontal alignment of image labels. (default: left)
  --label-align-vertical <top,center,bottom>
                          Vertical alignment of image labels. (default: top)
  --label-hide-names      Hide names of image labels.
  --create-done-file      Create a file in output directory on successful
                          export. The filename can be customized using
                          --done-filename.
  --done-filename <done.json>
                          Done file filename. Has no effect unless
                          --create-done-file flag is also supplied. (default:
                          done.json)
  --log <log>             Log file path.
  --log-level <trace,debug,info,notice,warning,error,critical>
                          Log level. (default: info)
  --quiet                 Disable log.
  --media-search-path <media-search-path>
                          Media search path. This argument can be supplied more
                          than once to use multiple paths. (default: same
                          folder as fcpxml(d))
  --version               Show the version.
  -h, --help              Show help information.
```

### Developer Library

To use this package in a SwiftPM project, you need to set it up as a package dependency:

```swift
// swift-tools-version: 5.6
import PackageDescription

let package = Package(
  name: "MyPackage",
  dependencies: [
    .package(
        url: "https://github.com/TheAcharya/MarkersExtractor.git",
        from: "0.1.0"
    )
  ],
  targets: [
    .target(
      name: "MyTarget",
      dependencies: [
        .product(name: "MarkersExtractor", package: "MarkersExtractor")
      ]
    )
  ]
)
```

Check out [MarkersExtractorCLI.swift](https://github.com/TheAcharya/MarkersExtractor/blob/master/Sources/markers-extractor-cli/MarkersExtractorCLI.swift) to see how to use the main extractor class.

## Credits

Original Idea and Workflow by [Vigneswaran Rajkumar](https://vigneswaranrajkumar.com/)

Initial Work by [Vladilen Zhdanov](https://github.com/vzhd1701) (0.1.0 ... 0.1.1)

Maintained by [Steffan Andrews](https://github.com/orchetect) (0.2.0 ...)

## License

Licensed under the MIT license. See [LICENSE](https://github.com/TheAcharya/MarkersExtractor/blob/master/LICENSE) for details.

## Reporting Bugs

For bug reports, feature requests and other suggestions you can create [a new issue](https://github.com/TheAcharya/MarkersExtractor/issues) to discuss.

## Contributing

Code contributions are welcome. See [CONTRIBUTING](https://github.com/TheAcharya/MarkersExtractor/blob/master/CONTRIBUTING.md) for details before contributing.
