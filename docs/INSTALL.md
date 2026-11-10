# 安装步骤

本仓库只提供 EFI，不提供 macOS 安装镜像。你需要一台能运行 macOS 的机器（Mac 或已装好的
黑苹果）来制作安装盘。

## 一、制作安装 U 盘

```bash
# 1. 从 App Store 下载 macOS，确认安装器路径
ls /Applications | grep -i "Install macOS"

# 2. 抹掉 U 盘（16 GB 以上，确认 diskN 是 U 盘不是内置盘！）
diskutil list
diskutil eraseDisk HFS+ USB /dev/diskN

# 3. 写入安装器（把 Install macOS Tahoe.app 换成实际名字）
sudo /Applications/Install\ macOS\ Tahoe.app/Contents/Resources/createinstallmedia \
     --volume /Volumes/USB --nointeractive

# 4. U 盘会变成 Install macOS 卷，给它挂上 EFI 分区
diskutil list                                   # 找到 U 盘的 EFI 分区
sudo diskutil mount diskNs1
```

## 二、写入 EFI

```bash
# 克隆本仓库
git clone https://github.com/<你的用户名>/ThinkCentre-M720q-Tiny-Hackintosh.git
cd ThinkCentre-M720q-Tiny-Hackintosh

# 生成你自己的 SMBIOS 并填进 config.plist —— 先做这一步，见 docs/SMBIOS.md

# 复制到 U 盘 EFI 分区
cp -R EFI/* /Volumes/EFI/EFI/
sudo diskutil unmount /Volumes/EFI
```

U 盘上的目录应该是 `EFI/BOOT/BOOTx64.efi` 和 `EFI/OC/...`，不要多套一层 `EFI/EFI`。

## 三、BIOS 与首次启动

按 [BIOS.md](BIOS.md) 改好设置，`F12` 选择 U 盘启动。

OpenCore 选择器里选 `Install macOS`。第一次安装会重启 3 到 4 次，
**每次都要从 U 盘引导，并在选择器里选对应的安装项**（不要选错成 U 盘本身）。

安装过程中屏幕可能长时间黑屏或只有进度条，只要硬盘灯在闪就等着。

## 四、安装后

```bash
# 1. 挂载内置盘 ESP
diskutil list                    # 找到内置盘（通常是 disk0）的 EFI 分区
sudo diskutil mount disk0s1

# 2. 把 U 盘上的 EFI 复制进来
cp -R /Volumes/EFI/EFI/* /Volumes/EFI/EFI/    # 注意先确认挂载路径，别搞混两个 EFI

# 更稳妥的做法：直接重新复制一次源目录
# cp -R ~/Projects/ThinkCentre-M720q-Tiny-Hackintosh/EFI/EFI/* /Volumes/EFI/EFI/

# 3. 卸载
sudo diskutil unmount /Volumes/EFI
```

然后进 BIOS 把内置盘设为第一启动项，拔掉 U 盘。

## 五、装完必查

```bash
# 核显
system_profiler SPDisplaysDataType | grep -E 'Chipset|Metal|Resolution'

# 音频（要看到内建输出/输入）
system_profiler SPAudioDataType | head -20

# 网卡
system_profiler SPNetworkDataType | grep -E 'Type:|BSD Device'
ifconfig en0 | head -3

# 无线
system_profiler SPAirPortDataType | head -12

# 第三方 kext 是否都在
kmutil showloaded --list-only | grep -v com.apple

# 确认引导的是你自己的 EFI
nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version
```

## 六、常见卡点

| 现象 | 处理 |
|---|---|
| 选择器都不出现 | 盘不是 UEFI 启动 / CSM 没关 / `BOOTx64.efi` 路径不对 |
| 卡 `apfs_module_start` | CFG Lock 没解锁，或 `AppleXcpmCfgLock` 未开 |
| 卡 `IOConsoleUsers: gIOScreenLockState 3` | 核显 platform-id 与机型不匹配 |
| 安装到一半重启后找不到盘 | 正常，进选择器选 `macOS Installer` 继续 |
| 装完没有声音 | 先确认 `SimpleHDA` 加载了，再查 `layout-id` |
