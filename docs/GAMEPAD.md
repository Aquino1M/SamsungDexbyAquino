# Gamepad e KeyMapper Aquino

## Abrir dentro do Dex
Abra `scripts/Aquino-GameLauncher.ps1`, escolha o package e deixe **Abrir fora do Dex** desmarcado. A janela scrcpy é criada como filha da janela principal `Android_Dex`, ficando visualmente dentro do desktop do launcher.

## Editor estilo BlueStacks
Use **Editar Teclas / Gamepad** ou Configurações > Jogos, Gamepad e Atualizações > Configurar Jogos e Gamepad.

1. Abra o jogo dentro do Dex.
2. Capture a janela.
3. Escolha uma tecla ou botão do controle.
4. Clique na posição correspondente do controle touch.
5. Para joysticks virtuais, use **Adicionar analógico ESQ/DIR** e clique no centro do joystick.
6. Salve e ative o perfil.

Os perfis ficam em `config/keymaps/<package>.json`. O runtime aceita teclado/mouse e bindings `PAD_*`, incluindo gatilhos e direções dos dois analógicos.
