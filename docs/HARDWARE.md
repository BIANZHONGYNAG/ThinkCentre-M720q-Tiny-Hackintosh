# 硬件指纹与识别方法

`system_profiler SPHardwareDataType` 打印的是 OpenCore 注入出来的身份（`Macmini8,1`、
序列号、Hardware UUID），**不是**物理主板。判断真实机型要看 PCI 子系统 ID、LPC/PCH ID、
HDA codec、内存规格和 CPUID。

## 本机实测值

```
hw.model                     Macmini8,1            （伪装值，非真实机型）
board-id                     Mac-7BA5B2DFE22DDD8C  （Macmini8,1 的 board-id）
machdep.cpu.brand_string     Genuine Intel(R) CPU 0000 @ 1.70GHz
machdep.cpu.family/model    6 / 158   stepping 12     （Coffee Lake Refresh）
hw.ncpu                      16                    （8 核 16 线程）
hw.memsize                   34359738368           （32 GB）
IOHDACodecVendorID           283902517             （0x10EC0235 = ALC235）
```

## PCI ID 清单

```
pci17aa,312d   ×12   LENOVO 312D 主板子系统 ID
pci8086,a308         B360 LPC
pci8086,a352         SATA
pci8086,a348         HDEF（音频）
pci8086,a36d         xHCI（USB 控制器）
pci8086,a360 / a324 / a323 / a33d   芯片组其它功能
pci8086,3e30         iGPU 主机桥（UHD 630 为 3E98）
pci144d,a802         Samsung PM961 NVMe
pci14e4,43a0         Broadcom BCM4360
pci8086,1911         高斯混合模型（GMM）设备，不是 GPU，可以忽略
```

## 识别链

`17AA:312D` + B360 + SO-DIMM + ALC235 + 1L 机箱 = **Lenovo ThinkCentre M720q Tiny**。
不是 Mac mini，也不是 Z390 台式机；`Macmini8,1` 只是 OpenCore 选择的 SMBIOS 型号。

## 收集命令

```bash
# CPU
sysctl -n machdep.cpu.brand_string machdep.cpu.family machdep.cpu.model \
          machdep.cpu.stepping hw.ncpu hw.memsize

# PCI ID（ioreg 才是可信来源，SPPCIDataType 在黑苹果上常为空）
ioreg -l -w0 | grep -oE '"pci[0-9a-f]{4},[0-9a-f]{1,4}"' | sort | uniq -c | sort -rn

# 音频 codec（十进制，转十六进制）
ioreg -l -w0 | grep -o 'IOHDACodecVendorID" = [0-9]*'

# 内存
system_profiler SPMemoryDataType

# 存储 / 无线 / 蓝牙 / 显示
system_profiler SPNVMeDataType SPAirPortDataType SPBluetoothDataType SPDisplaysDataType

# USB（SPUSBDataType 为空不代表没有 USB，用 ioreg）
ioreg -p IOUSB -w0

# 已加载的第三方 kext
kmutil showloaded --list-only | grep -v com.apple
```

## 坑

- `SPPCIDataType` / `SPUSBDataType` 在黑苹果上可能返回空，`ioreg` 才是准的。
- `pci8086,1911` 是 GMM 设备，不是核显也不是第二颗 CPU。
- `17AA:312D` 出现在 `compatible` 里是 OEM 子系统 ID，不是芯片组的 PCI 厂商号。
- 不要靠 AppleALC 的注释猜 codec，一定用 `IOHDACodecVendorID` 反查。
