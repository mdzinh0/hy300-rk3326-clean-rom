#!/usr/bin/env bash
set -uo pipefail

DIR=${1:-}
[ -n "$DIR" ] && [ -f "$DIR/system.img" ] && [ -f "$DIR/oem.img" ] || { echo "Uso: sudo $0 <pasta com system.img e oem.img>"; exit 1; }
[ "$(id -u)" -eq 0 ] || { echo "ERRO: rode como root (sudo)"; exit 1; }

FAILS=0
ok()   { echo "OK     $*"; }
fail() { echo "FALHA  $*"; FAILS=$((FAILS + 1)); }
chk()  { if eval "$2"; then ok "$1"; else fail "$1"; fi; }

for img in system oem; do
  rc=0; e2fsck -fn "$DIR/$img.img" >/dev/null 2>&1 || rc=$?
  chk "e2fsck $img.img sem erros" "[ $rc -eq 0 ]"
done

MS=$(mktemp -d); MO=$(mktemp -d)
cleanup() { umount "$MS" "$MO" 2>/dev/null; rmdir "$MS" "$MO" 2>/dev/null; }
trap cleanup EXIT
mount -o ro,noload,loop "$DIR/system.img" "$MS" || { echo "ERRO ao montar system.img"; exit 1; }
mount -o ro,noload,loop "$DIR/oem.img" "$MO" || { echo "ERRO ao montar oem.img"; exit 1; }
S="$MS/system"

for f in su daemonsu supolicy procmem; do chk "ausente /system/xbin/$f" "[ ! -e '$S/xbin/$f' ]"; done
SUID=$(find "$MS" -xdev -type f \( -perm -4000 -o -perm -2000 \) | wc -l)
chk "nenhum binário setuid/setgid em system ($SUID)" "[ $SUID -eq 0 ]"
for a in app/txczbox app/txczota app/txcz_app app/txcztest app/GetApp app/RKUpdateService priv-app/StressTest; do
  chk "ausente /system/$a" "[ ! -e '$S/$a' ]"
done
N=$(find "$MO/bundled_persist-app" -maxdepth 1 -name 'TXCZTVApp_*' 2>/dev/null | wc -l)
chk "ausente /oem/bundled_persist-app/TXCZTVApp_*" "[ $N -eq 0 ]"
chk "ausente /oem/bundled_uninstall_back-app/Youtubu_tv" "[ ! -e '$MO/bundled_uninstall_back-app/Youtubu_tv' ]"

chk "init.usb.rc: adbd sem --root_seclabel" "grep -qx 'service adbd /system/bin/adbd' '$MS/init.usb.rc' && ! grep -q root_seclabel '$MS/init.usb.rc'"
P="$S/etc/prop.default"
chk "prop.default: ro.debuggable=0" "grep -qx 'ro.debuggable=0' '$P'"
chk "prop.default: persist.sys.usb.config=mtp" "grep -qx 'persist.sys.usb.config=mtp' '$P'"
chk "prop.default: ro.adb.secure=1" "grep -qx 'ro.adb.secure=1' '$P'"
chk "build.prop: ADB por rede (5555) desligado no boot" "! grep -qE '^service\.adb\.tcp\.port=' '$S/build.prop'"

UNL=$(python3 - "$MS" "$MO" <<'PY'
import os, sys
missing = []
for root in sys.argv[1:]:
    for d, dirs, files in os.walk(root):
        for n in [''] + dirs + files:
            p = os.path.join(d, n) if n else d
            try:
                os.getxattr(p, 'security.selinux', follow_symlinks=False)
            except OSError:
                missing.append(p.replace(root, ''))
print(len(missing))
for m in missing[:20]:
    print(m, file=sys.stderr)
PY
)
chk "todos os arquivos com rótulo SELinux (sem rótulo: $UNL)" "[ '$UNL' = '0' ]"

if [ -d "$S/app/txcz_launcher" ]; then
  echo "INFO   launcher: txcz_launcher (de fábrica) presente"
else
  EXTRA=$(find "$S/app" "$S/priv-app" -mindepth 1 -maxdepth 1 -newermt 2010-01-01 | sed "s#$MS##" | tr '\n' ' ')
  echo "INFO   launcher: txcz_launcher removido; adicionados: ${EXTRA:-nenhum}"
  [ -n "$EXTRA" ] || fail "nenhum launcher instalado no lugar do txcz_launcher"
fi

umount "$MS" "$MO"
echo "--- SHA256 ---"
(cd "$DIR" && sha256sum system.img oem.img)
echo "Resultado: $FAILS falha(s)"
[ "$FAILS" -eq 0 ]
