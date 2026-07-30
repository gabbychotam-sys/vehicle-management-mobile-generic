Add-Type -AssemblyName System.Drawing

function Draw([int]$S) {
  $bmp = New-Object System.Drawing.Bitmap $S, $S
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'; $g.TextRenderingHint = 'AntiAliasGridFit'
  $f = $S / 256.0

  $rect = New-Object System.Drawing.Rectangle 0,0,$S,$S
  $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.Color]::FromArgb(39,174,96), [System.Drawing.Color]::FromArgb(20,110,60), 50)
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $r = [int](52 * $f); if ($r -lt 2) { $r = 2 }
  $path.AddArc(0,0,$r,$r,180,90); $path.AddArc($S-$r,0,$r,$r,270,90); $path.AddArc($S-$r,$S-$r,$r,$r,0,90); $path.AddArc(0,$S-$r,$r,$r,90,90); $path.CloseFigure()
  $g.FillPath($brush, $path)

  $emojiFont = New-Object System.Drawing.Font "Segoe UI Emoji", ([single](130*$f)), ([System.Drawing.FontStyle]::Regular)
  $fmt = New-Object System.Drawing.StringFormat
  $fmt.Alignment = [System.Drawing.StringAlignment]::Center
  $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
  $g.DrawString("🚗", $emojiFont, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF(0,0,$S,$S)), $fmt)

  $g.Dispose(); return $bmp
}

$pngSizes = 32,152,167,180,192,512
foreach ($s in $pngSizes) {
  $b = Draw $s
  $b.Save("$PSScriptRoot\icon-$s.png", [System.Drawing.Imaging.ImageFormat]::Png)
  $b.Dispose()
}

# favicon.ico from small sizes
$icoSizes = 16,32,48
$pngs = @()
foreach ($s in $icoSizes) { $b = Draw $s; $ms = New-Object System.IO.MemoryStream; $b.Save($ms,[System.Drawing.Imaging.ImageFormat]::Png); $pngs += ,($ms.ToArray()); $b.Dispose() }
$ico = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter $ico
$bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$icoSizes.Count)
$offset = 6 + (16 * $icoSizes.Count)
for ($i=0; $i -lt $icoSizes.Count; $i++) {
  $s = $icoSizes[$i]; $len = $pngs[$i].Length
  $bw.Write([byte]($(if($s -ge 256){0}else{$s}))); $bw.Write([byte]($(if($s -ge 256){0}else{$s})))
  $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([uint16]1); $bw.Write([uint16]32)
  $bw.Write([uint32]$len); $bw.Write([uint32]$offset); $offset += $len
}
foreach ($p in $pngs) { $bw.Write($p) }
$bw.Flush()
[System.IO.File]::WriteAllBytes("$PSScriptRoot\favicon.ico", $ico.ToArray()); $ico.Dispose()

"done"
