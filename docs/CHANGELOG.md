# 变更记录

## v1.0.0 — 2026-11-11

从真机 ESP 导出并发布。

- OpenCore 1.0.8（REL-108-2026-09-27）
- macOS 26 Tahoe 26.7.3（25G342）
- SMBIOS `Macmini8,1`，`UpdateSMBIOSMode=Custom` + `CustomSMBIOSGuid=true`
- 发布前脱敏：`SystemSerialNumber` / `MLB` → 占位值，`SystemUUID` → `OEM`，`ROM` → 空
- 删除 `EFI/APPLE/UPDATERS`（Apple 固件更新器，740 KB，黑苹果无用途）
- `ocvalidate 1.0.8`：No issues found

### 上一版增量（本机历史，2026-11-10）

**UUID 对齐修复**

现象：`IOPlatformUUID` 是主板固件里的 UUID，
而 `PlatformInfo/Generic/SystemUUID`、SMBIOS type-1 表、设备树 `system-id`
三者都是 OpenCore 生成的自定义 UUID。

原因：`UpdateSMBIOSMode=Custom` + `CustomSMBIOSGuid=true` 时，OpenCore 把生成的
SMBIOS 表写到 `gOcCustomSmbiosTableGuid`，并且只修补 `AppleSmbios.kext` /
`AppleACPIPlatform.kext` 去读这张表；`boot.efi` 未被修补，所以它仍然从固件原始
SMBIOS 表取 UUID，而 AppleSMBIOS 和设备树看到的是自定义表。

处理：把 `SystemUUID` 改成主板固件 UUID，即现在发布的 `OEM` 语义。
没有改成 `UpdateSMBIOSMode=Create`，因为那会更换硬件 UUID，导致 iCloud/iMessage
需要重新认证，也可能影响 Windows 双系统激活。

校验：`plutil -lint` OK；`ocvalidate 1.0.8` 无问题；与备份语义 diff 仅 1 个字段。

## 更早

- 2026-11-10：引入 SimpleHDA 1.0.1 恢复 Tahoe 音频（`layout-id 72`，ALC235）
- 2026-11-10：引入 SimpleBCM 1.2.0 替代 IOSkywalk 降级方案，`Kernel/Block` 清空
- 2026-11-09：USBToolBox + UTBMap 重做 USB 映射
- 2026-11-09：从 macOS Sequoia 升级到 Tahoe 26
