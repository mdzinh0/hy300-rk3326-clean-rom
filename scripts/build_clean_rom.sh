#!/usr/bin/env bash
set -euo pipefail

STOCK_SYSTEM_SHA=288103dfcffd322c403e7f9e9d941c9ac0ee2473e42adc1e2cfb6178ef944711
STOCK_OEM_SHA=8e2cf6a7cc20da957208c26f6d6df7940064e5981424c935ad5568734c391787

usage() {
  cat <<EOF
Uso: sudo $0 -s <system_stock.img> -o <oem_stock.img> -d <pasta_saida> [-l <launcher.apk>] [-n] [-f]
  -s  dump da partição system de fábrica
  -o  dump da partição oem de fábrica
  -d  pasta de saída (recebe system.img, oem.img e SHA256SUMS)
  -l  APK de launcher (opcional): remove o txcz_launcher e instala o APK em /system/priv-app
  -n  não zerar os blocos livres (pula o zerofree)
  -f  continuar mesmo se os dumps forem diferentes do firmware de referência
EOF
  exit 1
}

SYS_IN="" OEM_IN="" OUT="" APK="" ZERO=1 FORCE=0
while getopts "s:o:d:l:nfh" opt; do
  case $opt in
    s) SYS_IN=$OPTARG ;;
    o) OEM_IN=$OPTARG ;;
    d) OUT=$OPTARG ;;
    l) APK=$OPTARG ;;
    n) ZERO=0 ;;
    f) FORCE=1 ;;
    *) usage ;;
  esac
done
[ -n "$SYS_IN" ] && [ -n "$OEM_IN" ] && [ -n "$OUT" ] || usage
[ "$(id -u)" -eq 0 ] || { echo "ERRO: rode como root (sudo)"; exit 1; }
[ -f "$SYS_IN" ] || { echo "ERRO: $SYS_IN não encontrado"; exit 1; }
[ -f "$OEM_IN" ] || { echo "ERRO: $OEM_IN não encontrado"; exit 1; }
if [ -n "$APK" ]; then
  [ -f "$APK" ] || { echo "ERRO: $APK não encontrado"; exit 1; }
  [ "$(head -c 2 "$APK")" = "PK" ] || { echo "ERRO: $APK não parece um APK"; exit 1; }
fi
TOOLS="mount umount mountpoint e2fsck python3 sha256sum getfattr setfattr"
[ "$ZERO" -eq 1 ] && TOOLS="$TOOLS zerofree"
for t in $TOOLS; do
  command -v "$t" >/dev/null || { echo "ERRO: falta '$t' (Debian/Ubuntu: apt install e2fsprogs attr zerofree python3)"; exit 1; }
done

