# Rebuild the two A4-aspect paper albedos without additional dependencies.
# Windows PowerShell 5.1 / PowerShell 7 on Windows; no font files are copied.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$textureDirectory = Join-Path $projectRoot 'Assets\Kitchen\Textures'
[System.IO.Directory]::CreateDirectory($textureDirectory) | Out-Null
$width = 1024
$height = 1448
$supersampling = 2
$paperColor = [System.Drawing.Color]::FromArgb(246, 237, 216)
$inkColor = [System.Drawing.Color]::FromArgb(79, 65, 48)
$oliveColor = [System.Drawing.Color]::FromArgb(100, 110, 74)
$faintColor = [System.Drawing.Color]::FromArgb(202, 194, 169)
$ink = [System.Drawing.SolidBrush]::new($inkColor)
$olive = [System.Drawing.SolidBrush]::new($oliveColor)
$linePen = [System.Drawing.Pen]::new($inkColor, 5.5)
$linePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$linePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$linePen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
$rulePen = [System.Drawing.Pen]::new($faintColor, 2)
$format = [System.Drawing.StringFormat]::GenericTypographic.Clone()
$format.FormatFlags = [System.Drawing.StringFormatFlags]::NoWrap

function New-PaperBitmap {
    $bitmap = [System.Drawing.Bitmap]::new($width * $supersampling, $height * $supersampling)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear($paperColor)
    $graphics.ScaleTransform($supersampling, $supersampling)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $random = [System.Random]::new(260117)
    $grain = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(8, 117, 96, 64))
    for ($i = 0; $i -lt 18000; $i++) {
        $x = [single]($random.NextDouble() * $width)
        $y = [single]($random.NextDouble() * $height)
        $graphics.FillEllipse($grain, $x, $y, 0.6, 0.6)
    }
    $grain.Dispose()
    return @{ Bitmap = $bitmap; Graphics = $graphics }
}

function Write-PaperBitmap($paper, [string]$filename) {
    $output = [System.Drawing.Bitmap]::new($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($output)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($paper.Bitmap, [System.Drawing.Rectangle]::new(0, 0, $width, $height))
    $path = Join-Path $textureDirectory $filename
    $output.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $output.Dispose()
    $paper.Graphics.Dispose()
    $paper.Bitmap.Dispose()
    Write-Output "ORDER_PAPER_TEXTURE_OK $path ${width}x${height}"
}

function Draw-Label($graphics, [string]$text, [single]$size, [single]$x, [single]$y, $brush, [bool]$bold = $false) {
    $style = if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $font = [System.Drawing.Font]::new('Microsoft YaHei', $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
    $graphics.DrawString($text, $font, $brush, [System.Drawing.PointF]::new($x, $y), $format)
    $font.Dispose()
}

$blank = New-PaperBitmap
Write-PaperBitmap $blank 'order-paper-blank.png'
$paper = New-PaperBitmap
$g = $paper.Graphics

# The first 12% is intentionally clear for the physical brass clip.
Draw-Label $g '订单 02' 25 112 214 $olive
Draw-Label $g '早餐之后' 58 108 266 $ink $true
$g.DrawLine($rulePen, 112, 370, 912, 370)

# A shallow plate: actual vector strokes, not a font/emoji glyph.
$g.DrawEllipse($linePen, 134, 496, 254, 101)
$g.DrawEllipse($linePen, 166, 515, 190, 62)
$plateProfile = [System.Drawing.Drawing2D.GraphicsPath]::new()
$plateProfile.AddBezier(135, 548, 148, 632, 373, 632, 387, 548)
$g.DrawPath($linePen, $plateProfile)
$plateProfile.Dispose()
Draw-Label $g '餐盘' 44 476 494 $ink
Draw-Label $g '× 2' 53 758 493 $ink
Draw-Label $g '0 / 2 已完成' 25 479 565 $olive
$g.DrawLine($rulePen, 112, 708, 912, 708)

# Mug body and open handle, matching the standard mug silhouette.
$mug = [System.Drawing.Drawing2D.GraphicsPath]::new()
$mug.AddBezier(172, 806, 173, 843, 171, 899, 190, 924)
$mug.AddBezier(190, 924, 212, 952, 285, 951, 306, 924)
$mug.AddBezier(306, 924, 322, 901, 320, 843, 321, 806)
$g.DrawPath($linePen, $mug)
$mug.Dispose()
$g.DrawEllipse($linePen, 172, 783, 149, 47)
$handle = [System.Drawing.Drawing2D.GraphicsPath]::new()
$handle.AddBezier(323, 829, 395, 814, 391, 915, 318, 909)
$handle.AddBezier(320, 848, 365, 839, 363, 893, 321, 889)
$g.DrawPath($linePen, $handle)
$handle.Dispose()
Draw-Label $g '马克杯' 44 476 814 $ink
Draw-Label $g '× 1' 53 758 813 $ink
Draw-Label $g '0 / 1 已完成' 25 479 885 $olive
$g.DrawLine($rulePen, 112, 1033, 912, 1033)

Draw-Label $g '完成' 31 112 1100 $olive
Draw-Label $g '0 / 3' 46 767 1087 $ink
$track = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(218, 214, 191))
$g.FillRectangle($track, 112, 1171, 800, 8)
$track.Dispose()
Draw-Label $g '洗净后放入沥水架' 29 112 1232 $ink

Write-PaperBitmap $paper 'order-paper-breakfast.png'
$format.Dispose()
$linePen.Dispose()
$rulePen.Dispose()
$ink.Dispose()
$olive.Dispose()
