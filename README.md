# ThinkCentre M720q Tiny 黑苹果（OpenCore）

Lenovo ThinkCentre M720q Tiny（1L 小主机）+ Intel Core i9-9900T 的 OpenCore 引导配置，
当前运行 **macOS 26 Tahoe (26.7.3 / 25G342)**，OpenCore **1.0.8**（REL-108-2026-09-27）。

本项目由真机导出：EFI 与 `config.plist` 直接从该机 ESP 复制并脱敏，不是拼凑的模板；
下面「功能状态」一栏全部基于开机状态下的实测输出，未验证的项目会明确标注。

> **发布版与真机的唯一差别是 SMBIOS 三件套**（SystemSerialNumber / MLB / SystemUUID / ROM），
> 已替换为占位值。直接拿来开机可以进系统，但 iCloud / iMessage / App Store 登录会失败，
> 必须按 [docs/SMBIOS.md](docs/SMBIOS.md) 生成自己的序列号。**不要使用他人序列号。**

---

## 一、硬件配置

| 部件 | 型号 / 参数 | 备注 |
|---|---|---|
| 机型 | Lenovo ThinkCentre M720q Tiny（1L） | 主板 `LENOVO 312D`，`17AA:312D` |
| 芯片组 | Intel B360 | LPC `8086:A308`，SATA `A352`，HDA `A348`，xHCI `A36D` |
| CPU | Intel Core i9-9900T（ES/QS，QQCO） | 8 核 16 线程，1.7 GHz 基准 / 35 W，CPUID `6/158/12` |
| 核显 | Intel UHD Graphics 630 | `8086:3E98`，DVMT 1536 MB，Metal 3 |
| 内存 | 2 × 16 GB DDR4-2133 SO-DIMM | SK Hynix `HMA82GS6MFR8N-TF`，32 GB |
| 硬盘 | Samsung `MZVPV128HDGM-000L1`（PM961 128 GB） | NVMe PCIe 3.0 x4，`144D:A802` |
| 音频 | Realtek ALC235 | codec `0x10EC0235`，`layout-id = 72` |
| 有线网卡 | Intel I219-V | `8086:15BC` |
| 无线网卡 | Broadcom BCM4360 | `14E4:43A0`，macOS 报告为 `BCM17248`，802.11ac |
| 蓝牙 | Broadcom BCM20702（USB） | 与 Wi-Fi 同一模块 |
| 显示输出 | DisplayPort → Lenovo S28u-10 | 3840×2160 @ 60 Hz，30-bit |

CPU 是工程样品（ES/QS），`sysctl machdep.cpu.brand_string` 只会输出
`Genuine Intel(R) CPU 0000 @ 1.70GHz`；系统信息里显示的 `Intel Core i9-9900T`
是 RestrictEvents 的 `revcpuname` 补丁改的上层字符串，不是 CPUID 真的变了。

## 二、功能状态（实测）

| 功能 | 状态 | 证据 |
|---|---|---|
| 启动 / 引导 | ✅ | OpenCore 1.0.8，`ocvalidate` 无告警 |
| 核显加速 | ✅ | Metal 3，UHD 630，4K@60 输出正常 |
| 音频输出 | ✅ | 内建输出（内置扬声器）+ DisplayPort |
| 音频输入 | ✅ | 内建输入（外置麦克风） |
| 有线网络 | ✅ | I219-V 走 IntelMausiEthernet，en0 |
| 无线网络 | ✅ | en1，802.11ac 5 GHz，已连接 |
| 蓝牙 | ✅ | BCM20702，状态 On，键盘/接收器可用 |
| USB | ✅ | USBToolBox + UTBMap 定制映射 |
| NVMe / TRIM | ✅ | SMART Verified，TRIM 支持 |
| CPU 电源管理 | ✅ | SSDT-PLUG + SMCProcessor / SMCSuperIO |
| 睡眠 / 唤醒 | ⚠️ 未验证 | `hibernatemode 3`、`standby 1` 已配置，本次会话没有做唤醒测试 |
| 隔空投送 / 接力 | ⚠️ 依赖 SMBIOS | BCM4360 原生卡，系统报告 AirDrop 为 Supported |
| iCloud / iMessage | ⚠️ 需自签 | 发布版序列号为占位值，必须自行生成 |

## 三、快速开始

