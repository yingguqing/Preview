# QLProvision - Quick Look for ipa & provision


![Thumbnails example](https://raw.github.com/yingguqing/Preview/master/Screenshots/1.png)

Inspired by a number of existing alternatives, the goal of this project is to provide clean, reliable, current and open source Quick Look plugin for iOS & macOS developers.

Thumbnails will show app icon for `.ipa`/ `.xcarchive` or expiring status and device count for `.mobileprovision`. Quick Look preview will give a lot of information, including devices UUIDs, certificates, entitlements and much more.

![Valid AdHoc provision](https://raw.github.com/yingguqing/Preview/master/Screenshots/2.png)

Xcode now have its own mobileprovision Quick Look plugin. Since it's application-provided it will override user installed plugins, including ProvisionQL.

ProvisionQL will still work for ipa and xcarchive, but if you prefer it also for mobileprovision, just delete Xcode's QL plugin here:

```
# before xcode 16
/Applications/Xcode.app/Contents/Library/QuickLook/DVTProvisioningProfileQuicklookGenerator.qlgenerator
# xcode 16
/Applications/Xcode.app/Contents/PlugIns/ProvisoningProfileQuicklookExtension.appex
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

Initially based on [ProvisionQL](https://github.com/ealeksandrov/ProvisionQL).

### Tutorials based on this example:

* English - [aleksandrov.ws](https://aleksandrov.ws/2014/02/25/osx-quick-look-plugin-development/)
* Russian - [habrahabr.ru](https://habrahabr.ru/post/208552/)

## Installation

### Xcode project

Just clone the repository, open `Preview.xcodeproj` and build active target. Shell script will place app in `/Applications` and open `Preview.app`;

### Manual

* build project;
* move `Preview.app` to `/Applications/Preview.app);
* open `Preview.app`;
* open `System Preferences` to `Extensions` page
* select `Quick Look` and check `QLProvision`

## Author

Created and maintained by 影孤清.

## 可能遇到的问题

您可能会发现您无法在`编辑器`菜单甚至`扩展`首选项窗格中看到该插件。这似乎是由于在 `App Store` 之外安装 `Xcode` 版本引起的。如果发生这种情况，请打开终端并运行：

`pluginkit -m -p com.apple.dt.Xcode.extension.source-editor -A -D -vvv`

如果在此列表中看不到插件，则可以通过在 Terminal 中运行以下命令来重置插件列表：

```
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/Xcode.app
```

再次打开软件即可

如果系统设置的扩展里没有 `Xcode` 选项，可以尝试把 `Xcode` 重命名之后，再重启 `Xcode`。

**注意：**编译没有选择账号或指定证书时，会导致在` Xcode`中不能显示，快捷键中也没有相应的选项。

## License

`Preview` is available under the MIT license. See the [LICENSE.md](LICENSE.md) file for more info.
