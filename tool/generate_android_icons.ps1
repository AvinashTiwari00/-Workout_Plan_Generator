# Regenerate Android launcher resources from the supplied, unmodified logo.
# Run from the project root: powershell -File tool/generate_android_icons.ps1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path -Parent $PSScriptRoot
$logoPath = Join-Path $projectRoot 'assets/icons/app_icon.png'
$resRoot = Join-Path $projectRoot 'android/app/src/main/res'
$logo = [System.Drawing.Image]::FromFile($logoPath)
try {
    foreach ($density in @(
        @{ Name='mdpi'; Size=48; Layer=108 },
        @{ Name='hdpi'; Size=72; Layer=162 },
        @{ Name='xhdpi'; Size=96; Layer=216 },
        @{ Name='xxhdpi'; Size=144; Layer=324 },
        @{ Name='xxxhdpi'; Size=192; Layer=432 }
    )) {
        $folder = Join-Path $resRoot ('mipmap-' + $density.Name)
        New-Item -ItemType Directory -Force -Path $folder | Out-Null
        foreach ($variant in @('legacy','round','foreground')) {
            $size = if ($variant -eq 'foreground') { $density.Layer } else { $density.Size }
            $bitmap = New-Object System.Drawing.Bitmap($size, $size)
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear([System.Drawing.Color]::Transparent)
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                if ($variant -eq 'round') {
                    $clip = New-Object System.Drawing.Drawing2D.GraphicsPath
                    try { $clip.AddEllipse(0, 0, $size, $size); $graphics.SetClip($clip) }
                    finally { $clip.Dispose() }
                }
                # Keep the full logo within a centered 64dp box on a 108dp layer.
                # The lettering/figure remain inside the adaptive safe zone.
                $drawSize = if ($variant -eq 'foreground') { [int][Math]::Round($size * 64 / 108) } else { $size }
                $offset = [int][Math]::Round(($size - $drawSize) / 2)
                $graphics.DrawImage($logo, $offset, $offset, $drawSize, $drawSize)
                $fileName = switch ($variant) {
                    'legacy' { 'ic_launcher.png' }
                    'round' { 'ic_launcher_round.png' }
                    'foreground' { 'ic_launcher_foreground.png' }
                }
                $bitmap.Save((Join-Path $folder $fileName), [System.Drawing.Imaging.ImageFormat]::Png)
            } finally { $graphics.Dispose(); $bitmap.Dispose() }
        }
    }
} finally { $logo.Dispose() }
Write-Output 'Generated legacy, round, and adaptive foreground icons in five densities.'