```bash
# 1. 克隆
git clone https://github.com/<你的用户名>/ThinkCentre-M720q-Tiny-Hackintosh.git
cd ThinkCentre-M720q-Tiny-Hackintosh

# 2. 生成你自己的 SMBIOS（Macmini8,1），填入 EFI/OC/config.plist
#    见 docs/SMBIOS.md

# 3. 备份现有 ESP，再写入（脚本会先备份到 ~/efi-backups/）
./scripts/backup-efi.sh
sudo diskutil mount disk0s1
cp -R EFI/* /Volumes/EFI/EFI/
sudo diskutil unmount /Volumes/EFI

# 4. 重启
```

**首次使用请务必先备份**：`scripts/backup-efi.sh` 会把当前 ESP 完整复制到
`~/efi-backups/EFI-<时间戳>`，出问题可以原样拷回。

## 四、BIOS 设置

详见 [docs/BIOS.md](docs/BIOS.md)。关键项：

- CSM / Legacy Boot：关闭（纯 UEFI）
- Secure Boot：关闭
- CFG Lock（MSR 0xE2 写保护）：关闭 —— 本 EFI 未启用 `AppleXcpmCfgLock`，打开 CFG Lock 会卡在启动
- VT-d：可保持开启（EFI 已启用 `DisableIoMapper`）
- 显存 / DVMT：1536 MB（BIOS 中通常隐藏，M720q 可 64 MB 起步，本机实测 1536 MB）
- 启动顺序：先 EFI 分区，再其它

## 五、EFI 结构

```
EFI/
├── BOOT/BOOTx64.efi              # 引导入口
└── OC/
    ├── OpenCore.efi              # 1.0.8 RELEASE
    ├── config.plist              # 已脱敏，需填 SMBIOS
    ├── ACPI/                     # 7 个 SSDT
    ├── Drivers/                  # apfs_aligned / HfsPlus / OpenRuntime / OpenCanopy / ResetNvramEntry
    ├── Kexts/                    # 14 个 kext
    ├── Resources/                # OpenCanopy 主题（Font / Image / Label）
    └── Tools/                    # CsrUtil.efi / OpenShell.efi
```

逐项说明见 [docs/KEXTS.md](docs/KEXTS.md) 与 [docs/CONFIG.md](docs/CONFIG.md)。

## 六、已知问题

1. **SMBIOS 占位值**：不填序列号能开机，但 iCloud / iMessage 不可用。
2. **`SystemUUID` 与固件 UUID 的关系**：本机采用 `UpdateSMBIOSMode=Custom` +
   `CustomSMBIOSGuid`，`boot.efi` 不读自定义表，所以 `IOPlatformUUID` 取的是主板原本的
   UUID。发布版把 `SystemUUID` 设为 `OEM`（沿用固件值），这是这台机器最终采用的方案；
   若改成 `Create` 会更换硬件 UUID，需要重新登录 iCloud。详见 [docs/CHANGELOG.md](docs/CHANGELOG.md)。
3. **第四代 OpenCanopy 主题**：`Resources/Image` 里的主题素材（`chris1111\Flavours-macOS26`）
   版权归其作者，本项目仅作个人使用打包；如需再分发请先确认授权，或把
   `Misc/Boot/PickerVariant` 改回 `Default`。
4. **ES/QS CPU**：`Processor Name` 靠补丁显示，更换 CPU 后需重新设置 `revcpuname`。

## 七、免责声明

- 本项目只提供配置文件与引导程序，**不包含任何 Apple 版权文件**（macOS 安装镜像请自行获取）。
- 在非 Apple 硬件上安装 macOS 违反 Apple 的最终用户许可协议（EULA），风险自负。
- 修改 ESP 有导致无法开机的风险。请始终保留备份与一个可启动的 U 盘。
- 本项目按 MIT 协议发布（见 [LICENSE](LICENSE)）。OpenCore、各 kext 遵循其自身协议，
  版权归原作者所有。

## 八、致谢

- [Acidanthera](https://github.com/acidanthera)：OpenCore、Lilu、VirtualSMC、WhateverGreen、AppleALC、RestrictEvents、NVMeFix
- [laobamac](https://github.com/laobamac)：SimpleBCM（Tahoe 下替代 IOSkywalk 方案）、SimpleHDA（Tahoe 下恢复 AppleHDA）
- [dhinakg](https://github.com/dhinakg)：AMFIPass、USBToolBox
- [insanelymac]：IntelMausiEthernet
- [chris1111](https://github.com/chris1111)：Flavours-macOS26 主题
- [Dortania](https://dortania.github.io/OpenCore-Install-Guide/)：安装指南
