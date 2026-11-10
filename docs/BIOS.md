# BIOS 设置

ThinkCentre M720q 的 BIOS 是 Lenovo 商用机那套（`F1` 进 BIOS，`F12` 选启动项）。
不同 BIOS 版本的菜单层级略有差别，下面是需要改的项及原因。

## 必改项

| 菜单（参考路径） | 项目 | 设置 | 原因 |
|---|---|---|---|
| Startup | CSM Support / Legacy Boot | **Disabled** | 必须纯 UEFI。开着 CSM 时 OpenCore 可能拿不到 GOP，出现黑屏 |
| Startup | Boot Mode | **UEFI Only** | 同上 |
| Security → Secure Boot | Secure Boot | **Disabled** | 开着会拒绝加载未签名的 OpenCore |
| Advanced → CPU Setup | CFG Lock（MSR 0xE2） | **Disabled** | 本 EFI 没启用 `AppleXcpmCfgLock`，CFG Lock 打开会卡在 `apfs_module_start` 之前 |
| Advanced → CPU Setup | Intel Virtualization Technology | **Enabled** | 需要 VT-x；虚拟机/模拟器依赖 |
| Advanced → CPU Setup | CPU C-States | **Enabled** | SSDT-PLUG 依赖 C-State 才能做频率管理 |
| Startup → Boot Priority | 首选 EFI 分区 | 本机 ESP | 让 OpenCore 先起来 |

## 可保持默认

| 项目 | 说明 |
|---|---|
| VT-d | 开或关都可以，EFI 已启用 `Kernel/Quirks/DisableIoMapper=true`，会把 VT-d 对 macOS 屏蔽 |
| Hyper-Threading | 保持开启（本机 8C/16T 正常识别） |
| Fast Boot | 可开；若出现开机找不到引导再关掉 |
| 显存 / DVMT | M720q 的 DVMT 选项通常被隐藏，本机实测 `VRAM (Dynamic, Max): 1536 MB`，无需改动 |

## 关于 CFG Lock

`Kernel/Quirks/AppleXcpmCfgLock` 在本 EFI 里是 **false**。这意味着：

- 你的机器 CFG Lock 必须已经解锁（MSR 0xE2 可写），否则会启动失败；
- 如果你的机器是原厂状态没解锁，把 `AppleXcpmCfgLock` 改成 `true` 也能启动，
  代价是电源管理略有损失。

验证方法（开机后）：

```bash
# 能正常进系统且没有卡在 apfs_module_start，就说明 CFG 是解锁的
# 也可以查 EFI 里是否设了补丁：
/usr/libexec/PlistBuddy -c "Print :Kernel:Quirks:AppleXcpmCfgLock" /Volumes/EFI/EFI/OC/config.plist
```

## 启动顺序

1. 关机，插上装好 OpenCore 的 U 盘（或写好 ESP 的内置盘）
2. 开机按 `F12`，选 `UEFI: <你的盘>` 一次性启动，确认能进系统
3. 确认无误后，进 BIOS 把该 EFI 分区设为第一启动项
4. 以后开机直接进 OpenCore 选择器
