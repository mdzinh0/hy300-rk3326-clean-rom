#!/usr/bin/env bash
# ==============================================================================
# Script de Backup Seguro de Particoes (system e oem) - HY300 RK3326
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}=================================================================${NC}"
echo -e "${CYAN}             BACKUP DE SEGURANCA - PROJETOR HY300               ${NC}"
echo -e "${CYAN}=================================================================${NC}"

ADB=""
if command -v adb >/dev/null 2>&1; then
    ADB="adb"
elif [ -f "/mnt/c/adb/adb.exe" ]; then
    ADB="/mnt/c/adb/adb.exe"
fi

if [ -z "$ADB" ]; then
    echo -e "${RED}[ERRO] adb nao encontrado.${NC}"
    exit 1
fi

DEVICE=$("$ADB" devices | grep -w "device" | head -n 1 | awk '{print $1}' || true)
if [ -z "$DEVICE" ]; then
    read -rp "Digite o IP do projetor na rede WiFi (ex: 192.168.1.150): " IP
    if [ -n "$IP" ]; then
        "$ADB" connect "$IP:5555" >/dev/null 2>&1 || true
        sleep 2
        DEVICE=$("$ADB" devices | grep -w "device" | head -n 1 | awk '{print $1}' || true)
    fi
fi

if [ -z "$DEVICE" ]; then
    echo -e "${RED}[ERRO] Nao foi possivel conectar ao projetor.${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] Conectado a $DEVICE${NC}"

OUT="$(dirname "$0")/../backup"
mkdir -p "$OUT"
OUT=$(cd "$OUT" && pwd)
echo -e "${CYAN}[INFO] Backups serao salvos em: $OUT${NC}"

su_cmd() {
    "$ADB" -s "$DEVICE" shell "su 0 -c '$1'"
}

backup_part() {
    NAME=$1
    NODE=$2
    FILE=$3
    DEST="$OUT/$FILE"

    echo "-----------------------------------------------------------------"
    echo -e "${YELLOW}Iniciando backup: $NAME ($NODE)${NC}"
    echo "1. Extraindo no aparelho..."
    su_cmd "dd if=$NODE of=/data/local/tmp/$FILE bs=1048576 && chmod 644 /data/local/tmp/$FILE" >/dev/null
    
    echo "2. Calculando SHA256 no aparelho..."
    DEV_HASH=$(su_cmd "sha256sum /data/local/tmp/$FILE" | awk '{print $1}')

    echo "3. Baixando para o PC..."
    "$ADB" -s "$DEVICE" pull "/data/local/tmp/$FILE" "$DEST" >/dev/null

    echo "4. Limpando temporarios..."
    su_cmd "rm -f /data/local/tmp/$FILE" >/dev/null

    echo "5. Verificando integridade local..."
    LOC_HASH=$(sha256sum "$DEST" | awk '{print $1}')

    if [ "$DEV_HASH" = "$LOC_HASH" ]; then
        echo -e "${GREEN}[OK] Sucesso! Hash: $LOC_HASH${NC}"
    else
        echo -e "${RED}[FALHA] Hash divergente!${NC}"
        echo "Dev: $DEV_HASH"
        echo "Loc: $LOC_HASH"
    fi
}

backup_part "system" "/dev/block/mmcblk2p13" "system_original.img"
backup_part "oem" "/dev/block/mmcblk2p16" "oem_original.img"

echo ""
echo -e "${GREEN}=================================================================${NC}"
echo -e "${GREEN}              BACKUP FINALIZADO COM SUCESSO!                     ${NC}"
echo -e "${GREEN}=================================================================${NC}"
echo "Salvo em: $OUT"
echo ""
