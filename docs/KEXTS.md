# Kext 清单

14 个 kext，顺序即 `Kernel/Add` 的加载顺序（Lilu 及其插件必须排在前面）。

| # | Kext | 版本 | MinKernel–MaxKernel | 作用 |
|---|---|---|---|---|
| 1 | Lilu | 1.7.3 | 全部 | 内核补丁框架，其余补丁类 kext 的依赖 |
| 2 | VirtualSMC | 1.3.9 | 全部 | 模拟 SMC 芯片，没有它系统起不来 |
| 3 | SMCProcessor | 1.3.9 | 全部 | 提供 CPU 温度/电压传感器 |
| 4 | SMCSuperIO | 1.3.9 | 全部 | 提供风扇转速等 SuperIO 传感器 |
| 5 | AMFIPass | 1.4.1 | 20.0.0+ | 允许在 AMFI 开启时加载未签名 kext（SimpleBCM/SimpleHDA 需要） |
| 6 | SimpleBCM | 1.2.0 | 23.0.0–25.99.99 | 在 Tahoe 上自己实现 `AirPort_BrcmNIC` 类，替代 IOSkywalk 降级方案 |
| 7 | WhateverGreen | 1.7.2 | 全部 | 核显帧缓冲补丁、DP/HDMI 连接器修补 |
| 8 | AppleALC | 1.9.9 | 全部 | 音频 codec 补丁（ALC235，layout 72） |
| 9 | SimpleHDA | 1.0.1 | 25.0.0–25.99.99 | Tahoe 不再自带 `AppleHDA.kext`，此 kext 把它恢复出来 |
| 10 | IntelMausiEthernet | 3.0.3 | 全部 | Intel I219-V 有线网卡驱动 |
| 11 | NVMeFix | 1.1.4 | 18.0.0+ | NVMe 电源管理与兼容性修补 |
| 12 | RestrictEvents | 1.1.7 | 全部 | 屏蔽不必要的事件/日志，配合 `revcpuname` 显示 CPU 型号 |
| 13 | USBToolBox | 1.2.0 | 全部 | USB 端口映射框架 |
| 14 | UTBMap | 1.1 | 全部 | 本机的 USB 端口映射数据（USBToolBox 生成） |

## 两个特殊 kext

### SimpleBCM（Wi-Fi）

BCM4360（`14E4:43A0`）在 Sonoma 之后 Apple 移除了原生驱动。常见方案是把
`IOSkywalkFamily` 降级 + 加载 `IO80211FamilyLegacy` + `AirPortBrcmNIC`（约 21 MB，
还要在 `Kernel/Block` 里排除 `com.apple.iokit.IOSkywalkFamily`）。

SimpleBCM 走另一条路：直接用 Apple 原生的 `IOSkywalkFamily` / `IO80211Family`
实现 `AirPort_BrcmNIC` 类。所以本 EFI 的 `Kernel/Block` 是**空的**，这是正确状态，
不是漏配。如果需要排查，先看：

```bash
kmutil showloaded | grep -i simplebcm
system_profiler SPAirPortDataType | head -20
```

### SimpleHDA（音频）

macOS 26 Tahoe 移除了 `/System/Library/Extensions/AppleHDA.kext`，AppleALC 没有东西可打补丁，
表现为「kext 加载了但没有任何音频设备」。SimpleHDA 通过 OpenCore 注入把 AppleHDA 带回来，
不需要 root patch，也不需要重建内核缓存。

验证顺序：先看 kext 加载，再看设备：

```bash
kmutil showloaded | grep -i -E 'simplehda|applealc'
system_profiler SPAudioDataType     # 必须看到设备，设备为空就是没成
```

## 精简说明

这份 EFI 相对发行版模板已经做过裁剪：

- 删掉 `EFI/APPLE/UPDATERS`（Apple 固件更新器，黑苹果用不到，`BlacklistAppleUpdate=true`）
- `Misc/Tools` 只留 `CsrUtil.efi` 和 `OpenShell.efi`（`ResetNvramEntry.efi` 已提供 NVRAM 重置）
- 没有冗余的 `IOSkywalkFamily` / `IO80211FamilyLegacy` / `AirPortBrcmNIC-Tahoe`（SimpleBCM 方案不需要）
- 没有 `XHCI-unsupported.kext`（B360 的 xHCI 由系统原生驱动）

不要删除 `AMFIPass`、`SimpleBCM`、`SimpleHDA` 或 `boot-args` 里的
`amfi_get_out_of_my_way=1`、`-amfipassbeta`、`csr-active-config=0x0803` ——
它们是一整套契约，单独去掉会让 Wi-Fi / 音频失效。
