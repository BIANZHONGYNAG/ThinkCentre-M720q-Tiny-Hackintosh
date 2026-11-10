#!/bin/bash
# 校验 EFI：plist 语法、SMBIOS 占位、所有引用文件是否存在、可选的 ocvalidate
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CFG="$ROOT/EFI/OC/config.plist"
FAIL=0

say() { printf '%s\n' "$*"; }
ok()   { printf '  ✓ %s\n' "$*"; }
bad()  { printf '  ✗ %s\n' "$*"; FAIL=$((FAIL+1)); }

say "== 基本 =="
[ -f "$CFG" ] && ok "config.plist 存在" || bad "config.plist 缺失"

if plutil -lint "$CFG" >/dev/null 2>&1; then ok "plutil -lint 通过"; else bad "plutil -lint 失败"; fi

say "== SMBIOS =="
python3 - "$CFG" <<'PY'
import plistlib,sys
d=plistlib.load(open(sys.argv[1],'rb'))
g=d['PlatformInfo']['Generic']
for k in ('SystemProductName','SystemSerialNumber','MLB','SystemUUID','ROM'):
    v=g.get(k)
    if isinstance(v,bytes):
        print('  %-20s %s' % (k, v.hex() or '(空)'))
    else:
        print('  %-20s %s' % (k, v))
serial=g.get('SystemSerialNumber','')
if serial.startswith('[') or serial=='':
    print('  ! 序列号是占位值：iCloud/iMessage 不可用，见 docs/SMBIOS.md')
if not g.get('ROM'):
    print('  ! ROM 为空：需要填 en0 的 MAC')
PY

say "== 引用完整性 =="
python3 - "$CFG" "$ROOT/EFI/OC" <<'PY'
import plistlib,os,sys
cfg,oc=sys.argv[1],sys.argv[2]
d=plistlib.load(open(cfg,'rb'))
missing=[]; checked=0
for e in d['ACPI']['Add']:
    if e.get('Enabled'):
        p=os.path.join(oc,'ACPI',e['Path']); checked+=1
        if not os.path.exists(p): missing.append(p)
for e in d['Kernel']['Add']:
    if e.get('Enabled'):
        p=os.path.join(oc,'Kexts',e['BundlePath']); checked+=1
        if not os.path.exists(p): missing.append(p)
        exe=e.get('ExecutablePath','')
        if exe:
            p=os.path.join(oc,'Kexts',e['BundlePath'],exe); checked+=1
            if not os.path.exists(p): missing.append(p)
for e in d['UEFI']['Drivers']:
    if e.get('Enabled'):
        p=os.path.join(oc,'Drivers',e['Path']); checked+=1
        if not os.path.exists(p): missing.append(p)
for e in d['Misc']['Tools']:
    if e.get('Enabled'):
        p=os.path.join(oc,'Tools',e['Path']); checked+=1
        if not os.path.exists(p): missing.append(p)
print('  检查 %d 个路径' % checked)
if missing:
    for m in missing: print('  ✗ 缺失', m)
    sys.exit(3)
print('  ✓ 全部存在')
PY
[ $? -eq 3 ] && FAIL=$((FAIL+1))

say "== ocvalidate =="
OCV="$(command -v ocvalidate || true)"
[ -x "$ROOT/tools/ocvalidate" ] && OCV="$ROOT/tools/ocvalidate"
if [ -n "$OCV" ]; then
  "$OCV" "$CFG" 2>&1 | tail -5
else
  say "  未找到 ocvalidate（把它放到 tools/ 或 PATH 里再跑一次）"
fi

say "== 大小 =="
BYTES=$(find "$ROOT/EFI" -type f -exec stat -f '%z' {} \; | awk '{s+=$1} END {print s}')
say "  EFI: $(find "$ROOT/EFI" -type f | wc -l | tr -d ' ') 个文件, $BYTES 字节"

say ""
[ "$FAIL" -eq 0 ] && say "结果：通过" || say "结果：$FAIL 项需要处理"
exit "$FAIL"
