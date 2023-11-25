# MarkersExtractor Change Log

## 0.2.7

- Added `--markers-source` CLI flag, allowing import of markers and/or captions (#8)

## [0.2.6](https://github.com/TheAcharya/MarkersExtractor/releases/tag/0.2.6) (2023-11-24)

### Changes

- Changed `--done-filename` filename to `--result-file-path` path (#67)
- Removed `--create-done-file` flag as it is now redundant. (#67)
  If `--done-file-path` is specified, a result file will be written to disk and if not specified, none will be written.
- Renamed manifest file JSON key `csvPath` to `csvManifestPath`
- Renamed manifest file JSON key `jsonPath` to `jsonManifestPath`
- Added manifest file JSON key `outputFolder` containing the final output path of the extracted files (#67)
- Added manifest file JSON key `profile` containing the profile identifier for the profile that was used (#67)
- `MarkersExtractor.extract()` now returns result information (#68)

## [0.2.5](https://github.com/TheAcharya/MarkersExtractor/releases/tag/0.2.5) (2023-11-22)

### Changes

- Markers within compound clips are now discarded (#7)
- Renamed "Type" manifest field to "Marker Type" (#63)
- Added "Clip Type" manifest field (#62)
- Removed "Clip Filename" manifest field (#65)

### Bug Fixes

- Fixed bug where image generation could fail when project start time was later than 00:00:00:00 (#37)

## [0.2.4](https://github.com/TheAcharya/MarkersExtractor/releases/tag/0.2.4) (2023-11-21)

### Changes

- Markers exactly on clip boundaries are now considered within clip bounds (#56)
- Output folder name is now uniqued if it already exists instead of aborting process (#35)

### Refinements

- Substantial internal refactors to FCPXML parser, which fixes several bugs and increases maintainability

## [0.2.3](https://github.com/TheAcharya/MarkersExtractor/releases/tag/0.2.3) (2023-10-31)

### New Features

- Added `--no-progress` CLI flag to suppress progress output to console (#31)

### Bug Fixes

- Resolved issue where CLI was not outputting progress to the console in a release build (#31)
- Performance and reliability improvements for thumbnail image generation (#49)

## [0.2.2](https://github.com/TheAcharya/MarkersExtractor/releases/tag/0.2.2) (2023-10-31)

### Refinements

- Progress reporting is now more relevant and reliable (#31)

### Bug Fixes

- Fixed hang during thumbnail image generation on Intel systems (#53)
- Fixed potential crash when media contains fewer frames than required to produce an animated GIF

## [0.2.1](https://github.com/TheAcharya/MarkersExtractor/releases/tag/0.2.1) (2023-10-30)

### General

- Updated README and added new icon thanks to [Bor Jen Goh](https://www.artstation.com/borjengoh)

### New Features

- Thumbnail image generation is now multithreaded to improve performance (#49)
- CLI now outputs progress percentage to the console (#31)

### Library Refinements

- Added `async`/`await` support (#49)
- Errors thrown now provide more granular error cases (#46)
- `MarkersExtractor` now conforms to `ProgressReporting` (#31)
- Most concrete types now conform to `Sendable`
- Internal refactors and improvements

## [0.2.0](https://github.com/TheAcharya/MarkersExtractor/releases/tag/0.2.0) (2023-04-28)

### General

- Major internal refactors to improve reliability and scalability for possible future formats and feature additions
- Unit tests added with automated GitHub CI

### New Features

- Default done file renamed to done.json and content is now JSON formatted (#2)
- Added `--exclude-exclusive-roles <video, audio>` CLI flag (#5)
- Markers that share the same ID will gain unique incrementing number suffixes by default (#9)
- Markers are now sorted chronologically by timecode (#10)
- Added `--label-hide-names` CLI flag to hide label names on thumbnail images (#16)
- Added `--done-filename <filename>` CLI argument to customize done filename (#17)
- Added `--media-search-path <path>` argument to allow custom media search path(s) (#20)
- Added Airtable export profile (`--export-format airtable`) (#21)
- Added MIDI file export profile (`--export-format midi`) (#23)
- Added `--enable-subframes` CLI flag to show subframes in all timecode strings (#29)
- Added `--include-outside-clip-boundaries` CLI flag (#34)
- Added `--folder-format` CLI flag (#35)
- Added `--no-media` CLI flag (#40)
- Added JSON manifest file output in addition to CSV (#44)

### Refinements

- `--id-naming-mode` and `--label` CLI arguments now take short-form label IDs (#15)
- Empty roles with no default role receive placeholder role (#33)
- Redundant subroles are now stripped in metadata output (#33)
- Parsing marker locations is now more reliable (#34)

### Bug Fixes

- Correctly supports all FCP frame rates (including drop frame) (#3)
- Library name is now URL decoded and stripped of file extension (#13)
- Markers outside of clip bounds now correctly log a warning (#34)

## [0.1.1](https://github.com/TheAcharya/MarkersExtractor/releases/tag/0.1.1) (2022-09-08)


### Bug Fixes

* Create `done.txt` file instead of `.done` ([ad378e5](https://github.com/vzhd1701/MarkersExtractor/commit/ad378e52b836de0dbb2534128e890ab71d724002))

## [0.1.0](https://github.com/TheAcharya/MarkersExtractor/releases/tag/0.1.0) (2022-09-07)


### New Features

* Added `--label-opacity` option ([e9b2418](https://github.com/vzhd1701/MarkersExtractor/commit/e9b2418df8b2b07bf22e5a7b1da257ef2456578e))


### Bug Fixes

* Added support for media files without video ([f0d84de](https://github.com/vzhd1701/MarkersExtractor/commit/f0d84dee5f48f43f3d0feb219480126839e463d7))
* Exit with error if any marker ID is empty ([926f857](https://github.com/vzhd1701/MarkersExtractor/commit/926f8575a51c979d72e7dba80eda36a5ae9b1cab))
