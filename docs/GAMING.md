# Aquino Gaming Hub v0.3

Criado por **Aquino / Aquino1M**.

## O que está implementado

- Janelas Android independentes por package com `--new-display` e `--start-app`.
- Flex display: redimensionar a janela do PC redimensiona o display Android virtual.
- Tela cheia e presets ultrawide.
- Teclado físico nativo via UHID.
- Mouse físico relativo/capturado via UHID.
- Gamepad nativo encaminhado pelo scrcpy via SDL3/UHID.
- Editor visual de mapeamento para jogos touchscreen.
- Esquema de controles para tap, toque repetido, swipe, D-pad, FPS-look, ações estilo MOBA/tap, scripts e gamepad-to-touch.
- Fallback XInput para controles Xbox-compatible em jogos que aceitam apenas touchscreen.
- Metas de 30/60/90/120/144/165 FPS.
- Seleção automática de encoder/codec (AV1 → H.265 → H.264 → VP9 → VP8 conforme disponibilidade do aparelho).
- Perfis de baixa latência.

## Modos recomendados

### O jogo aceita teclado/mouse/gamepad
Use o **Aquino Game Launcher** com UHID ativado. É o caminho de menor latência e evita emulação de touchscreen.

### O jogo aceita apenas touchscreen
Abra o jogo e depois inicie o **Aquino KeyMapper**. Capture a janela do scrcpy, escolha o tipo de controle e clique na posição do botão Android. Salve e ative o perfil.

`F12` encerra o runtime de mapeamento. `F1` alterna a captura de mouse FPS quando o perfil possui um controle `FPSLook`.

## Gamepad

Para suporte nativo, o scrcpy 4 usa SDL3 e encaminha o gamepad ao Android por UHID. Para títulos sem suporte Android a gamepad, o KeyMapper consegue associar bindings como `PAD_A`, `PAD_B`, `PAD_X`, `PAD_Y`, gatilhos, D-pad e direções do analógico esquerdo a pontos touchscreen.

DualSense e controles DirectInput devem primeiro usar o modo nativo SDL/UHID do scrcpy. O fallback XInput-to-touch é voltado principalmente a controles Xbox/XInput.

## Editor visual

O editor captura a janela do jogo e grava coordenadas normalizadas entre 0 e 1. Isso permite reaproveitar o perfil mesmo quando a resolução do display muda.

Tipos disponíveis no editor:

- `Tap`: um toque ao pressionar a tecla.
- `RepeatedTap`: toque repetido enquanto a tecla/botão estiver pressionado.
- `Swipe`: gesto entre dois pontos.
- `DPad`: movimento direcional baseado em um joystick virtual.
- `FPSLook`: fallback de visão pelo movimento relativo do mouse.
- `MOBASkill`: ponto de habilidade; atualmente usa comportamento de toque no fallback externo.
- `Script`: sequência configurável de taps/swipes/esperas via JSON.
- `GamepadTap`: botão XInput associado a um toque.

`Zoom` aparece reservado no esquema do editor, mas zoom multitouch verdadeiro requer um bridge Android dedicado e não é anunciado como concluído nesta versão.

## Exemplos

- `config/keymaps/example-fps.json`: WASD, clique para atirar, pulo, recarga e mouse-look.
- `config/keymaps/example-gamepad-touch.json`: A/B/X/Y e analógico esquerdo convertidos em ações touchscreen.

## Pesquisa de concorrentes

A UX foi inspirada em recursos descritos publicamente por ferramentas de jogos Android como BlueStacks, NoxPlayer e MuMuPlayer: pontos de toque, toque repetido, D-pad, modo de tiro/mouse, mapeamento de gamepad, controles MOBA e esquemas personalizados. Nenhum código-fonte ou binário proprietário desses produtos é incluído. A implementação deste repositório é independente e construída sobre ADB + scrcpy.

## Limitação importante

Injeção touchscreen por `adb shell input` é um fallback de compatibilidade e não possui o mesmo pipeline interno de multitouch de um emulador. Para jogos que reconhecem dispositivos físicos, **UHID é sempre o modo preferido**. Um bridge Android opcional poderá futuramente melhorar gestos simultâneos sem exigir alteração da interface Flutter original.
