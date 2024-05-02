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
2. Ensure package dependencies are set to version numbers and not branch names.
3. Perform the following file modifications:
   - Update the version number string literal in `Sources/MarkersExtractor/Version.swift`
   - Update root `CHANGELOG.md`
     - with a condensed bullet-point list of changes/fixes/improvements according to its established format
     - where possible, reference the Issue/PR number(s) or commit(s) where each change was made
   - Update root `README.md` with any pertinent revisions:
     - Updated version number of CLI tool, updated link to CLI binary zip download URL.
       (Change `0.2.0` here to the new version number)
       `https://github.com/TheAcharya/MarkersExtractor/releases/download/0.2.0/markers-extractor-cli-0.2.0.zip`
     - New help block output of the CLI tool
4. Commit the changes made in Step 3 using the new version number (ie: `0.2.0`) as the commit message, and push to main.
5. Run the `release_github` workflow, and enter `yes` for the `Release after build` parameter.
6. After the workflow run successfully completes, publish GitHub Release:
   1. Find the newly created draft release in https://github.com/TheAcharya/MarkersExtractor/releases
   2. Paste the `CHANGELOG.md` block for this release version into the release notes field
   3. Publish the release
