Add-Type -AssemblyName System.Drawing

function New-BrandImage {
  param(
    [string]$Path,
    [int]$Width,
    [int]$Height,
    [string]$ColorA,
    [string]$ColorB,
    [string]$ColorC,
    [string]$Tagline
  )

  $bmp = New-Object System.Drawing.Bitmap($Width, $Height)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

  $rect = New-Object System.Drawing.Rectangle(0, 0, $Width, $Height)
  $a = [System.Drawing.ColorTranslator]::FromHtml($ColorA)
  $b = [System.Drawing.ColorTranslator]::FromHtml($ColorB)
  $c = [System.Drawing.ColorTranslator]::FromHtml($ColorC)

  $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $a, $b, 35)
  $blend = New-Object System.Drawing.Drawing2D.ColorBlend
  $blend.Colors = @($a, $b, $c)
  $blend.Positions = @(0.0, 0.6, 1.0)
  $bg.InterpolationColors = $blend
  $g.FillRectangle($bg, $rect)

  $shape1 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(34, 255, 255, 255))
  $shape2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(28, 0, 0, 0))
  $shape3 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(55, 255, 255, 255))

  $g.FillEllipse($shape1, -120, [int]($Height * 0.20), [int]($Width * 0.95), [int]($Height * 0.55))
  $g.FillEllipse($shape2, [int]($Width * 0.35), [int]($Height * 0.48), [int]($Width * 0.90), [int]($Height * 0.60))

  $poly = [System.Drawing.Point[]]@(
    (New-Object System.Drawing.Point([int]($Width * 0.08), [int]($Height * 0.75))),
    (New-Object System.Drawing.Point([int]($Width * 0.44), [int]($Height * 0.55))),
    (New-Object System.Drawing.Point([int]($Width * 0.83), [int]($Height * 0.72))),
    (New-Object System.Drawing.Point([int]($Width * 0.50), [int]($Height * 0.92)))
  )
  $g.FillPolygon($shape3, $poly)

  $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(80, 255, 255, 255), 4)
  $g.DrawLine($pen, 40, [int]($Height * 0.70), $Width - 40, [int]($Height * 0.70))

  $titleFont = New-Object System.Drawing.Font('Segoe UI', [float]($Width / 11), [System.Drawing.FontStyle]::Bold)
  $subFont = New-Object System.Drawing.Font('Segoe UI', [float]($Width / 28), [System.Drawing.FontStyle]::Regular)
  $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 255, 255, 255))
  $soft = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(205, 255, 255, 255))

  $fmt = New-Object System.Drawing.StringFormat
  $fmt.Alignment = [System.Drawing.StringAlignment]::Near
  $fmt.LineAlignment = [System.Drawing.StringAlignment]::Near

  $g.DrawString('BIG CART', $titleFont, $white, [System.Drawing.RectangleF]::new(56, [float]($Height * 0.08), [float]($Width * 0.80), [float]($Height * 0.30)), $fmt)
  $g.DrawString($Tagline, $subFont, $soft, [System.Drawing.RectangleF]::new(58, [float]($Height * 0.76), [float]($Width * 0.85), [float]($Height * 0.15)), $fmt)

  $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Jpeg)

  $fmt.Dispose(); $titleFont.Dispose(); $subFont.Dispose(); $white.Dispose(); $soft.Dispose(); $pen.Dispose()
  $shape1.Dispose(); $shape2.Dispose(); $shape3.Dispose(); $bg.Dispose(); $g.Dispose(); $bmp.Dispose()
}

New-BrandImage -Path 'assets/images/carousel_1.jpg' -Width 1201 -Height 1600 -ColorA '#95574C' -ColorB '#C68A67' -ColorC '#2E2220' -Tagline 'Autumn essentials for your daily style'
New-BrandImage -Path 'assets/images/carousel_2.jpg' -Width 1067 -Height 1600 -ColorA '#215662' -ColorB '#3E8A97' -ColorC '#12222B' -Tagline 'Minimal lines. Elevated street confidence'
New-BrandImage -Path 'assets/images/carousel_3.jpg' -Width 1280 -Height 1600 -ColorA '#2A3F78' -ColorB '#5B82BF' -ColorC '#181F3C' -Tagline 'Weekend capsule with bold silhouettes'
New-BrandImage -Path 'assets/images/welcome_bg.jpg' -Width 1000 -Height 1500 -ColorA '#7A3E37' -ColorB '#AD6D5A' -ColorC '#27201D' -Tagline 'Discover your signature everyday look'

Get-ChildItem assets/images -File | ForEach-Object {
  $img = [System.Drawing.Image]::FromFile($_.FullName)
  [PSCustomObject]@{
    Name = $_.Name
    Width = $img.Width
    Height = $img.Height
    SizeKB = [Math]::Round($_.Length / 1KB, 2)
  }
  $img.Dispose()
} | Sort-Object Name | Format-Table -AutoSize | Out-String
