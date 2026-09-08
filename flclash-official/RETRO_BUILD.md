# FLClash // 86

这是基于官方 FlClash 0.8.96 源码的复古界面分支。Android 端继续沿用官方的 ClashMeta（mihomo）Go 核心、JNI 桥接、`VpnService`、`ServiceState` 和 `ServiceController`，复古主页只调用原有连接状态与 VPN 控制链，没有新增第二套 VPN 生命周期。

## 本次改动

- `lib/common/retro_theme.dart`：复古蓝橙配色、等宽字体、硬边框主题。
- `lib/application.dart`：浅色与深色 Material 主题切换到复古主题，同时保留原有页面与状态管理。
- `lib/pages/retro_home.dart`：默认展示复古功能主页；功能页面的底部和侧栏“主页”入口返回该页，不再切换成上游仪表盘。
- `lib/views/dashboard/widgets/retro_dashboard.dart`：蓝底白色圆形连接按钮、配置、规则／全局／直连模式和代理／配置／工具快捷入口。
- `lib/views/dashboard/classic_home.dart`：原 APK 经典布局为独立附加页面，可从默认主页右上角进入。
- `lib/views/dashboard/widgets/home_motion.dart`：入场、按压反馈、运行时呼吸光环和波浪；页面隐藏、应用进入后台或减少动态效果时暂停循环。
- `lib/views/dashboard/dashboard.dart`：保留完整上游仪表盘与小组件编辑，作为复古主页抽屉里的高级功能入口。
- `lib/manager/app_manager.dart`：桌面导航增加 `FLCLASH // 86` 品牌标识。
- `lib/widgets/card.dart`：官方卡片默认圆角收紧为 4，保留现有交互和选择状态。
- `lib/common/constant.dart`：应用显示名和默认主题强调色改为 `FLClash // 86`。
- Android 通知、服务频道、调试包名称同步为 `FLClash // 86`。

## Android 构建

官方构建脚本需要 Flutter 3.44.4、Dart 3.8+、Android SDK、Android NDK 和 JDK 17：

在工作区根目录执行项目内构建脚本即可（脚本会设置本地 Flutter/SDK/NDK/Go/Pub 缓存，并通过 `127.0.0.1:7890` 的 SOCKS5 代理下载依赖）：

```powershell
.\build-flclash-android.ps1 -Mode release -SplitPerAbi
```

也可以在源码目录直接运行 `flutter build apk --release`；首次构建会由官方 Gradle 插件编译核心。

如果只验证 Android Kotlin 模块，可以在 `android/` 下运行：

```text
./gradlew :service:compileDebugKotlin
./gradlew :app:compileDebugKotlin
```

首次构建会由官方 Gradle 插件编译 `core/` 下的 mihomo Go 核心，并把 `libclash.so` 放入 Android core 模块；不要手工替换这个产物。

## Windows 构建

在工作区根目录执行：

```powershell
.\build-flclash-windows.ps1
```

需要已安装带桌面 C++ 工作负载的 Visual Studio 构建工具，以及用户目录下的 Rust 工具链。Flutter、Go 和依赖缓存使用项目内工具目录，下载通过 `127.0.0.1:7890` 代理。

输出为 `dist/FlClash-retro-0.8.96-windows-x64.zip`。将整个压缩包解压后运行 `FlClash.exe`，不能单独复制主程序；同目录的内核、服务助手、动态库和资源必须保留。使用前先退出正在运行的官方 FlClash，本脚本不会替换已安装程序或停止现有代理服务。配置目录仍遵循上游约定，不是隔离的第二套配置。

Windows 沿用上游独立内核进程和服务助手。需要 TUN 时使用软件自身的授权流程；构建脚本不会自动安装或替换系统服务。
