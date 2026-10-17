#!/usr/bin/env bash
# ==============================================================================
# Script de Verificacao de Compatibilidade - HY300 (Rockchip RK3326)
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}=================================================================${NC}"
echo -e "${CYAN}       VERIFICADOR DE COMPATIBILIDADE - PROJETOR HY300          ${NC}"
echo -e "${CYAN}=================================================================${NC}"
echo "Este script verifica se o seu projetor possui o hardware"
echo "e a versao de firmware compativeis com a ROM limpa RK3326."
echo ""

# Localizar ADB
ADB=""
if command -v adb >/dev/null 2>&1; then
    ADB="adb"
elif [ -f "/mnt/c/adb/adb.exe" ]; then
    ADB="/mnt/c/adb/adb.exe"
fi

if [ -z "$ADB" ]; then
    echo -e "${RED}[ERRO] adb nao encontrado no PATH.${NC}"
    echo "Instale o adb (ex: sudo apt install adb) e tente novamente."
    exit 1
fi

# Verificar dispositivos conectados
DEVICE=$("$ADB" devices | grep -w "device" | head -n 1 | awk '{print $1}' || true)

if [ -z "$DEVICE" ]; then
    echo -e "${YELLOW}Nenhum dispositivo ADB detectado via USB ou rede.${NC}"
    echo "Dica: No firmware de fabrica do HY300 RK3326, a porta 5555 vem aberta na rede WiFi!"
    read -rp "Digite o IP do projetor na rede (ex: 192.168.1.150): " IP
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

echo -e "${GREEN}[INFO] Dispositivo conectado: $DEVICE${NC}"
echo ""

get_prop() {
    "$ADB" -s "$DEVICE" shell getprop "$1" | tr -d '\r\n'
}

PLATFORM=$(get_prop "ro.board.platform")
MODEL=$(get_prop "ro.product.model")
DISPLAY_ID=$(get_prop "ro.build.display.id")
SDK_VER=$(get_prop "ro.vendor.sdkversion")
ANDROID_VER=$(get_prop "ro.build.version.release")
API_LVL=$(get_prop "ro.build.version.sdk")

SYS_PART=$("$ADB" -s "$DEVICE" shell "ls -l /dev/block/by-name/system 2>/dev/null" | tr -d '\r\n' | awk -F'-> ' '{print $2}')
OEM_PART=$("$ADB" -s "$DEVICE" shell "ls -l /dev/block/by-name/oem 2>/dev/null" | tr -d '\r\n' | awk -F'-> ' '{print $2}')
SU_TEST=$("$ADB" -s "$DEVICE" shell "su 0 id 2>/dev/null" | tr -d '\r\n' || true)

echo "-----------------------------------------------------------------"
echo "                     RELATORIO DO APARELHO                       "
echo "-----------------------------------------------------------------"
echo "Processador / Plataforma:  $PLATFORM"
echo "Modelo informado:          $MODEL"
echo "Versao de Build (Display): $DISPLAY_ID"
echo "SDK Vendor:                $SDK_VER"
echo "Versao Android (API):      $ANDROID_VER (API $API_LVL)"
echo "Particao system:           $SYS_PART"
echo "Particao oem:              $OEM_PART"
if [[ "$SU_TEST" =~ "uid=0" ]]; then
    echo -e "Backdoor root de fabrica:  ${YELLOW}PRESENTE (su ativo)${NC}"
else
    echo "Backdoor root de fabrica:  Ausente ou seguro"
fi
echo "-----------------------------------------------------------------"
echo ""

if [[ "$PLATFORM" =~ (h713|sun50iw9|allwinner) ]]; then
    echo -e "${RED}=================================================================${NC}"
    echo -e "${RED} [X] INCOMPATIVEL: PROCESSADOR ALLWINNER (H713) DETECTADO!      ${NC}"
    echo -e "${RED}=================================================================${NC}"
    echo -e "${YELLOW}O seu projetor utiliza um chip Allwinner H713 e NAO o Rockchip RK3326.${NC}"
    echo -e "${RED}GRAVAR ESTA ROM LIMPA CAUSARA O BRICK IRREVERSIVEL DO SEU PROJETOR!${NC}"
    exit 2
fi

if [ "$PLATFORM" != "rk3326" ]; then
    echo -e "${RED}=================================================================${NC}"
    echo -e "${RED} [?] CHIPSET NAO RECONHECIDO: $PLATFORM                         ${NC}"
    echo -e "${RED}=================================================================${NC}"
    echo "A plataforma informada nao e rk3326. Nao prossiga com a gravacao."
    exit 2
fi

if [ "$DISPLAY_ID" = "11 PI eng.20240808.171210test-keys" ]; then
    echo -e "${GREEN}=================================================================${NC}"
    echo -e "${GREEN} [OK] PROJETOR 100% COMPATIVEL E HOMOLOGADO!                    ${NC}"
    echo -e "${GREEN}=================================================================${NC}"
    echo "Seu projetor possui EXATAMENTE o mesmo processador, modelo e build"
    echo "do firmware de referencia (08/08/2024)."
else
    echo -e "${YELLOW}=================================================================${NC}"
    echo -e "${YELLOW} [!] COMPATIVEL COM RESSALVAS (BUILD DIFERENTE)                 ${NC}"
    echo -e "${YELLOW}=================================================================${NC}"
    echo "O processador e RK3326 e o modelo e HY300, mas a sua build e diferente."
    echo "Faca o backup completo das particoes antes de qualquer tentativa."
fi
echo ""
