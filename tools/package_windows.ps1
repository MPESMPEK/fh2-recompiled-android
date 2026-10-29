# PowerShell script to package FH2 Windows Release
$ErrorActionPreference = "Stop"

$exe = Get-ChildItem -Path . -Filter "fh2.exe" -Recurse | Select-Object -First 1
if (-not $exe) {
    throw "fh2.exe not found in build directory!"
}
$outDir = $exe.DirectoryName
Write-Host "Found fh2.exe at: $outDir"
Get-ChildItem -Path $outDir

$distDir = "dist/fh2-windows-x64"
if (Test-Path $distDir) {
    Remove-Item -Path $distDir -Recurse -Force
}
New-Item -ItemType Directory -Path $distDir -Force

Write-Host "Copying binary and DLLs..."
Copy-Item "$outDir\fh2.exe" "$distDir/"
Get-ChildItem -Path . -Filter "*.dll" -Recurse | Where-Object { $_.FullName -notlike "*\dist\*" } | ForEach-Object {
    Write-Host "Staging DLL: $($_.FullName)"
    Copy-Item $_.FullName "$distDir/" -Force
}
if (Test-Path "$outDir\*.pdb") {
    Copy-Item "$outDir\*.pdb" "$distDir/"
}

$runD3D12Content = @"
@echo off
title FH2 Recompiled - DirectX 12
echo =========================================================
echo   FH2 Recompiled (Windows PC x64) - D3D12
echo =========================================================
echo.
echo Pastikan Anda memiliki game dump Forza Horizon 2 (Xbox 360).
echo Masukkan flag --game_data_root="C:\path\ke\folder_game" jika belum ada.
echo.
fh2.exe --gpu_plugin=xenos --gpu=d3d12 --gpu_allow_invalid_fetch_constants=true --mnk_mode=true --mnk_preset=race %*
pause
"@

$runVulkanContent = @"
@echo off
title FH2 Recompiled - Vulkan
echo =========================================================
echo   FH2 Recompiled (Windows PC x64) - Vulkan
echo =========================================================
echo.
echo Pastikan Anda memiliki game dump Forza Horizon 2 (Xbox 360).
echo Masukkan flag --game_data_root="C:\path\ke\folder_game" jika belum ada.
echo.
fh2.exe --gpu_plugin=xenos --gpu=vulkan --gpu_allow_invalid_fetch_constants=true --mnk_mode=true --mnk_preset=race %*
pause
"@

$readmeContent = @"
FH2 Recompiled for Windows PC (x64)
====================================
Kebutuhan Sistem:
- OS: Windows 10 / 11 64-bit
- GPU: DirectX 12 / Vulkan kompatibel

Cara Menjalankan:
1. Double-click run_d3d12.bat (DirectX 12) atau run_vulkan.bat (Vulkan).
2. Anda juga dapat memasukkan path folder game atau ISO langsung:
   fh2.exe --game_data_root="D:\Games\ForzaHorizon2" --gpu=d3d12 --mnk_mode=true --mnk_preset=race

Kontrol Keyboard (Mode Balap / Race Layout):
- W : Gas (Throttle)
- S : Rem (Brake)
- A / D : Belok Kiri / Kanan (Steer)
- Spasi : Rem Tangan (Handbrake / Tombol A)
- Panah / Mouse : Kamera
- I, J, K, L : D-Pad
- Enter : Start
- Esc / Tab : Back
- F4 : Menu Pengaturan / Remap Controller langsung di game
"@

[System.IO.File]::WriteAllText("$distDir/run_d3d12.bat", $runD3D12Content)
[System.IO.File]::WriteAllText("$distDir/run_vulkan.bat", $runVulkanContent)
[System.IO.File]::WriteAllText("$distDir/README.txt", $readmeContent, [System.Text.Encoding]::UTF8)

$zipPath = "dist/fh2-windows-x64.zip"
if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}

Compress-Archive -Path "$distDir/*" -DestinationPath $zipPath -Force
Write-Host "Package created successfully: $zipPath"
Get-Item $zipPath | Select-Object Name, Length, LastWriteTime
