# Tutorial PT-BR — Android Dex by Aquino

> Enhanced/Gaming por **Aquino / Aquino1M**. A aplicacao base Android-Dex e uma build closed-source de Shrey113; a autoria da base deve continuar preservada.

## Conexao USB

1. No celular, abra **Configuracoes > Sobre o telefone**.
2. Toque 7 vezes em **Numero da versao / Build** para liberar as Opcoes do Desenvolvedor.
3. Entre em **Opcoes do Desenvolvedor** e ative **Depuracao USB**.
4. Conecte o Android ao PC com um cabo que transmita dados.
5. Quando o Android perguntar pela chave RSA, marque para confiar no computador e toque em **Permitir**.
6. Execute `start_android_dex.bat`.
7. Clique em **Adicionar Novo Dispositivo** e continue pela conexao USB.

## Conexao Wi-Fi

Depois que o aparelho estiver autorizado:

1. Ative **Depuracao sem fio** no Android.
2. Use `start_control_center.bat` ou `scripts/Wireless-Adb.ps1` para parear/conectar.
3. PC e celular devem estar na mesma rede local.

## Jogos

Execute `start_gaming_hub.bat` para usar:

- janela independente por aplicativo;
- fullscreen;
- UHID de teclado, mouse e gamepad;
- KeyMapper visual;
- XInput para jogos touchscreen-only;
- perfis 30/60/90/120/144/165 FPS;
- codec automatico e perfis de baixa latencia.

## Se o aparelho nao aparecer

Abra `start_control_center.bat` e rode **Reparar ADB** e **Diagnostico**. No ADB, o aparelho precisa aparecer como `device`; se aparecer `unauthorized`, desbloqueie o celular e aceite novamente a autorizacao RSA.

## Branding Aquino na build compilada

Se voce ja possui a build base dentro de `Android_Dex/`, execute:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Patch-CompiledUi.ps1
```

O patch cria `app.so.upstream-backup` antes de alterar a interface compilada.
