$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$appRoot = Split-Path -Parent $PSScriptRoot

function Write-ProtoIcon([string]$RelativePath, [int]$Size) {
    $target = Join-Path $appRoot $RelativePath
    $bitmap = New-Object System.Drawing.Bitmap($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::FromArgb(16, 17, 15))
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(213, 246, 108))
    $points = @(
        [System.Drawing.PointF]::new($Size * 0.57, $Size * 0.18),
        [System.Drawing.PointF]::new($Size * 0.29, $Size * 0.55),
        [System.Drawing.PointF]::new($Size * 0.49, $Size * 0.55),
        [System.Drawing.PointF]::new($Size * 0.40, $Size * 0.82),
        [System.Drawing.PointF]::new($Size * 0.72, $Size * 0.43),
        [System.Drawing.PointF]::new($Size * 0.53, $Size * 0.43)
    )
    $graphics.FillPolygon($brush, $points)
    $bitmap.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
    $brush.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

Write-ProtoIcon 'web/favicon.png' 64
foreach ($iconSize in @(192, 512)) {
    Write-ProtoIcon "web/icons/Icon-$iconSize.png" $iconSize
    Write-ProtoIcon "web/icons/Icon-maskable-$iconSize.png" $iconSize
}
foreach ($density in @(@('mdpi',48),@('hdpi',72),@('xhdpi',96),@('xxhdpi',144),@('xxxhdpi',192))) {
    Write-ProtoIcon "android/app/src/main/res/mipmap-$($density[0])/ic_launcher.png" $density[1]
}
$iconManifest = Get-Content (Join-Path $appRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json') -Raw | ConvertFrom-Json
foreach ($icon in $iconManifest.images) {
    $pointSize = [double]($icon.size.Split('x')[0])
    $scale = [double]($icon.scale.TrimEnd('x'))
    Write-ProtoIcon ('ios/Runner/Assets.xcassets/AppIcon.appiconset/' + $icon.filename) ([int]($pointSize * $scale))
}
Write-Output 'Proto app icons generated for web, Android, and iOS.'
