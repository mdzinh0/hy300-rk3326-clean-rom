# ==============================================================================
# Script de Verificacao de Compatibilidade - HY300 (Rockchip RK3326)
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "Verificador de Compatibilidade - HY300 RK3326"

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "       VERIFICADOR DE COMPATIBILIDADE - PROJETOR HY300          " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Este script verifica se o seu projetor possui o hardware"
Write-Host "e a versao de firmware compativeis com a ROM limpa RK3326."
Write-Host ""

# 1. Localizar executavel do ADB
$adbPath = ""
if (Get-Command adb -ErrorAction SilentlyContinue) {
    $adbPath = "adb"
} elseif (Test-Path "C:\adb\adb.exe") {
    $adbPath = "C:\adb\adb.exe"
} elseif (Test-Path ".\platform-tools\adb.exe") {
    $adbPath = ".\platform-tools\adb.exe"
}

if (-not $adbPath) {
    Write-Host "[ERRO] Executavel do ADB nao foi encontrado!" -ForegroundColor Red
    Write-Host "Por favor, instale o Android SDK Platform Tools (adb) em C:\adb"
    Write-Host "ou certifique-se de que o comando 'adb' esteja no seu PATH."
    Write-Host ""
    $manualPath = Read-Host "Digite o caminho completo do adb.exe (ou aperte Enter para sair)"
    if ($manualPath -and (Test-Path $manualPath)) {
        $adbPath = $manualPath
    } else {
        Write-Host "Saindo..." -ForegroundColor Yellow
        pause
        exit 1
    }
}

Write-Host "[INFO] Usando ADB: $adbPath" -ForegroundColor Gray

# 2. Verificar conexao ADB
$devices = & $adbPath devices | Select-String -Pattern "device$"

if (-not $devices) {
    Write-Host ""
    Write-Host "Nenhum dispositivo ADB detectado via USB ou rede." -ForegroundColor Yellow
    Write-Host "Dica: No firmware de fabrica do HY300 RK3326, a porta 5555 vem aberta na rede WiFi!" -ForegroundColor Cyan
    Write-Host ""
    $ip = Read-Host "Digite o IP do projetor na rede WiFi (ex: 192.168.1.150) ou Enter para tentar USB novamente"
    
    if ($ip.Trim()) {
        Write-Host "Tentando conectar em $ip:5555 ..." -ForegroundColor Gray
        & $adbPath connect "$($ip.Trim()):5555" | Out-Null
        Start-Sleep -Seconds 2
    }
}

$deviceList = & $adbPath devices | Select-String -Pattern "device$"
if (-not $deviceList) {
    Write-Host ""
    Write-Host "[ERRO] Nao foi possivel conectar ao projetor via ADB." -ForegroundColor Red
    Write-Host "- Verifique se o projetor esta ligado e conectado na mesma rede WiFi."
    Write-Host "- Se estiver usando cabo USB (macho-macho), use a porta USB correta (OTG)."
    Write-Host ""
    pause
    exit 1
}

$firstDevice = ($deviceList[0].Line -split "`t")[0]
Write-Host "[INFO] Dispositivo conectado: $firstDevice" -ForegroundColor Green
Write-Host ""

# 3. Coleta de propriedades
Write-Host "Lendo informacoes do sistema..." -ForegroundColor Cyan

function Get-Prop($propName) {
    $val = & $adbPath -s $firstDevice shell getprop $propName
    return $val.Trim()
}

$platform   = Get-Prop "ro.board.platform"
$model      = Get-Prop "ro.product.model"
$displayId  = Get-Prop "ro.build.display.id"
$sdkVersion = Get-Prop "ro.vendor.sdkversion"
$androidVer = Get-Prop "ro.build.version.release"
$apiLevel   = Get-Prop "ro.build.version.sdk"
$txczModel  = Get-Prop "ro.txcz.model"

# Verificar particoes
$partSystem = (& $adbPath -s $firstDevice shell "ls -l /dev/block/by-name/system" 2>$null).Trim()
$partOem    = (& $adbPath -s $firstDevice shell "ls -l /dev/block/by-name/oem" 2>$null).Trim()

# Testar su / root
$suTest = (& $adbPath -s $firstDevice shell "su 0 id" 2>$null).Trim()

