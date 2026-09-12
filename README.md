# Code.NET
<p align="center">
  <a href="https://github.com/Open-code-Studio/CodeNet/actions/workflows/build-codenet.yml"><img src="https://img.shields.io/github/actions/workflow/status/Open-code-Studio/CodeNet/build-codenet.yml?branch=main&label=%E6%9E%84%E5%BB%BA&logo=github&style=for-the-badge" alt="构建状态"></a>
  <a href="https://github.com/Open-code-Studio/CodeNet/releases"><img src="https://img.shields.io/github/v/release/Open-code-Studio/CodeNet?display_name=tag&label=%E5%8F%91%E5%B8%83&logo=github&logoColor=white&color=ff007f&style=for-the-badge" alt="最新发布"></a>
  <a href="https://github.com/Open-code-Studio/CodeNet/stargazers"><img src="https://img.shields.io/github/stars/Open-code-Studio/CodeNet?label=%E6%98%9F%E6%A0%87&logo=github&logoColor=white&color=eac54f&style=for-the-badge" alt="星标"></a>
  <a href="https://github.com/Open-code-Studio/CodeNet/releases"><img src="https://img.shields.io/github/downloads/Open-code-Studio/CodeNet/total?label=%E4%B8%8B%E8%BD%BD%E9%87%8F&logo=github&logoColor=white&color=388bfd&style=for-the-badge" alt="下载量"></a>
  <img src="https://img.shields.io/badge/%E8%AE%B8%E5%8F%AF%E8%AF%81-MIT-9d4edd?logoColor=white&style=for-the-badge" alt="许可证">
</p>

---

## 让 .NET 在新版 macOS 上原厂即可用

