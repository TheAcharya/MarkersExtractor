# Contributing to MarkersExtractor

This file contains general guidelines but is subject to change and evolve over time.

## Code Contributions

Before contributing, it is encouraged to post an Issue to discuss a bug or new feature prior to implementing it. Once implemented on your fork, PRs are welcome for features that benefit the core functionality of the project.

Code owners/maintainers reserve the right to revise or reject contributions if they are not deemed fit.

## Code Formatting

Code formatting is not strictly enforced but is a courtesy we would like contributors to employ.

[SwiftFormat](https://github.com/nicklockwood/SwiftFormat) is used to format `*.swift` files.

```bash
cd <path to repo root>
swiftformat .
```

## Unit Testing

Unit testing is encouraged but not strictly required if making code contributions. However, all existing unit tests must pass before a code contribution will be accepted.

Unit tests can be run on the command-line or in Xcode using the MarkersExtractor-Package scheme.

GitHub CI is also set up to run the unit tests server-side.

## Releases

Publishing releases and tags should be left to code owners/maintainers.

For code owners/maintainers, the following release spec is used:

1. Unit tests must pass
2. Update the version number string literal near the top of MarkersExtractor-CLI.swift (on main branch)
3. Compile the CLI tool as a binary executable and zip it
4. Update root CHANGELOG.md (on main branch)
   - with a condensed bullet-point list of changes/fixes/improvements according to its established format
   - where possible, reference the Issue number(s), PR(s) or commit(s) where each change was made
5. Update root README.md (on main branch) with any pertinent revisions:
   - New help block output of the CLI tool
   - Updated version number of CLI tool
6. Make GitHub Release using
   - the new version number as its new tag and release name
   - the added CHANGELOG.md block as the release notes
   - attach the binary zip file