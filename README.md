# Android Dex by Aquino — Enhanced / Gaming Edition

> **Enhanced/Gaming por Aquino — [@Aquino1M](https://github.com/Aquino1M)**

Este repositório contém a camada **Enhanced/Gaming** criada por Aquino em torno da build Android-Dex existente: launchers, recuperação ADB, diagnóstico, fullscreen, Wireless ADB, perfis de jogos, KeyMapper, gamepad, janelas por aplicativo e patches de interface.

> **Importante sobre autoria:** a aplicação base `Android_Dex.exe` / Flutter é derivada da build **Android-Dex de Shrey113**, cujo repositório público identifica a aplicação como **Closed Source**. O projeto Aquino preserva essa atribuição. O nome “by Aquino” refere-se às melhorias, Gaming Engine, integração, patches, documentação e distribuição Enhanced — não à autoria do aplicativo-base fechado.

## Principais recursos Aquino

- Supervisor ADB e recuperação do daemon `tcp:5037`.
- Reparo das portas reversas `3698–3702`.
- Wireless ADB pair/connect/disconnect.
- Borderless fullscreen.
- Gaming Hub com janela por aplicativo via scrcpy 4.
- `--keyboard=uhid`, `--mouse=uhid` e `--gamepad=uhid`.
- KeyMapper visual e fallback XInput → touch.
- Perfis 30/60/90/120/144/165 FPS.
- Codec automático e perfis de baixa latência.
- Perfis ultrawide 21:9 e 32:9.
- Diagnóstico e relatórios para Issues.
- Patch seguro da UI compilada com backup do `app.so`.

## Como iniciar

Com a build base dentro de `Android_Dex/`:

```text
start_android_dex.bat       -> abre a interface principal diretamente
start_control_center.bat    -> ADB, diagnóstico e fullscreen
start_gaming_hub.bat        -> jogos, KeyMapper, gamepad e FPS
```

## Instalação

No PowerShell, execute:

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/Aquino1M/SamsungDexbyAquino/main/install_android_dex.ps1 -OutFile .\install_android_dex.ps1
.\install_android_dex.ps1
```

O instalador baixa a release oficial, valida o arquivo e cria a pasta `Android Dex by Aquino` em `%LOCALAPPDATA%`.

## Patch de interface v0.3.2

Para aplicar o branding Aquino e traduzir a área de conexão da build compilada:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Patch-CompiledUi.ps1
```

O patch:

- cria `Android_Dex/data/app.so.upstream-backup` antes de qualquer alteração;
- mostra **Aquino1M** na área de melhorias;
- mantém a indicação da base upstream;
- traduz `Device Connection Guide` e passos de conexão para PT-BR;
- troca a navegação/tutorial para rótulos em português;
- preserva URLs de source/update/issues do upstream onde elas pertencem ao aplicativo base.

O tutorial único em português está em [`docs/TUTORIAL_PTBR.md`](docs/TUTORIAL_PTBR.md).

### Limitação da build fechada

O widget que renderiza a lista interna de vídeos está compilado no AOT Flutter. Sem o fonte original dessa tela, remover estruturalmente o `TabBar` e a lista de cards exigiria reescrever o binário fechado de forma frágil. Por isso a v0.3.2 faz apenas substituições de strings de tamanho fixo, adiciona tutorial PT-BR local e mantém backup restaurável. Não publicamos o `app.so` fechado como código próprio.

## Gaming Hub

O guia completo está em [`docs/GAMING.md`](docs/GAMING.md). Os perfis de FPS são metas máximas: o FPS real depende do jogo, aparelho, encoder e tela.

## Diagnóstico

```powershell
.\scripts\Diagnostics.ps1
```

Verifica executável, ADB, dispositivo, companion APK, JARs, FFmpeg, WebView2 e portas reversas.

## Autoria e terceiros

**Código Enhanced/Gaming e customizações originais deste repositório:** Copyright © 2026 Aquino / Aquino1M.

A aplicação base, scrcpy, FFmpeg, Flutter e demais componentes de terceiros continuam pertencendo aos respectivos autores e sujeitos às licenças/termos originais. Veja [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

GitHub Aquino: **https://github.com/Aquino1M**

> Projeto independente; não afiliado ou endossado por Samsung, Google, Microsoft, BlueStacks, LDPlayer, Nox, MuMu ou outros produtos usados como referência de funcionalidades.
