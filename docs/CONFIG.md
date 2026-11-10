# config.plist 详解

对应 OpenCore 1.0.8。所有值来自本机运行的 ESP，`ocvalidate 1.0.8` 校验无告警。

## SMBIOS（PlatformInfo）

```
SystemProductName     Macmini8,1
SystemSerialNumber    [REPLACE]       ← 必须自己生成，见 SMBIOS.md
MLB                   [REPLACE]       ← 必须自己生成
SystemUUID            OEM             ← 沿用固件 UUID
ROM                   （空）           ← 填 en0 的 MAC
ProcessorType         3841            （0x0F01，8 核 CPU 才显示 revcpuname）
Automatic             true
UpdateSMBIOSMode      Custom
CustomSMBIOSGuid      true
UpdateDataHub/NVRAM/SMBIOS  true
```

## 启动参数

```
boot-args = igfxagdc=0 vm_compressor=4 amfi_get_out_of_my_way=1 -amfipassbeta
csr-active-config = 0x0803      （SIP 部分关闭，AMFI 相关 kext 需要）
SecureBootModel = Disabled
Vault = Optional
```

| 参数 | 为什么 |
|---|---|
| `igfxagdc=0` | 关闭 AGDC，避免 iGPU + DP 音频下睡眠/唤醒异常 |
| `vm_compressor=4` | 指定内存压缩算法，本机实测稳定 |
| `amfi_get_out_of_my_way=1` | SimpleBCM / SimpleHDA 的二进制调用 `csr_check`，必须关 AMFI |
| `-amfipassbeta` | 让 AMFIPass 在 Tahoe 上启用 beta 路径 |

**安全代价**：`csr-active-config=0x0803` + `SecureBootModel=Disabled` 意味着关闭了
系统完整性保护与安全启动。这是 BCM4360 在 Tahoe 上的必然代价，不是配置失误。

## Booter Quirks

| 项 | 值 | 说明 |
|---|---|---|
| AvoidRuntimeDefrag | true | 修 runtime 内存碎片，必需 |
| DevirtualiseMmio | false | 本机保持关闭 |
| EnableSafeModeSlide | true | 安全模式可用 |
| EnableWriteUnprotector | true | 关闭 CR0 写保护，必需 |
| FixupAppleEfiImages | true | 修复部分 EFI 镜像签名检查 |
| ProvideCustomSlide | true | 内核 slide 随机化 |
| SetupVirtualMap | true | 建立虚拟内存映射 |
| ResizeAppleGpuBars | -1 | 不改 Resizable BAR |

## Kernel Quirks

| 项 | 值 | 说明 |
|---|---|---|
| CustomSMBIOSGuid | true | 配合 `UpdateSMBIOSMode=Custom` |
| DisableIoMapper | true | 屏蔽 VT-d 对 macOS 的影响 |
| DisableLinkeditJettison | true | 保持 Lilu 兼容（SimpleHDA 依赖） |
| PanicNoKextDump | true | 崩溃时不打印 kext 列表 |
| PowerTimeoutKernelPanic | true | 电源超时改为内核崩溃，便于定位 |
| SetApfsTrimTimeout | -1 | 不强制 TRIM 超时 |
| AppleXcpmCfgLock | **false** | 说明 CFG Lock 已在 BIOS 解锁 |

`Kernel/Block` 与 `Kernel/Patch` 都是空的 —— 这是 SimpleBCM 方案的正确形态。

## DeviceProperties

```
PciRoot(0x0)/Pci(0x2,0x0)          ← 核显
  AAPL,ig-platform-id  0x3e9b0007
  framebuffer-con0/1/2-*           三个连接器全部 type 0x00000800（DisplayPort）
  framebuffer-con0-busid  0x01 / con1-busid 0x02 / con2-busid 0x00

PciRoot(0x0)/Pci(0x1f,0x3)         ← HDA
  layout-id  0x48  (72, ALC235)

PciRoot(0x0)/Pci(0x14,0x0)         ← xHCI
  acpi-wake-type  0x01
```

`0x3e9b0007` 是 UHD 630 的 DP 帧缓冲；三个连接器都按 DP 配置，对应本机
DisplayPort 直出 4K@60。换 HDMI 输出需要改 `con*-type` 为 `0x00080000` 并调整 busid。

## ACPI（7 个 SSDT）

| 文件 | 作用 |
|---|---|
| SSDT-PLUG | CPU 电源管理（XCPM），让变频生效 |
| SSDT-EC | 补一个 EC 设备，缺了会报 `AppleACPIEC` 相关错 |
| SSDT-PMC | 恢复原生 NVRAM（300 系芯片组必需） |
| SSDT-SBUS | SBUS 设备，配合 SMBus 传感器 |
| SSDT-MCHC | 内存控制器设备 |
| SSDT-USBX | USB 供电属性（电流上限） |
| SSDT-RTCAWAC | 修正 AWAC RTC，避免时间跳变 |

`ACPI/Delete` 为空，不需要 Drop 任何原始表。

## Drivers（5 个）

| 文件 | 作用 |
|---|---|
| OpenRuntime.efi | OpenCore 必需，内存/启动服务 |
| apfs_aligned.efi | APFS 驱动（`UEFI/APFS/EnableJumpstart=false`，由它接管） |
| HfsPlus.efi | 读 HFS+ 分区（旧安装盘会用） |
| OpenCanopy.efi | 图形化选择器 |
| ResetNvramEntry.efi | 选择器里的「重置 NVRAM」项 |

## Misc

```
PickerMode      External        （OpenCanopy 图形选择器）
PickerVariant   chris1111\Flavours-macOS26
PickerAttributes 17
Timeout         5 秒
HideAuxiliary   true            （默认隐藏还原/清理等辅助项）
LauncherOption  Disabled        （不写 Boot#### 变量，避免污染固件启动项）
SecureBootModel Disabled
DmgLoading      Signed
BlacklistAppleUpdate true
Misc/Tools      CsrUtil.efi, OpenShell.efi
```

## NVRAM

写入的三个 GUID：

```
4D1EDE05-...-B38C14   DefaultBackgroundColor = 00000000
4D1FDA02-...-B30102   revcpu = 1
                      revcpuname = "Intel Core i9-9900T"
                      revpatch = cpuname
                      rtc-blacklist = （空）
7C436110-...-9F82     boot-args / csr-active-config / run-efi-updater=No / SystemAudioVolume
```

`revcpu`/`revcpuname` 是 RestrictEvents 的开关，作用是把「关于本机」里的
`Genuine Intel(R) CPU 0000` 换成 `Intel Core i9-9900T`。它只改用户态字符串，
`sysctl machdep.cpu.brand_string` 仍然是 ES 的原始串，这是正常的。

`WriteFlash = true` 才会把上面这些写进闪存；`NVRAM/Add` 只在变量不存在时写入，
所以改值后要先删旧变量（`sudo nvram -d <GUID>:<name>`）再重启。
