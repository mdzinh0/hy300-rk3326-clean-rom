# HY300 (Rockchip RK3326): ROM Limpa e Segura

[![Chipset](https://img.shields.io/badge/SoC-Rockchip%20RK3326-orange.svg)]()
[![Android](https://img.shields.io/badge/Android-9.0%20(API%2028)-green.svg)]()
[![Launcher](https://img.shields.io/badge/Launcher-Projectivy%204.72-blue.svg)]()
[![Status](https://img.shields.io/badge/Status-v2%20Offline%20Verified-brightgreen.svg)]()

> **⚠️ AVISO CRÍTICO DE COMPATIBILIDADE:**
> O projetor **HY300** é vendido em diferentes versões de hardware. Existem modelos com processador **Rockchip RK3326** e modelos com **Allwinner H713**.
> 
> **ESTA ROM É EXCLUSIVA PARA A VERSÃO COM CHIP ROCKCHIP RK3326.**
> Se o seu projetor utilizar o processador Allwinner (H713) ou qualquer outro modelo, **NÃO GRAVE ESTE FIRMWARE**, sob pena de causar **brick irreversível (perda total)** do aparelho.
> 
> 👉 **Execute a [Etapa 0: Verificação de Compatibilidade](#etapa-0-verificação-de-compatibilidade-obrigatória) antes de prosseguir!**

---

## 📑 Sumário

- [Por que esta ROM limpa foi criada?](#por-que-esta-rom-limpa-foi-criada)
- [O que a ROM limpa altera](#o-que-a-rom-limpa-altera)
- [O que permanece original e funcionando](#o-que-permanece-original-e-funcionando)
- [Etapa 0: Verificação de Compatibilidade (OBRIGATÓRIA)](#etapa-0-verificação-de-compatibilidade-obrigatória)
- [Etapa 1: Backup Completo (OBRIGATÓRIO)](#etapa-1-backup-completo-obrigatório)
- [Etapa 2: Download das Imagens Limpas](#etapa-2-download-das-imagens-limpas)
- [Etapa 3: Gravação com RKDevTool (Passo a Passo)](#etapa-3-gravação-com-rkdevtool-passo-a-passo)
- [Etapa 4: Reset de Fábrica (OBRIGATÓRIO)](#etapa-4-reset-de-fábrica-obrigatório)
- [Primeiro Uso e Configuração do Projectivy Launcher](#primeiro-uso-e-configuração-do-projectivy-launcher)
- [Como Restaurar o Firmware Original de Fábrica](#como-restaurar-o-firmware-original-de-fábrica)
- [Como Compilar Você Mesmo (Avançado)](#como-compilar-você-mesmo-avançado)
- [FAQ & Solução de Problemas](#faq--solução-de-problemas)
- [Estrutura do Repositório](#estrutura-do-repositório)
- [Licença e Isenção de Responsabilidade](#licença-e-isenção-de-responsabilidade)

---

## Por que esta ROM limpa foi criada?

Ao analisar minuciosamente as imagens originais de fábrica do projetor Magcubic HY300 (Rockchip RK3326), foram identificadas graves falhas de segurança e softwares indesejados rodando em segundo plano:

1. **Proxyware / Adware pré-instalado:** Processos ocultos e serviços como `txczbox`, `txczota`, `itvbox`, `meowrisee` e conexões a redes descentralizadas (ex.: `gaganode`) que utilizam o processador, a memória e a sua rede de internet sem o seu consentimento.
2. **Backdoor de Root Persistente:** Binários `su` e `daemonsu` (SuperSU) com permissão setuid root em `/system/xbin`.
3. **Porta ADB 5555 aberta na rede sem senha:** Qualquer dispositivo conectado na mesma rede Wi-Fi conseguia acesso root silencioso ao projetor via `adb connect`, sem qualquer tela de confirmação ou pareamento.
4. **Launcher nativo lento e com anúncios:** A tela inicial padrão do fabricante busca propagandas em domínios remotos chineses (`shzhtxcz.com`, `mfcopenapi.info`), consumindo banda e deixando a navegação pesada.

**O objetivo desta ROM:** Manter 100% da estabilidade e recursos nativos do aparelho (keystone, foco, Wi-Fi, Bluetooth e Play Store), eliminando completamente as ameaças, fechando o backdoor de rede e instalando o excelente **Projectivy Launcher** como tela inicial leve e sem anúncios.

---

## O que a ROM limpa altera

### Partição `system.img`
| Componente | Ação realizada |
|---|---|
| `/system/xbin/{su,daemonsu,supolicy,procmem}` | **Removidos** (elimina o root persistente e privilégios setuid/setgid inseguros). |
| `/system/app/{txczbox,txczota,txcz_app,txcztest,GetApp,RKUpdateService}` | **Removidos** (adwares e instaladores ocultos do fabricante). |
| `/system/priv-app/StressTest` | **Removido** (app de stress test da Rockchip). |
| `/system/app/txcz_launcher` | **Removido** (launcher de fábrica com anúncios). |
| `/system/priv-app/ProjectivyLauncher` | **Adicionado** (Projectivy Launcher v4.72 oficial, limpo, assinado e com rótulo SELinux correto). |
| `/init.usb.rc` | Serviço `adbd` restaurado para rodar sem flag de root (`--root_seclabel`). |
| `/system/etc/prop.default` | Configurado com `ro.debuggable=0`, `persist.sys.usb.config=mtp` e `ro.adb.secure=1`. |
| `/system/build.prop` | Linha `service.adb.tcp.port=5555` desativada (o ADB não abre mais na rede ao ligar). |

### Partição `oem.img`
| Componente | Ação realizada |
|---|---|
| `bundled_persist-app/TXCZTVApp_FTZX_*` | **Removido** (bloatware reinstalável da partição persistente). |
| `bundled_uninstall_back-app/Youtubu_tv` | **Removido** (repack suspeito de YouTube; use o SmartTube ou o app oficial). |

---

## O que permanece original e funcionando

- **Bootloader, Kernel e Drivers de Hardware:** Mantidos intactos (`boot.img`, `dtb`, `dtbo`, `trust`, `vendor.img`).
- **Wi-Fi e Bluetooth:** Drivers RTL8733BS, AIC8800 e bcmdhd 100% originais.
- **Painel de Ajustes do Projetor (`TxczSetting`):** O menu de ajuste de foco, keystone (correção de trapézio de 4 pontos), zoom e rotação de tela funciona perfeitamente.
- **Google Play Store e Serviços Google:** Originais e operacionais.
- **Transmissão e HDMI:** Entrada HDMI e espelhamento continuam funcionando normalmente.

---

## Etapa 0: Verificação de Compatibilidade (OBRIGATÓRIA)

Antes de baixar imagens ou tentar qualquer gravação, **confirme se o seu projetor é exatamente o modelo compatível**.

### Tabela de Comparação

| Característica | ✅ Compatível (Este Projeto) | ❌ INCOMPATÍVEL (NÃO GRAVAR!) |
|---|---|---|
| **Processador / Plataforma** | `rk3326` (Rockchip) | `h713`, `sun50iw9` (Allwinner) ou outro |
| **Modelo** | `HY300` | HY300 Pro, HY320, HY350 ou outro |
| **Versão de Build** | `11 PI eng.20240808.171210test-keys` | Builds Allwinner ou de outros fabricantes |
| **SDK da Placa** | `RK3326_ANDROID9.0_MID_V2.1` | Qualquer outro |
| **Versão real do Android** | Android 9 (API 28) | Android 11 nativo de chips Allwinner |

---

### Método 1: Verificação Automática por Script (Mais Fácil)

O repositório já inclui scripts prontos que detectam e validam o seu projetor via ADB.

#### No Windows:
1. Conecte o projetor na mesma rede Wi-Fi do seu computador (ou ligue um cabo USB macho-macho na porta USB do projetor).
2. Dê dois cliques no arquivo:
   ```cmd
   scripts\verificar_compatibilidade.bat
   ```
3. Se solicitado, informe o IP do projetor na sua rede (encontrado em *Configurações → Rede/Wi-Fi* no projetor).
4. O script exibirá na tela se o aparelho é **100% COMPATÍVEL** ou se possui chipset diferente.

#### No Linux / macOS:
```bash
chmod +x scripts/check_compatibility.sh
./scripts/check_compatibility.sh
```

---

### Método 2: Verificação Manual via Linha de Comando (ADB)

Se preferir rodar os comandos manualmente no terminal:

```bash
# Conectar ao projetor pelo IP na rede Wi-Fi:
adb connect <IP_DO_PROJETOR>:5555

# Conferir o processador (DEVE retornar 'rk3326'):
adb shell getprop ro.board.platform

# Conferir a versão de build:
adb shell getprop ro.build.display.id

# Conferir o modelo:
adb shell getprop ro.product.model
```

**Resultado esperado:**
- `ro.board.platform`: `rk3326`
- `ro.product.model`: `HY300`
- `ro.build.display.id`: `11 PI eng.20240808.171210test-keys`

> ⚠️ Se o retorno de `ro.board.platform` for algo como `allwinner`, `sun50iw9` ou `h713`, **PARE IMEDIATAMENTE**. O seu aparelho usa chip Allwinner e este tutorial não se aplica a ele.

---

### Método 3: Verificação no Próprio Projetor (Sem PC)

Se você não tem o ADB configurado no momento:
1. No projetor, acesse a **Google Play Store** (ou instale via pendrive) o aplicativo **AIDA64** ou **Device Info HW**.
2. Abra o aplicativo e acesse a aba **Processador / SoC**:
   - Se o campo *Modelo do SoC* for **Rockchip RK3326** → Compatível.
   - Se o campo for **Allwinner H713** (Cortex-A53 quad-core com GPU Mali-G31) → Incompatível.

---

## Etapa 1: Backup Completo (OBRIGATÓRIO)

**Nunca grave uma ROM sem ter o backup das partições originais do seu aparelho.**

Como o firmware de fábrica possui a falha do ADB root aberto, podemos fazer o backup direto pela rede Wi-Fi em poucos minutos.

### Opção A: Usando o Script Automatizado
- No Windows: Dê duplo clique em `scripts\fazer_backup.bat`.
- No Linux/macOS: Execute `./scripts/fazer_backup.sh`.

O script fará o dump de `system` e `oem`, baixará para uma pasta local `backup/` e validará o hash SHA256 automaticamente.

### Opção B: Backup Manual via Terminal
No HY300 RK3326, a partição `system` é a **13** (`mmcblk2p13`) e `oem` é a **16** (`mmcblk2p16`).

```bash
adb connect <IP_DO_PROJETOR>:5555

# 1. Backup da partição system (1,5 GB)
adb shell "su 0 -c 'dd if=/dev/block/mmcblk2p13 of=/data/local/tmp/system_original.img bs=1048576; chmod 644 /data/local/tmp/system_original.img'"
adb pull /data/local/tmp/system_original.img
adb shell "su 0 -c 'rm /data/local/tmp/system_original.img'"

# 2. Backup da partição oem (512 MB)
adb shell "su 0 -c 'dd if=/dev/block/mmcblk2p16 of=/data/local/tmp/oem_original.img bs=1048576; chmod 644 /data/local/tmp/oem_original.img'"
adb pull /data/local/tmp/oem_original.img
adb shell "su 0 -c 'rm /data/local/tmp/oem_original.img'"
```

Guarde os arquivos `system_original.img` e `oem_original.img` em um local seguro.

---

## Etapa 2: Download das Imagens Limpas

Baixe os arquivos prontos na aba **[Releases (v2.0)](https://github.com/mdzinh0/hy300-rk3326-clean-rom/releases/tag/v2.0)** deste repositório no GitHub:

| Arquivo no Release | Conteúdo | Tamanho descompactado | Link direto |
|---|---|---|---|
| `HY300_RK3326_rom_limpa_v2_system_projectivy.zip` | `system.img` limpo com Projectivy | ~1,5 GiB | [Download (636 MB)](https://github.com/mdzinh0/hy300-rk3326-clean-rom/releases/download/v2.0/HY300_RK3326_rom_limpa_v2_system_projectivy.zip) |
| `HY300_RK3326_rom_limpa_v2_oem.zip` | `oem.img` limpo | ~512 MiB | [Download (112 MB)](https://github.com/mdzinh0/hy300-rk3326-clean-rom/releases/download/v2.0/HY300_RK3326_rom_limpa_v2_oem.zip) |
| `SHA256SUMS_zips.txt` | Hashes de integridade | — | [Download](https://github.com/mdzinh0/hy300-rk3326-clean-rom/releases/download/v2.0/SHA256SUMS_zips.txt) |

### Verificação de Integridade (Hashes SHA256)

Após baixar e descompactar os arquivos `.zip`, confira se os hashes correspondem:

**Arquivos .img (descompactados):**
- `system.img`: `77aa8ea8b805fc60a223aad7f618efae8f8ee04448f86312e66ce4959a2041de`
- `oem.img`: `2fb82dfd0665e3e38a77a7dbd464f01ca3414ec8bb11128009fc0b8685bf7f24`

Para verificar no Windows (PowerShell):
```powershell
Get-FileHash system.img
Get-FileHash oem.img
```
No Linux:
```bash
sha256sum system.img oem.img
```

---

## Etapa 3: Gravação com RKDevTool (Passo a Passo)

A gravação é feita através da ferramenta oficial da Rockchip (**RKDevTool**) em ambiente Windows.

> **🛑 REGRA DE OURO:**
> Grave **APENAS** as partições `system` e `oem`.
> **NUNCA** marque ou tente regravar `Loader`, `Parameter`, `misc`, `boot` ou `trust`.

### Pré-requisitos
1. Computador com Windows 10 ou 11.
2. Cabo USB macho-macho (USB-A para USB-A).
3. Driver USB Rockchip instalado (baixe o pacote **Rockchip DriverAssitant**).
4. Aplicativo **RKDevTool** (versão 2.84 ou superior).

---

### Procedimento de Gravação

1. **Instale os Drivers:**
   Execute o `DriverInstall.exe` do pacote DriverAssitant e clique em *Install Driver*.
2. **Conecte o Cabo USB:**
   Ligue uma ponta do cabo USB no computador e a outra na porta USB do projetor que suporta modo OTG.
3. **Coloque o Projetor em Modo Loader:**
   - Com o projetor ligado na rede, você pode simplesmente rodar:
     ```bash
     adb reboot loader
     ```
   - *Alternativa manual:* Desligue o projetor da tomada. Mantenha pressionado o botão de recovery/reset (geralmente dentro do orifício de áudio P2 ou orifício dedicado com um clipe) e ligue o cabo de energia.
4. **Verifique no RKDevTool:**
   Na parte inferior do RKDevTool, a mensagem deve mudar para **"Found One LOADER Device"**.
5. **Ler as Partições do Aparelho:**
   - Vá na aba **Download Image**.
   - Clique com o botão direito na lista de partições e escolha a opção **"Dev Partition"**. O programa lerá o mapa exato da eMMC do projetor.
6. **Selecionar Apenas as Duas Imagens:**
   - Desmarque todas as caixas de seleção.
   - Marque **apenas** a linha `system` e aponte para o seu `system.img` baixado.
   - Marque **apenas** a linha `oem` e aponte para o seu `oem.img` baixado.
   - Confirme se todas as outras opções continuam **desmarcadas**.
7. **Gravar:**
   - Clique no botão **Run** no canto direito.
   - Aguarde o progresso até 100% ("Download image OK").
   - O projetor irá reiniciar automaticamente.

---

### Gravação no Linux (rkdeveloptool)

Se estiver utilizando Linux:
```bash
# Gravar partição system
sudo rkdeveloptool wlx system system.img

# Gravar partição oem
sudo rkdeveloptool wlx oem oem.img

# Reiniciar o projetor
sudo rkdeveloptool rd
```

---

## Etapa 4: Reset de Fábrica (OBRIGATÓRIO)

Após a gravação das imagens, o primeiro boot iniciará o sistema.
Porém, a partição `/data` do aparelho ainda armazena dados antigos e clones dos adwares/proxywares que estavam instalados.

**Portanto, é obrigatório redefinir o sistema:**
1. No menu do projetor, acesse: **Configurações → Preferências do Dispositivo → Redefinir para a configuração original** (ou realizar *Wipe Data / Factory Reset* via Recovery).
2. Confirme a limpeza e aguarde o reinício completo.

---

## Primeiro Uso e Configuração do Projectivy Launcher

- Quando o sistema carregar pela primeira vez após o reset, o Android poderá perguntar qual Launcher deseja usar: selecione **Projectivy Launcher** e marque **"Sempre"**.
- O **Projectivy Launcher** incluído é o aplicativo original da Play Store (versão 4.72, `com.spocky.projengmenu`), mantendo sua assinatura criptográfica intacta.
- Você pode atualizar o launcher diretamente pela **Google Play Store** sempre que houver novas versões.
- Os menus de ajuste do projetor (keystone, foco e calibração) continuam funcionando no atalho de configurações.

---

## Como Restaurar o Firmware Original de Fábrica

Se por qualquer motivo você desejar voltar exatamente ao estado que veio de fábrica:
1. Conecte o projetor em modo Loader no **RKDevTool**.
2. Selecione o arquivo `system_original.img` na partição `system`.
3. Selecione o arquivo `oem_original.img` na partição `oem`.
4. Clique em **Run**.
5. Ao reiniciar, execute o Reset de Fábrica.

---

## Como Compilar Você Mesmo (Avançado)

Se preferir não usar os binários pré-compilados do Release e desejar gerar a ROM limpa a partir dos seus próprios dumps de fábrica usando Linux/WSL:

```bash
# Instalar dependências
sudo apt install e2fsprogs attr zerofree python3

# Gerar imagens limpas
sudo ./scripts/build_clean_rom.sh \
  -s system_original.img \
  -o oem_original.img \
  -d pasta_saida \
  -l ProjectivyLauncher.apk

# Validar o resultado offline
sudo ./scripts/verify_clean_rom.sh pasta_saida
```

---

## FAQ & Solução de Problemas

### 1. O RKDevTool mostra "No Devices Found"
- Verifique se instalou o driver do **DriverAssitant**.
- Experimente inverter as pontas do cabo USB ou utilizar outra porta USB no computador (de preferência portas traseiras da placa-mãe).
- Certifique-se de estar usando o comando `adb reboot loader` com o aparelho totalmente ligado.

### 2. A imagem não inicia (Loop na animação de boot)
- Você realizou a [Etapa 4 (Reset de Fábrica)](#etapa-4-reset-de-fábrica-obrigatório)? Dados antigos na partição `/data` causam conflito com as alterações do `system.img`.
- Verifique se os hashes SHA256 dos arquivos `.img` baixados conferem exatamente com a tabela da Etapa 2.

### 3. A porta ADB continua acessível?
- Na ROM limpa, o ADB pela rede Wi-Fi vem **desligado por padrão**.
- Se você ativar a *Depuração USB* nas Opções do Desenvolvedor, o projetor agora exibirá a **caixa de diálogo solicitando autorização com impressão digital RSA**, impedindo acessos não autorizados.

---

## Estrutura do Repositório

```
├── .gitignore
├── README.md
└── scripts/
    ├── verificar_compatibilidade.bat   # Verificador para Windows (executável com duplo clique)
    ├── verificar_compatibilidade.ps1   # Script PowerShell de diagnóstico de compatibilidade
    ├── check_compatibility.sh         # Script Bash de compatibilidade (Linux/macOS)
    ├── fazer_backup.bat               # Script Windows para backup automático de partições
    ├── fazer_backup.ps1               # Script PowerShell para extração segura de system e oem
    ├── fazer_backup.sh                # Script Bash para backup no Linux/macOS
    ├── build_clean_rom.sh             # Construtor da ROM a partir de dumps originais (Linux)
    └── verify_clean_rom.sh            # Auditor offline das imagens geradas
```

---

## Licença e Isenção de Responsabilidade

- **Scripts:** Distribuídos sob licença livre [MIT](https://opensource.org/licenses/MIT).
- **Projectivy Launcher:** Propriedade de Spocky ([projectivylauncher.com](https://projectivylauncher.com/)). Incluído sem modificações em sua versão gratuita. Para apoiar o desenvolvedor, considere adquirir a versão Premium na Play Store.
- **Isenção de Responsabilidade:** Modificações de firmware envolvem riscos. Os autores e colaboradores não se responsabilizam por danos, perda de dados ou mau funcionamento decorrentes do uso das instruções e arquivos contidos neste repositório. Faça sempre backup prévio.
