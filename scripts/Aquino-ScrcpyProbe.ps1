Import-Module (Join-Path $PSScriptRoot 'Aquino.Gaming.psm1') -Force
$s=Resolve-AquinoScrcpy
Write-Host '=== Aquino Gaming / scrcpy Probe ===' -ForegroundColor Cyan
Write-Host "scrcpy: $s"
Write-Host "versão: $(Get-AquinoScrcpyVersion -ScrcpyPath $s)"
Write-Host "`n=== Encoders do aparelho ===" -ForegroundColor Yellow
Get-AquinoScrcpyEncoders -ScrcpyPath $s | ForEach-Object { Write-Host $_ }
Write-Host "`nCodec automático escolhido: $(Resolve-AquinoVideoCodec -Preferred auto -ScrcpyPath $s)" -ForegroundColor Green
Write-Host "`nRecursos usados pelo Gaming Hub: --new-display, --flex-display, --max-fps, --video-codec, --keyboard=uhid, --mouse=uhid, --gamepad=uhid."
Read-Host 'Pressione Enter para fechar'
