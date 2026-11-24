# Lenovo ThinkCentre M720q Tiny (1L) 黑苹果 OpenCore EFI

面向 **Lenovo ThinkCentre M720q Tiny (1L)** 的 OpenCore 黑苹果 EFI 引导配置，目标系统为 **macOS 26 Tahoe**。

## 硬件支持

| 硬件 | 型号 |
| --- | --- |
| CPU | Intel Core i9-9900T |
| 核显 | Intel UHD 630 |
| 声音 | Realtek ALC235 |
| 无线网卡 | Broadcom BCM4360 |
| BIOS 类型 | 1 代款 mini 台式机（ThinkCentre M720q Tiny 1L） |

> 说明：仓库不包含针帽/背光/指纹等接口支持，以下为已验证可用组件。

## 目录结构

```
EFI/
├── BOOT/
│   └── BOOTx64.efi          # 引导入口
├── OC/
│   ├── OpenCore.efi         # OpenCore 核心
│   ├── config.plist         # 引导配置（SMBIOS、引导参数等）
│   ├── ACPI/                  # 修正 ACPI
│   ├── Drivers/               # 引导驱动
│   ├── Kexts/                 # macOS 启动后内核扩展
│   ├── Tools/                 # 工具
│   └── Resources/             # 字体/图标/画面文本等
```

## 关键配置

### 系统信息（`EFI/OC/config.plist` > SMBIOS）

本仓库使用 **Macmini8,1** SMBIOS 运行，当前配置如下：

| 键 | 值 |
| --- | --- |
| SystemProductName | Macmini8,1 |
| SystemSerialNumber | C07ZMWZ2JYVX |
| SystemUUID | B9FDEE37-F5ED-5061-95C0-0B462E6E8792 |
| ROM | VAXb8tQq |
| SpoofVendor | true |
| SystemMemoryStatus | Auto |

> 更换机型或电脑后，建议同步更新 `SystemUUID`、`ROM` 与 `SerialNumber`，并在 `UpdateSMBIOS` 开启后让 OpenCore 自动刷写。

### 引导参数

`config.plist` > `Kernel -> Arguments`：

```
igfxagdc=0 vm_compressor=4 amfi_get_out_of_my_way=1 -amfipassbeta brcmfx-country=CN
```

> 常用含义：
> - `amfi_get_out_of_my_way=1`：打开 AMFI 旁路（黑苹果必需）
> - `brcmfx-country=CN`：Broadcom 无线国家码（中国）
> - `igfxagdc=0`：Intel 核显输出控制

### 无线网卡（BCM4360）

安装了以下内核扩展以支持 BCM4360 网卡与触控板：

- `AirportBrcmFixup.kext`：修复 Broadcom WX 阵列
- `BlueToolFixup.kext`：修复 BlueTool / 触控板辨识
- `BrcmFirmwareData.kext`：注入固件数据

## 安装

1. 将 `EFI` 目录完整复制到目标硬盘的 `EFI` 磁盘分区（ESP）；
2. 在 BIOS 中将启动选项设置为 UEFI，从 `EFI/BOOT/BOOTx64.efi` 引导；
3. 系统进入后打开「系统设置 > 蓝牙」配对无线网卡与触控板。

## 更新与备份

- 更新前务必备份 `EFI` 目录（尤其是 `config.plist`）；
- 升级 macOS 后，重新生成或核对 `SystemUUID`、`ROM` 与 `SerialNumber`，避免引导异常；
- 更换主板或 BIOS 版本前，先备份当前 `EFI`，恢复后再刷入。

## 维护者

- GitHub: [@BIANZHONGYNAG](https://github.com/BIANZHONGYNAG)
