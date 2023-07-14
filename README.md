The FlutterFire packages do not properly follow semver, and all packages must be on the versions released together. This causes issues downgrading a package, as it will be incompatible with the other FlutterFire packages. The `ffvm` tool aims to solve this by allowing you to specify what package and version you want to use, and it will lock all the other packages to the appropriate versions.

## Features

Lock all FlutterFire packages to versions compatible with the specified package and version

## Getting started

```console
dart pub global activate flutterfire_version_manager
```

## Usage

```console
ffvm <package> <version>
```

## Additional information

Hopefully in the future this package will not be necessary

If you maintain any third party FlutterFire packages that are affected by this, please create an issue and I will add them to the list of packages that are locked
