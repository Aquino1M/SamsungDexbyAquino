# Android Dex by Aquino — Enhanced Edition

> Projeto criado e mantido por **Aquino** — [@Aquino1M](https://github.com/Aquino1M)

Android Dex by Aquino transforma a experiência de usar um aparelho Android no Windows, com foco em produtividade, janelas, espelhamento, áudio e jogos. A edição **Enhanced** adiciona uma camada pública de estabilidade, diagnóstico e recursos para jogos ao redor da build existente.

## ⭐ Principais recursos

- Supervisor ADB com recuperação automática do daemon `tcp:5037`.
- Reparo das portas reversas `3698–3702` usadas pela build.
- Espera inteligente pela autorização USB antes de enviar APK/JAR.
- Modo **Borderless Fullscreen** para o Android Dex e janelas de jogos.
- Perfis de jogo: padrão, baixa latência, qualidade, economia e ultrawide.
- Base de compatibilidade por fabricante: Samsung, Xiaomi/Redmi/POCO, Motorola, Pixel, OnePlus, OPPO, realme, vivo e Nothing.
- Assistente para **Wireless ADB** (pair/connect/disconnect/status).
- Central de diagnóstico com relatório JSON pronto para anexar em Issues.
- Control Center em PowerShell para iniciar, reparar e testar sem decorar comandos.
- CI no GitHub para validar scripts PowerShell e arquivos JSON em cada atualização.

## 🚀 Como testar

### 1. Baixe a build do Android Dex
A build compilada deve ficar em uma pasta chamada `Android_Dex` na raiz deste repositório:

```text
SamsungDexbyAquino/
├─ Android_Dex/
│  ├─ Android_Dex.exe
│  ├─ Build_copy/
│  └─ data/
├─ scripts/
├─ config/
└─ start_android_dex.bat
```

### 2. Ative Depuração USB no Android
Ative **Opções do desenvolvedor > Depuração USB**, conecte o aparelho e aceite a autorização RSA.

### 3. Abra o Control Center
Execute:

```text
start_android_dex.bat
```

O launcher testa o ADB, espera a autorização do aparelho, tenta reparar as portas reversas e só depois inicia o Android Dex.

## 🎮 Tela cheia em jogos

No Control Center, escolha o perfil desejado e marque **Tela cheia** antes de iniciar. Também é possível aplicar tela cheia em uma janela já aberta:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Fullscreen.ps1 -ProcessName Android_Dex
```

Para uma janela do scrcpy:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Fullscreen.ps1 -ProcessName scrcpy
```

Use `-Off` para voltar ao modo de janela.

## 📶 Wireless ADB

Pareamento:

```powershell
.\scripts\Wireless-Adb.ps1 -Action pair -Address 192.168.1.20:37123 -PairCode 123456
```

Conexão:

```powershell
.\scripts\Wireless-Adb.ps1 -Action connect -Address 192.168.1.20:5555
```

O endereço e as portas aparecem na tela **Depuração sem fio** do Android.

## 🩺 Diagnóstico

```powershell
.\scripts\Diagnostics.ps1
```

O relatório verifica executável, ADB, APK companion, JARs, FFmpeg, WebView2 e estado do aparelho. Identificadores de dispositivo são mascarados no relatório para facilitar o envio público.

## 🛠️ Problemas que esta edição ataca

A build analisada apresentou falhas reais como:

- `Reverse port 3698 failed`
- `cannot connect to daemon at tcp:5037`
- `device still authorizing`
- `APK installation failed`
- `JAR push failed`

O launcher Enhanced tenta recuperar esses cenários automaticamente antes de iniciar o aplicativo.

## 🗺️ Roadmap

As 20 melhorias planejadas e o estado de cada uma estão em [`docs/ROADMAP.md`](docs/ROADMAP.md).

## 📦 Build compilada

A build original enviada por Aquino é grande e contém binários de terceiros (Flutter, FFmpeg, scrcpy e outros). Por isso, o código público e os scripts Enhanced ficam neste repositório, enquanto builds distribuíveis devem ser publicadas na área **Releases** respeitando as licenças de todos os componentes de terceiros.

## 🔐 Autoria e uso

**Copyright © 2026 Aquino / Aquino1M. Todos os direitos reservados.**

Este repositório é público para transparência, testes e feedback. A licença do código criado por Aquino **não autoriza** rebranding, venda, redistribuição como outro produto, remoção dos créditos ou alegação de autoria por terceiros. Componentes de terceiros continuam sujeitos às licenças originais deles.

Leia [`LICENSE.md`](LICENSE.md) e [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## 🐛 Encontrou problema?

Abra uma Issue usando o template de bug e, se possível, anexe o JSON criado por `scripts/Diagnostics.ps1`. Nunca publique códigos de pareamento, chaves, senhas ou dados pessoais.

---

### Criado por Aquino

GitHub: **https://github.com/Aquino1M**

> Projeto independente. Não é afiliado, patrocinado ou endossado pela Samsung Electronics, Google, Microsoft ou pelos projetos de terceiros utilizados.
