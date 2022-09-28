# ProvisionQL - Quick Look for ipa & provision

[![CI Status](https://github.com/yingguqing/Preview/workflows/CI/badge.svg?branch=master)](https://github.com/yingguqing/Preview/actions)
[![Latest Release](https://img.shields.io/github/release/yingguqing/Preview.svg)](https://github.com/yingguqing/Preview/releases/latest)
[![License](https://img.shields.io/github/license/yingguqing/Preview.svg)](LICENSE.md)
![Platform](https://img.shields.io/badge/platform-macos-lightgrey.svg)

![Thumbnails example](https://raw.github.com/yingguqing/Preview/master/Screenshots/1.png)

Inspired by a number of existing alternatives, the goal of this project is to provide clean, reliable, current and open source Quick Look plugin for iOS & macOS developers.

Thumbnails will show app icon for `.ipa`/ `.xcarchive` or expiring status and device count for `.mobileprovision`. Quick Look preview will give a lot of information, including devices UUIDs, certificates, entitlements and much more.

![Valid AdHoc provision](https://raw.github.com/yingguqing/Preview/master/Screenshots/2.png)

Xcode now have its own mobileprovision Quick Look plugin. Since it's application-provided it will override user installed plugins, including ProvisionQL.

ProvisionQL will still work for ipa and xcarchive, but if you prefer it also for mobileprovision, just delete Xcode's QL plugin here:

```
/Applications/Xcode.app/Contents/Library/QuickLook/DVTProvisioningProfileQuicklookGenerator.qlgenerator
```
And run

```
qlmanage -r
```

Supported file types:

* `.ipa` - iOS packaged application
* `.xcarchive` - Xcode archive
* `.appex` - iOS/OSX application extension
* `.mobileprovision` - iOS provisioning profile
* `.provisionprofile` - OSX provisioning profile

[More screenshots](https://github.com/yingguqing/Preview/blob/master/Screenshots/README.md)

### Acknowledgments

Initially based on [ProvisionQL](https://github.com/yingguqing/Preview).

### Tutorials based on this example:

* English - [aleksandrov.ws](https://aleksandrov.ws/2014/02/25/osx-quick-look-plugin-development/)
* Russian - [habrahabr.ru](https://habrahabr.ru/post/208552/)

## Installation

### Xcode project

Just clone the repository, open `Preview.xcodeproj` and build active target. Shell script will place app in `/Applications` and open `快速查看.app`;

### Manual

* download archive with latest version from the [Releases](https://github.com/yingguqing/Preview/releases/latest) page;
* move `快速查看.app` to `/Applications/快速查看.app);
* open `快速查看.app`;
* open `System Preferences` to `Extensions` page
* select `Quick Look` and check `QLProvision`

## Author

Created and maintained by 影孤清.

## License

`Preview` is available under the MIT license. See the [LICENSE.md](LICENSE.md) file for more info.