echo "==> 1. Conferindo os dumps de fábrica"
MISMATCH=0
for pair in "$SYS_IN:$STOCK_SYSTEM_SHA" "$OEM_IN:$STOCK_OEM_SHA"; do
  f=${pair%:*}; ref=${pair##*:}
  h=$(sha256sum "$f" | cut -d' ' -f1)
  if [ "$h" = "$ref" ]; then echo "OK     $(basename "$f") = firmware de referência"
  else echo "AVISO  $(basename "$f") difere do firmware de referência ($h)"; MISMATCH=1; fi
done
if [ "$MISMATCH" -eq 1 ] && [ "$FORCE" -eq 0 ]; then
  echo "ERRO: dumps diferentes do firmware analisado. Use -f para continuar por sua conta."
  exit 1
fi

echo "==> 2. Copiando para $OUT"
mkdir -p "$OUT"
cp --sparse=always -f "$SYS_IN" "$OUT/system.img"
cp --sparse=always -f "$OEM_IN" "$OUT/oem.img"

MS=$(mktemp -d); MO=$(mktemp -d)
cleanup() {
  mountpoint -q "$MS" && umount "$MS"
  mountpoint -q "$MO" && umount "$MO"
  rmdir "$MS" "$MO" 2>/dev/null || true
}
trap cleanup EXIT
mount -o rw,loop "$OUT/system.img" "$MS"
mount -o rw,loop "$OUT/oem.img" "$MO"
S="$MS/system"

rmv() {
  if [ -e "$1" ]; then rm -rf "$1"; echo "removido  ${1#"$2"}"; else echo "ausente   ${1#"$2"}"; fi
}

echo "==> 3. Removendo root persistente (system/xbin)"
for f in su daemonsu supolicy procmem; do rmv "$S/xbin/$f" "$MS"; done

echo "==> 4. Removendo apps do fabricante"
for a in txczbox txczota txcz_app txcztest GetApp RKUpdateService; do rmv "$S/app/$a" "$MS"; done
rmv "$S/priv-app/StressTest" "$MS"

echo "==> 5. Removendo adware da partição oem"
for d in "$MO"/bundled_persist-app/TXCZTVApp_*; do
  if [ -e "$d" ]; then rmv "$d" "$MO"; fi
done
rmv "$MO/bundled_uninstall_back-app/Youtubu_tv" "$MO"

echo "==> 6. Editando init.usb.rc, prop.default e build.prop (in-place, preserva rótulo SELinux)"
python3 - "$MS" <<'PY'
import sys
root = sys.argv[1]

def edit(rel, pairs, append=None):
    path = root + rel
    with open(path, 'r+b') as f:
        old = f.read()
        new = old
        for a, b in pairs:
            if a in new:
                new = new.replace(a, b)
                print(f'{rel}: {a.decode().strip()} -> {b.decode().strip()}')
            elif b in new:
                print(f'{rel}: já aplicado: {b.decode().strip()}')
            else:
                sys.exit(f'ERRO: {rel}: trecho não encontrado: {a.decode().strip()}')
        if append and append not in new:
            if not new.endswith(b'\n'):
                new += b'\n'
            new += append
            print(f'{rel}: adicionado {append.decode().strip()}')
        if new != old:
            f.seek(0)
            f.write(new)
            f.truncate()

edit('/init.usb.rc',
     [(b'service adbd /system/bin/adbd --root_seclabel=u:r:su:s0', b'service adbd /system/bin/adbd')])
edit('/system/etc/prop.default',
     [(b'ro.debuggable=1', b'ro.debuggable=0'),
      (b'persist.sys.usb.config=adb', b'persist.sys.usb.config=mtp')],
     append=b'ro.adb.secure=1\n')
edit('/system/build.prop',
     [(b'\nservice.adb.tcp.port=5555', b'\n#service.adb.tcp.port=5555')])
PY

if [ -n "$APK" ]; then
  echo "==> 7. Instalando launcher $(basename "$APK")"
  NAME=$(basename "$APK" .apk | tr -cd 'A-Za-z0-9_.-')
  [ -n "$NAME" ] || NAME=CustomLauncher
  rmv "$S/app/txcz_launcher" "$MS"
  D="$S/priv-app/$NAME"
  mkdir -p "$D"
  cp -f "$APK" "$D/$NAME.apk"
  chown -R 0:0 "$D"
  chmod 755 "$D"
  chmod 644 "$D/$NAME.apk"
  label() { { getfattr -h -e hex -n security.selinux "$1" 2>/dev/null || true; } | sed -n 's/^security\.selinux=//p'; }
  LDIR=$(label "$S/priv-app/Settings")
  LAPK=$(label "$S/priv-app/Settings/Settings.apk")
  [ -n "$LDIR" ] && [ -n "$LAPK" ] || { echo "ERRO: não foi possível ler o rótulo SELinux de referência"; exit 1; }
  setfattr -h -n security.selinux -v "$LDIR" "$D"
  setfattr -h -n security.selinux -v "$LAPK" "$D/$NAME.apk"
  [ "$(label "$D")" = "$LDIR" ] && [ "$(label "$D/$NAME.apk")" = "$LAPK" ] \
    || { echo "ERRO: rótulo SELinux não aplicado"; exit 1; }
  echo "rótulo SELinux aplicado em /system/priv-app/$NAME"
else
  echo "==> 7. Sem launcher extra: txcz_launcher mantido"
fi

echo "==> 8. Desmontando e checando o sistema de arquivos"
sync
umount "$MS"; umount "$MO"
for img in system oem; do
  rc=0; e2fsck -fy "$OUT/$img.img" >/dev/null 2>&1 || rc=$?
  [ "$rc" -le 1 ] || { echo "ERRO: e2fsck $img.img rc=$rc"; exit 1; }
  if [ "$ZERO" -eq 1 ]; then zerofree "$OUT/$img.img"; fi
  rc=0; e2fsck -fn "$OUT/$img.img" >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 0 ] || { echo "ERRO: e2fsck -fn $img.img rc=$rc"; exit 1; }
  echo "OK     $img.img íntegro"
done

echo "==> 9. SHA256"
(cd "$OUT" && sha256sum system.img oem.img | tee SHA256SUMS)
echo "Pronto. Grave só system.img e oem.img (veja o README)."
