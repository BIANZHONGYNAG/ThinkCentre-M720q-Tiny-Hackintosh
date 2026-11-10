# SMBIOS：生成属于你自己的序列号

发布版 `config.plist` 里这四项是占位值：

```
PlatformInfo/Generic/SystemSerialNumber   [REPLACE]
PlatformInfo/Generic/MLB                  [REPLACE]
PlatformInfo/Generic/SystemUUID           OEM
PlatformInfo/Generic/ROM                  （空）
```

**用别人的序列号会有两个后果**：iCloud / iMessage 可能因为「序列号被多台设备占用」被锁，
而且原机主没法再用。所以一定要生成你自己的。

## 一、生成序列号

`macserial` 随 OpenCore 发布包提供（`Utilities/macserial`），也可以用 GenSMBIOS 脚本。

```bash
# 下载 OpenCore 1.0.8 RELEASE，解压出 macserial
# 若 github.com 打不开，用 API 拉：
curl -fL -H 'Accept: application/octet-stream' \
  -o oc.zip https://api.github.com/repos/acidanthera/OpenCorePkg/releases/assets/<ASSET_ID>
unzip -q oc.zip -d oc
chmod +x oc/Utilities/macserial/macserial

# 生成 5 组 Macmini8,1 的序列号，格式为：序列号 | MLB
./oc/Utilities/macserial/macserial -m Macmini8,1 | head -5
```

输出示例（**不要直接用这三行，它们已被公开**）：

```
C07WL0XYJYVX | C07816310J9KXPG8C
C07CPQZQJYVX | C07019701GUKXPG8C
C07DP00EJYVX | C07046108J9KXPG1H
```

左边填 `SystemSerialNumber`，右边填 `MLB`。

## 二、填 ROM

`ROM` 是网卡的 MAC 地址（6 字节），macOS 用它做 iMessage 的硬件校验。
用你的 en0（有线网卡）MAC，去掉冒号：

```bash
ifconfig en0 | grep ether
# ether a4:bb:6d:11:22:33
# ROM = a4bb6d112233
```

在 config.plist 里是 `<data>` 类型：

```xml
<key>ROM</key>
<data>pLttESIz</data>
```

用 `plutil` 或 ProperTree 改，别手写 base64 容易错。Python 一行：

```bash
python3 - <<'EOF'
import plistlib, subprocess
mac = subprocess.check_output(['ifconfig','en0']).decode()
hexmac = [l.split()[1] for l in mac.splitlines() if 'ether' in l][0].replace(':','')
p = 'EFI/OC/config.plist'
d = plistlib.load(open(p,'rb'))
d['PlatformInfo']['Generic']['ROM'] = bytes.fromhex(hexmac)
plistlib.dump(d, open(p,'wb'), fmt=plistlib.FMT_XML)
print('ROM =', hexmac)
EOF
```

## 三、SystemUUID

三种取值：

| 值 | 含义 | 适用 |
|---|---|---|
| `OEM` | 沿用主板固件里的 UUID | **本机采用**，Windows 双系统激活不受影响 |
| 空 | OpenCore 自动生成 | 简单，但换配置就变 |
| 一个 UUID | 固定值 | 需要跨重装保持同一硬件 UUID 时 |

本机用 `OEM` 的原因：`UpdateSMBIOSMode=Custom` 下 `boot.efi` 不读自定义 SMBIOS 表，
`IOPlatformUUID` 取的是固件原值；写死一个自定义 UUID 会导致「系统报告里的 UUID 与实际
运行 UUID 不一致」。详见 [CHANGELOG.md](CHANGELOG.md)。

## 四、验证

```bash
# 1. 语法与结构
plutil -lint EFI/OC/config.plist

# 2. OpenCore 官方校验（从 1.0.8 发布包里取 ocvalidate，版本必须对应）
./oc/Utilities/ocvalidate/ocvalidate EFI/OC/config.plist
# 期望：No issues found

# 3. 写入后重启，确认三处一致
system_profiler SPHardwareDataType | grep -E 'Serial Number|Hardware UUID'
ioreg -l | grep IOPlatformSerialNumber
nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version
```

## 五、注意

- `Automatic=true` 在 `UpdateSMBIOSMode=Custom` 下**不会**自动生成序列号，
  必须手填，否则 iCloud 必失败。
- 别把 `SystemProductName` 改别的：`Macmini8,1` 是这台机器唯一验证过的机型，
  换机型要同步改核显 `AAPL,ig-platform-id` 和 USB 映射。
- 序列号、MLB、ROM 三件套是对应关系，不要拆开混用不同机器生成的值。