[CodeNet](https://github.com/Open-code-Studio/CodeNet) 是 [dotnet/runtime](https://github.com/dotnet/runtime) 的定制分支，针对新版 macOS（含 macOS 27 及后续版本）上 .NET 运行时崩溃的问题做了修复。**核心思路是把修复做进 SDK 本身**：构建出的 CodeNet SDK 自带修复后的运行时，任何用它打包的 .NET 应用（例如 SulfurLauncher 的 macOS 版）出厂即带修复，不再需要在 App 层手工注入 dylib 或重签名。

## 获取 CodeNet

从 [Releases](https://github.com/Open-code-Studio/CodeNet/releases) 下载对应平台的预构建运行时 / SDK（当前发布标签 `sdk-v10.0.400`）：

| 平台                    | 资产                                                                                                                  | 说明                                   |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| **macOS Apple Silicon** | [dotnet-codenet-osx-arm64.tar.gz](https://github.com/Open-code-Studio/CodeNet/releases/download/sdk-v10.0.400/dotnet-codenet-osx-arm64.tar.gz) | 含修复运行时的 SDK（arm64）            |
| **macOS Intel**         | [dotnet-codenet-osx-x64.tar.gz](https://github.com/Open-code-Studio/CodeNet/releases/download/sdk-v10.0.400/dotnet-codenet-osx-x64.tar.gz)         | 含修复运行时的 SDK（x64）              |
| **macOS arm64（备用）** | [dotnet-codenet-osx-arm64-fixed.tar.gz](https://github.com/Open-code-Studio/CodeNet/releases/download/sdk-v10.0.400/dotnet-codenet-osx-arm64-fixed.tar.gz) | 与 arm64 版一致，作为已验证修复的备份资产 |
| **Linux x64**           | [dotnet-codenet-linux-x64.tar.gz](https://github.com/Open-code-Studio/CodeNet/releases/download/sdk-v10.0.400/dotnet-codenet-linux-x64.tar.gz)     | 含修复运行时的 SDK（x64）              |
| **Linux arm64**         | [dotnet-codenet-linux-arm64.tar.gz](https://github.com/Open-code-Studio/CodeNet/releases/download/sdk-v10.0.400/dotnet-codenet-linux-arm64.tar.gz) | 含修复运行时的 SDK（arm64）            |
| **Windows x64**         | [dotnet-codenet-win-x64.zip](https://github.com/Open-code-Studio/CodeNet/releases/download/sdk-v10.0.400/dotnet-codenet-win-x64.zip)               | 含修复运行时的 SDK（x64）              |
| **Windows arm64**       | [dotnet-codenet-win-arm64.zip](https://github.com/Open-code-Studio/CodeNet/releases/download/sdk-v10.0.400/dotnet-codenet-win-arm64.zip)           | 含修复运行时的 SDK（arm64）            |

> [!NOTE]
> 下载后解压，目录内的 `dotnet11x64`（或对应架构目录）即 CodeNet SDK：
> ```bash
> tar xzf dotnet-codenet-osx-arm64.tar.gz
> export DOTNET_ROOT="$PWD/dotnet11x64"
> export PATH="$DOTNET_ROOT:$PATH"
> ```
> 下游构建（如 SulfurLauncher 的 `publish-*.yml`）正是从此 Release 拉取 SDK，并设置 `DOTNET_ROOT` 后执行自包含发布，产物天然携带修复运行时。

## 修复了什么

### Wall#1 — 保持 GS cookie 页可写

新版 macOS 将 Guard Segment（GS）cookie 页设为只读，导致部分运行时初始化路径崩溃。CodeNet 改为**保持该页可写、不冻结为只读**（commit `macOS: keep GS cookie page writable; do not freeze it read-only`），从根上消除该崩溃。

### Wall#2 — 基于信号的 SEH / EXC_GUARD 修复

原版 .NET 在新版 macOS 上创建 CoreCLR 时会因 `EXC_GUARD` 异常（`HRESULT: 0x8007000C`）直接失败、进程被 SIGKILL。CodeNet 将 macOS 上的异常处理改为**基于信号的 SEH（signal-based SEH）**，使 CoreCLR 能在新版 macOS 正常创建与运行。

### 出厂即修复（code.net 层注入）

上述修复被打包进 CodeNet SDK 的运行时（`packs/` 中的 `Microsoft.NETCore.App.Runtime.osx-arm64`），因此**用 CodeNet 构建出的自包含应用天然携带修复运行时**，无需在发布后再对 `.app` 做 dylib 注入或重签名。

## 从源代码构建

贡献者环境、子模块与完整构建说明参见 [CONTRIBUTING.md](CONTRIBUTING.md)。下面是从源码构建 CodeNet 运行时的常用方法。

### 环境准备（macOS）

```bash
brew install cmake ninja icu4c
```

### 构建运行时

```bash
./build.sh -arch arm64 -os osx -c Release \
  --subset clr+libs \
  --ninja \
  /p:TargetOS=osx \
  /p:TargetArchitecture=arm64 \
  /p:Configuration=Release
```

构建产物分为两部分，打包时需要合并：

- `artifacts/bin/coreclr/osx.<Arch>.Release` — CoreCLR 宿主与工具（`libcoreclr.dylib`、`corerun` 等）
- `artifacts/bin/runtime/*-osx-Release-<Arch>` — 全部托管库 `System.*.dll`

### 打包与安装包

合并后的运行时位于 `artifacts/package/runtime`，并产出：

- `dotnet-runtime-osx-<arch>.tar.gz` — 可直接解压使用的运行时包
- `dotnet-runtime-osx-<arch>.pkg` — macOS 安装包（标识符 `net.codenet.runtime`，版本 `10.0.11`，安装到 `/usr/local/share/dotnet`，并通过 `etc/paths.d/dotnet` 写入 PATH）

> [!NOTE]
> 也可使用仓库根的 `./dotnet.sh` 调用 CodeNet 自带的 dotnet CLI，它会隔离运行时查找（`DOTNET_MULTILEVEL_LOOKUP=0`）以保证构建确定性。

### 其他平台

`build-codenet.yml` 同样支持 `linux`（x64 / arm64）与 `win`（x64 / arm64），分别对应 `dotnet-runtime-linux-<arch>.tar.gz` 与 `dotnet-runtime-win-<arch>.zip`。**这些 job 在 push 到 `main` 时会自动构建，并将产物以 `dotnet-codenet-<os>-<arch>.*` 命名发布到 Release `sdk-v10.0.400`**（macOS 还会额外发布 `.pkg` 安装包）；手动 `workflow_dispatch` 可通过 `target_os` 单独指定只构建某一平台。

## 致谢

CodeNet 基于 [dotnet/runtime](https://github.com/dotnet/runtime)（MIT 许可）构建，向 .NET 团队与所有运行时维护者致敬；macOS 兼容性修复由 Open-code-Studio 维护。

## 许可证

CodeNet 继承上游 .NET Runtime 的 [MIT](LICENSE.TXT) 许可证。
