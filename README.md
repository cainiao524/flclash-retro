# 复古 VPN

基于 [FlClash](https://github.com/chen08209/FlClash) 官方源码的复古蓝橙界面分支，沿用其 ClashMeta（mihomo）内核和平台 VPN／代理能力。本仓库保存当前修改后的源码快照，并非官方发行仓库。

## 当前功能

- 默认复古功能主页，包含连接、配置、代理、规则／全局／直连模式和工具入口。
- 原 APK 风格的经典布局为独立附加页面，上游仪表盘保留为高级功能入口。
- 手机、平板和桌面横竖屏适配；切换功能后点击“主页”仍返回复古界面。
- 入场渐显、按压反馈、运行时光环和波浪动画，后台与减少动态效果时暂停循环。
- 已完成安卓与 Windows 发布构建；iPhone／iPad 版未实现。

## 目录与构建

- `flclash-official/`：应用源码、内核子模块、插件、测试和上游许可。
- `build-flclash-android.ps1`：安卓构建脚本。
- `build-flclash-windows.ps1`：Windows 构建与压缩包生成脚本。

构建工具与缓存不上传。现有脚本使用工作区 `.tools` 中的 Flutter、Go、Android 工具及依赖缓存，下载代理为 `127.0.0.1:7890`；Windows 还需要 Visual Studio 桌面 C++ 工作负载和 Rust。详细要求见 [构建说明](flclash-official/RETRO_BUILD.md)。

首次克隆后，先初始化固定版本的内核子模块，并创建本机构建环境配置：

```powershell
git submodule update --init --recursive
Copy-Item flclash-official/env.example.json flclash-official/env.json
```

示例配置默认使用 `stable` 环境，不显示右上角预发布角标。已有工作区需要同时将本机 `env.json` 的 `APP_ENV` 改成 `stable` 并重新构建；仅更新仓库不会改变已安装的旧版本。

```powershell
.\build-flclash-android.ps1 -Mode release -SplitPerAbi
.\build-flclash-windows.ps1
```

当前界面和导航测试共 168 项通过。Windows 打包已检查内核清单、运行库和资源；未为测试中断已有代理连接。Windows 使用前请先退出原 FlClash，配置目录仍遵循上游约定。

## 上传范围与许可

仓库不包含本机工具缓存、编译输出、安装包、原始参考 APK、签名密钥或个人订阅配置。上游说明、版权与 [GPL-3.0 许可](flclash-official/LICENSE) 保留在源码目录中；内核和第三方组件保留各自许可。参考界面资源不代表本项目取得原软件品牌或收费服务的授权。
