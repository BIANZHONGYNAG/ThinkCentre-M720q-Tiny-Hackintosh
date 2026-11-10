# 常见问题

## 启动相关

**卡在 `apfs_module_start`**
CFG Lock 没解锁，或 `AppleXcpmCfgLock` 为 false。两种解法：BIOS 里解锁 CFG Lock，
或把 `Kernel/Quirks/AppleXcpmCfgLock` 改成 true。

**选择器全是文字，没有图标**
`OpenCanopy.efi` 没加载，或 `Resources/Image` 缺失。检查
`UEFI/Drivers` 里 OpenCanopy 是否 `Enabled=true`，以及 `Misc/Boot/PickerMode` 是否为 `External`。

**卡 `IOConsoleUsers: gIOScreenLockState 3`**
核显帧缓冲不对。确认 `AAPL,ig-platform-id` 是 `0x3e9b0007`（本机方案），
并用 `-v` 加 verbose 看具体卡在哪一步。

**进系统后黑屏但机器在跑**
连接器类型配错。本机三个连接器都按 DisplayPort（`0x00000800`）；
如果接的是 HDMI，改成 `0x00080000` 并调整 busid。

**重置 NVRAM 后启动项丢失**
`LauncherOption=Disabled` 是刻意的（不写 Boot#### 变量）。重新进 BIOS 设启动顺序即可。

## 网络

**Wi-Fi 打不开 / 系统报告里没有 AirPort**
先确认 SimpleBCM 加载：

```bash
kmutil showloaded | grep -i simplebcm
system_profiler SPAirPortDataType | head -10
```

没加载就检查 `Kernel/Add` 里 SimpleBCM 是否 enabled、`MinKernel/MaxKernel`
是否覆盖当前内核（23.0.0–25.99.99），以及 AMFIPass 与 `-amfipassbeta` 是否在位。

**有线网卡不识别**
I219-V 走 IntelMausiEthernet。确认 kext 加载，且 `DisableIoMapper` 为 true 时
网卡仍在 `ioreg` 里可见：

```bash
ioreg -l | grep -i I219
ifconfig -a | grep -A3 en0
```

## 音频

**没有声音，但 AppleALC 已加载**
Tahoe 没有 `AppleHDA.kext`，必须靠 SimpleHDA 注入。检查：

```bash
kmutil showloaded | grep -i simplehda
system_profiler SPAudioDataType     # 设备列表为空 = 没成
```

**有设备但某个输出没声音**
`osascript -e 'get volume settings'` 在默认输出是 DisplayPort/HDMI 时会返回 `missing value`，
因为这条通路没有软件音量控制。先切到内建输出再测音量。

**音量正常但没有声音输出到显示器**
DisplayPort 音频需要 `igfxagdc=0` 且帧缓冲连接器类型正确，两者缺一不可。

## CPU 显示

**关于本机里是 `Genuine Intel(R) CPU 0000`**
说明 `revcpuname` 没生效。检查（必须带 GUID 前缀，普通 `nvram -p` 看不到）：

```bash
nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:revpatch
nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:revcpuname
```

`revpatch` 必须是 `cpuname`；如果残留 `sbvmm` 之类会禁用 cpuname。
改完要 `sudo nvram -d` 删旧值再重启，否则 `NVRAM/Add` 不会覆盖已存在的变量。

## 睡眠

**唤醒后 Wi-Fi 断连**
先确认是否真的是 Wi-Fi 掉，还是 DHCP 续租慢。看日志：

```bash
log show --last 5m --predicate 'eventMessage CONTAINS "Wake reason"' | tail -20
pmset -g assertions | head -20
```

**根本睡不着**
先看是不是有进程阻止：`pmset -g` 里的 `sleep` 一行会写 `prevented by ...`。
本机实测 `hibernatemode 3`、`standby 1`，配置上是正常的。

## iCloud / iMessage

**登录报「无法验证设备」**
序列号是占位值或与他人重复。按 [SMBIOS.md](SMBIOS.md) 生成自己的三件套，
`ROM` 必须是你 en0 的真实 MAC。

**换过配置后 iCloud 要求重新登录**
硬件 UUID 变了。本机用 `SystemUUID=OEM` 就是为了避免这个问题。

## EFI 修改

**改完开不了机怎么回滚**

```bash
# 挂载备份里的 EFI 分区
ls ~/efi-backups/
sudo diskutil mount disk0s1
cp -R ~/efi-backups/EFI-<时间戳>/EFI/* /Volumes/EFI/EFI/
sudo diskutil unmount /Volumes/EFI
```

**改了 config.plist 但没生效**
确认改的是挂载盘上的那份，不是仓库里克隆出来的副本。改完校验：

```bash
plutil -lint /Volumes/EFI/EFI/OC/config.plist
./oc/Utilities/ocvalidate/ocvalidate /Volumes/EFI/EFI/OC/config.plist
```

ocvalidate 版本必须与 `OpenCore.efi` 的版本一致，版本不匹配会报出并不存在的错误。