Write-Host ""
Write-Host "-----------------------------------------------------------------" -ForegroundColor Gray
Write-Host "                     RELATORIO DO APARELHO                       " -ForegroundColor White
Write-Host "-----------------------------------------------------------------" -ForegroundColor Gray
Write-Host ("Processador / Plataforma:  {0}" -f $platform)
Write-Host ("Modelo informado:          {0}" -f $model)
Write-Host ("Versao de Build (Display): {0}" -f $displayId)
Write-Host ("SDK Vendor:                {0}" -f $sdkVersion)
Write-Host ("Versao Android (API):      {0} (API {1})" -f $androidVer, $apiLevel)
Write-Host ("Particao system:           {0}" -f ($partSystem -replace ".*-> ", ""))
Write-Host ("Particao oem:              {0}" -f ($partOem -replace ".*-> ", ""))
$rootStatus = if ($suTest -like "*uid=0*") { "PRESENTE (su ativo)" } else { "Ausente ou seguro" }
Write-Host ("Backdoor root de fabrica:  {0}" -f $rootStatus)
Write-Host "-----------------------------------------------------------------" -ForegroundColor Gray
Write-Host ""

# 4. Avaliacao de Compatibilidade
$isAllwinner = ($platform -like "*h713*" -or $platform -like "*sun50iw9*" -or $platform -like "*allwinner*")
$isRK3326    = ($platform -eq "rk3326")
$isHY300     = ($model -eq "HY300")
$isExactBuild = ($displayId -eq "11 PI eng.20240808.171210test-keys")

if ($isAllwinner) {
    Write-Host "=================================================================" -ForegroundColor Red
    Write-Host " [X] INCOMPATIVEL: PROCESSADOR ALLWINNER (H713) DETECTADO!      " -ForegroundColor Red
    Write-Host "=================================================================" -ForegroundColor Red
    Write-Host "O seu projetor utiliza um chip Allwinner H713 e NAO o Rockchip RK3326." -ForegroundColor Yellow
    Write-Host "GRAVAR ESTA ROM LIMPA CAUSARA O BRICK IRREVERSIVEL DO SEU PROJETOR!" -ForegroundColor Red
    Write-Host "Este repositório e compativel APENAS com modelos Rockchip RK3326."
    Write-Host ""
    pause
    exit 2
}

if (-not $isRK3326) {
    Write-Host "=================================================================" -ForegroundColor Red
    Write-Host " [?] CHIPSET NAO RECONHECIDO: $platform                         " -ForegroundColor Red
    Write-Host "=================================================================" -ForegroundColor Red
    Write-Host "A plataforma informada nao e rk3326. Nao prossiga com a gravacao." -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 2
}

if ($isRK3326 -and $isExactBuild) {
    Write-Host "=================================================================" -ForegroundColor Green
    Write-Host " [OK] PROJETOR 100% COMPATIVEL E HOMOLOGADO!                    " -ForegroundColor Green
    Write-Host "=================================================================" -ForegroundColor Green
    Write-Host "Seu projetor possui EXATAMENTE o mesmo processador, modelo e build" -ForegroundColor White
    Write-Host "do firmware de referencia (08/08/2024)." -ForegroundColor White
    Write-Host ""
    Write-Host "Proximos passos recomendados:" -ForegroundColor Cyan
    Write-Host "1. Faca o backup das particoes (execute o script scripts\fazer_backup.bat)"
    Write-Host "2. Baixe os arquivos da ROM limpa na aba Releases do GitHub"
    Write-Host "3. Grave system.img e oem.img usando o RKDevTool conforme o README.md"
    Write-Host ""
} elseif ($isRK3326) {
    Write-Host "=================================================================" -ForegroundColor Yellow
    Write-Host " [!] COMPATIVEL COM RESSALVAS (BUILD DIFERENTE)                 " -ForegroundColor Yellow
    Write-Host "=================================================================" -ForegroundColor Yellow
    Write-Host "O seu processador e RK3326 e o modelo e HY300, mas a sua build:" -ForegroundColor White
    Write-Host "  -> $displayId" -ForegroundColor Cyan
    Write-Host "e diferente da build de referencia (11 PI eng.20240808.171210test-keys)." -ForegroundColor White
    Write-Host ""
    Write-Host "A ROM limpa provavelmente funcionara, mas e FUNDAMENTAL fazer o" -ForegroundColor Yellow
    Write-Host "backup completo das suas particoes originais antes de qualquer gravacao!" -ForegroundColor Yellow
    Write-Host ""
}

pause
