# ==============================================================================
# Script de Backup Seguro de Particoes (system e oem) - HY300 RK3326
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "Backup de Particoes - HY300 RK3326"

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "             BACKUP DE SEGURANCA - PROJETOR HY300               " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Este script fara o dump das particoes originais (system e oem)"
Write-Host "direto do projetor para esta pasta, verificando a integridade."
Write-Host ""

# 1. Localizar ADB
$adbPath = ""
if (Get-Command adb -ErrorAction SilentlyContinue) {
    $adbPath = "adb"
} elseif (Test-Path "C:\adb\adb.exe") {
    $adbPath = "C:\adb\adb.exe"
}

if (-not $adbPath) {
    Write-Host "[ERRO] Executavel do adb nao encontrado." -ForegroundColor Red
    pause
    exit 1
}

# 2. Conectar ADB
$devices = & $adbPath devices | Select-String -Pattern "device$"
if (-not $devices) {
    $ip = Read-Host "Digite o IP do projetor na rede WiFi (ex: 192.168.1.150)"
    if ($ip.Trim()) {
        & $adbPath connect "$($ip.Trim()):5555" | Out-Null
        Start-Sleep -Seconds 2
    }
}

$deviceList = & $adbPath devices | Select-String -Pattern "device$"
if (-not $deviceList) {
    Write-Host "[ERRO] Dispositivo nao conectado." -ForegroundColor Red
    pause
    exit 1
}

$serial = ($deviceList[0].Line -split "`t")[0]
Write-Host "[OK] Conectado a $serial" -ForegroundColor Green
Write-Host ""

# Criar pasta backup
$outDir = Join-Path $PSScriptRoot "..\backup"
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}
$outDir = (Resolve-Path $outDir).Path
Write-Host "[INFO] Os backups serao salvos em: $outDir" -ForegroundColor Cyan
Write-Host ""

# Mapear particoes
# No HY300 RK3326:
# system = mmcblk2p13
# oem = mmcblk2p16
$partitions = @(
    @{ Name = "system"; Node = "/dev/block/mmcblk2p13"; File = "system_original.img" },
    @{ Name = "oem";    Node = "/dev/block/mmcblk2p16"; File = "oem_original.img" }
)

foreach ($part in $partitions) {
    $name = $part.Name
    $node = $part.Node
    $dest = Join-Path $outDir $part.File

    Write-Host "-----------------------------------------------------------------" -ForegroundColor Gray
    Write-Host "Iniciando backup da particao: $name ($node)" -ForegroundColor Yellow
    Write-Host "1. Extraindo no aparelho (dd)... Aguarde alguns instantes..." -ForegroundColor Gray
    
    # Executa dd
    & $adbPath -s $serial shell "su 0 -c 'dd if=$node of=/data/local/tmp/$($part.File) bs=1048576 && chmod 644 /data/local/tmp/$($part.File)'" | Out-Null
    
    Write-Host "2. Calculando SHA256 no aparelho..." -ForegroundColor Gray
    $devHash = (& $adbPath -s $serial shell "su 0 -c 'sha256sum /data/local/tmp/$($part.File)'").Trim() -split "\s+" | Select-Object -First 1

    Write-Host "3. Baixando para o computador (adb pull)..." -ForegroundColor Gray
    & $adbPath -s $serial pull "/data/local/tmp/$($part.File)" "$dest" | Out-Null

    Write-Host "4. Removendo arquivo temporario do projetor..." -ForegroundColor Gray
    & $adbPath -s $serial shell "su 0 -c 'rm -f /data/local/tmp/$($part.File)'" | Out-Null

    Write-Host "5. Verificando integridade local..." -ForegroundColor Gray
    $locHash = (Get-FileHash -Path "$dest" -Algorithm SHA256).Hash.ToLower()

    if ($devHash.ToLower() -eq $locHash) {
        Write-Host " [OK] Sucesso! Hash conferido: $locHash" -ForegroundColor Green
    } else {
        Write-Host " [FALHA] Hash divergente entre projetor e PC!" -ForegroundColor Red
        Write-Host " Dev: $devHash"
        Write-Host " PC : $locHash"
    }
    Write-Host ""
}

Write-Host "=================================================================" -ForegroundColor Green
Write-Host "              BACKUP FINALIZADO COM SUCESSO!                     " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "Seus arquivos foram salvos com seguranca em:"
Write-Host "$outDir" -ForegroundColor Cyan
Write-Host "Guarde esses arquivos em local seguro caso precise restaurar o projetor."
Write-Host ""
pause
