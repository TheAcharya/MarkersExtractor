# MarkersExtractor CLI

![MarkersExtractorCLI.gif](assets/MarkersExtractorCLI.gif)

The Marker metadata extraction tool and engine for Final Cut Pro. (Currenly in development)

# Core Features

- Accurately extract Markers from FCP's FCPXML/FCPXMLD to CSV
- Ability to batch extract and render stills or animated GIFs based on Marker's timecode
- Ability to batch burn-in labesl of Marker's metadata onto the stills or animated GIFs

# Table of contents

- [Installation](#Installation)
  - [Pre-compiled Binary (Recommended)](#pre-compiled-binary-recommended)
  - [From Source](#from-source)
- [Usage](#Usage)
  - [CLI](#cli)
- [For Development](#for-development)
  - [Library](#library)
  - [Development](#development)
- [Credits](#Credits)
- [License](#License)
- [Reporting Bugs & Contributions](#reporting-bugs--contributions)

# Installation

## Pre-compiled Binary (Recommended)

Download the latest version of CLI universal binary [here](https://github.com/TheAcharya/MarkersExtractor/archive/refs/tags/0.1.1.zip).

## From Source

```shell
VERSION=0.1.0  # replace this with the version you need
git clone https://github.com/TheAcharya/MarkersExtractor.git
cd MarkersExtractor
git checkout "tags/$VERSION"
swift build -c release
```

Once the build has finished, the `markers-extractor-cli` executable will be located at `.build/release/`.

# Usage

## CLI

```shell
$ markers-extractor-cli --help
OVERVIEW: Tool to extract markers from FCPXML(D).

USAGE: markers-extractor-cli [<options>] <fcpxml-path> <output-dir>

ARGUMENTS:
  <fcpxml-path>           Input FCPXML file / FCPXMLD bundle.
  <output-dir>            Output directory.

OPTIONS:
  --image-format <png,jpg,gif>
                          Marker thumb image format. (default: png)
  --image-quality <0-100> Image quality percent for JPG. (default: 100)
  --image-width <w>       Limit image width keeping aspect ratio.
  --image-height <h>      Limit image height keeping aspect ratio.
  --image-size-percent <%>
                          Limit image size to % keeping aspect ratio. (default for GIF: 50)
  --gif-fps <1-50>        GIF frame rate. (default: 10)
  --gif-span <sec>        GIF capture span around marker. (default: 2)
  --id-naming-mode <ProjectTimecode,Name,Notes>
                          Marker naming mode. (default: ProjectTimecode)
  --label <label>         Label to put on a thumb image, can be used multiple times form multiple labels. Use --help-labels to get full list of available labels.
  --label-copyright <text>
                          Copyright label, will be added after all other labels.
  --label-font <name>     Font for image labels (default: Menlo-Regular)
  --label-font-size <pt>  Maximum font size for image labels, font size is automatically reduced to fit all labels. (default: 30)
  --label-opacity <0-100> Label opacity percent (default: 100)
  --label-font-color <#RRGGBB / #RGB>
                          Label font color (default: #FFF)
  --label-stroke-color <#RRGGBB / #RGB>
                          Label stroke color (default: #000)
  --label-stroke-width <w>
                          Label stroke width, 0 to disable. (default: auto)
  --label-align-horizontal <left,center,right>
                          Horizontal alignment of image label. (default: left)
  --label-align-vertical <top,center,bottom>
                          Vertical alignment of image label. (default: top)
  --create-done-file      Create 'done.txt' file in output directory on successful export.
  --log <log>             Log file path.
  --log-level <trace,debug,info,notice,warning,error,critical>
                          Log level. (default: info)
  --quiet                 Disable log.
  --help-labels           List all possible labels to use with --label.
  --version               Show the version.
  -h, --help              Show help information.
```

# For Development

### Library

To use this package in a SwiftPM project, you need to set it up as a package dependency:

```swift
// swift-tools-version:5.6
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

## Development

This projects uses [pre-commit](https://pre-commit.com/) for automatic source files formatting. [swift-format](https://github.com/apple/swift-format) (swift-5.6.1-RELEASE) is used to format `*.swift` files. Make sure both are present in PATH before making commits.

```shell
git clone https://github.com/yourname/MarkersExtractor
cd MarkersExtractor
pre-commit install
git checkout -b fix
```

# Credits

Original Idea and Workflow by [Vigneswaran Rajkumar](https://vigneswaranrajkumar.com/)

Initial Work by [Vladilen Zhdanov](https://github.com/vzhd1701)

Maintained by [Steffan Andrews](https://github.com/orchetect)

# License

Licensed under the MIT license. See [LICENSE](https://github.com/TheAcharya/MarkersExtractor/blob/master/LICENSE) for details.

# Reporting Bugs & Contributions

For bug reports, feature requests and other suggestions you can create [a new issue](https://github.com/TheAcharya/MarkersExtractor/issues) to discuss.
