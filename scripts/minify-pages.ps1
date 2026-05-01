# Conservative inline-asset minifier for the kataloghub static pages.
# Reads each *.html file in $SourceDirs and writes a minified copy to a
# sibling "<name>.min" directory. Strips:
#   - HTML comments (except the <!-- src-guard:v1 --> marker)
#   - JS block comments and full-line // comments inside <script>
#   - CSS block comments and excess whitespace inside <style>
# Trailing inline JS comments are intentionally NOT stripped (would break
# protocol literals like https://). Run this before deploying.

[CmdletBinding()]
param(
  [string[]]$SourceDirs = @(
    'C:\Users\carin\OneDrive\Dokument\katolog\pages',
    'C:\Users\carin\OneDrive\Dokument\auto\whitelabel\pages'
  )
)

function Replace-Pattern([string]$text, [string]$pattern, $options, [scriptblock]$transform) {
  $regex = [regex]::new($pattern, $options)
  $sb = [System.Text.StringBuilder]::new()
  $lastEnd = 0
  foreach ($m in $regex.Matches($text)) {
    [void]$sb.Append($text.Substring($lastEnd, $m.Index - $lastEnd))
    [void]$sb.Append((& $transform $m))
    $lastEnd = $m.Index + $m.Length
  }
  [void]$sb.Append($text.Substring($lastEnd))
  return $sb.ToString()
}

function Strip-JsComments([string]$code) {
  # Block /* ... */ comments
  $code = [regex]::Replace($code, '/\*[\s\S]*?\*/', '')
  # Full-line // comments (after optional indent), preserves trailing-on-code //
  $code = [regex]::Replace($code, '(?m)^[ \t]*//[^\r\n]*\r?\n', '')
  # Collapse runs of blank lines
  $code = [regex]::Replace($code, '(\r?\n[ \t]*){2,}', "`n")
  # Trim trailing whitespace per line
  $code = [regex]::Replace($code, '[ \t]+\r?\n', "`n")
  return $code.Trim()
}

function Strip-CssComments([string]$code) {
  $code = [regex]::Replace($code, '/\*[\s\S]*?\*/', '')
  # Tighten whitespace around CSS punctuation
  $code = [regex]::Replace($code, '\s*([{};,>])\s*', '$1')
  $code = [regex]::Replace($code, ':\s+', ':')
  $code = [regex]::Replace($code, '(\r?\n[ \t]*){2,}', "`n")
  $code = [regex]::Replace($code, '[ \t]+', ' ')
  return $code.Trim()
}

function Minify-Html([string]$html) {
  $opts = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor `
          [System.Text.RegularExpressions.RegexOptions]::Singleline

  $html = Replace-Pattern $html '(<script\b[^>]*>)(.*?)(</script>)' $opts {
    param($m)
    return $m.Groups[1].Value + (Strip-JsComments $m.Groups[2].Value) + $m.Groups[3].Value
  }
  $html = Replace-Pattern $html '(<style\b[^>]*>)(.*?)(</style>)' $opts {
    param($m)
    return $m.Groups[1].Value + (Strip-CssComments $m.Groups[2].Value) + $m.Groups[3].Value
  }
  # Preserve the src-guard marker, strip every other HTML comment
  $html = Replace-Pattern $html '<!--([\s\S]*?)-->' ([System.Text.RegularExpressions.RegexOptions]::None) {
    param($m)
    if ($m.Groups[1].Value -match 'src-guard:v\d+') {
      return '<!--' + $m.Groups[1].Value + '-->'
    }
    return ''
  }
  return $html
}

$totalIn = 0; $totalOut = 0; $files = 0
foreach ($src in $SourceDirs) {
  if (-not (Test-Path $src)) { Write-Output "skip (missing): $src"; continue }
  $parent = Split-Path $src -Parent
  $leaf   = Split-Path $src -Leaf
  $out    = Join-Path $parent ($leaf + '.min')
  if (-not (Test-Path $out)) { New-Item -Path $out -ItemType Directory | Out-Null }

  Write-Output "==> $src"
  Get-ChildItem -Path $src -Filter *.html | ForEach-Object {
    $raw = [System.IO.File]::ReadAllText($_.FullName)
    $min = Minify-Html $raw
    $dst = Join-Path $out $_.Name
    [System.IO.File]::WriteAllText($dst, $min, [System.Text.UTF8Encoding]::new($false))
    $totalIn  += $raw.Length
    $totalOut += $min.Length
    $files++
    Write-Output ("  {0,-32} {1,8} -> {2,8}  (-{3,5}, {4,5:N1}%)" -f `
      $_.Name, $raw.Length, $min.Length, ($raw.Length - $min.Length), `
      (100.0 * (1 - ($min.Length / [double]$raw.Length))))
  }
  Write-Output "    wrote: $out"
  Write-Output ""
}
Write-Output ("done: {0} files, {1} bytes -> {2} bytes ({3:N1}% smaller)" -f `
  $files, $totalIn, $totalOut, `
  (100.0 * (1 - ($totalOut / [double]$totalIn))))
