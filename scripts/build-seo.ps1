param([string]$SiteUrl = 'https://rodiart.gr/')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$dist = Join-Path $root 'dist'
$SiteUrl = $SiteUrl.TrimEnd('/') + '/'
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Write-Utf8($path, $value) { [IO.File]::WriteAllText($path, $value, $utf8) }
function Escape($value) { [System.Net.WebUtility]::HtmlEncode([string]$value) }
$source = [IO.File]::ReadAllText((Join-Path $dist 'script.js'))
$template = [IO.File]::ReadAllText((Join-Path $root 'site/index.html'))
$languages = @('el', 'ru', 'uk', 'en')
$texts = @{}
# Read the site's literal translation objects, including later overrides.
foreach ($lang in $languages) {
  $texts[$lang] = @{}
  $patterns = @()
  $patterns += '(?s)\b' + $lang + ':\s*\{(.*?)\n  \}'
  $patterns += '(?s)Object\.assign\(translations\.' + $lang + ',\s*\{(.*?)\}\);'
  $patterns += '(?s)translations\.' + $lang + '\s*=\s*\{(.*?)\n\};'
  $blocks = foreach ($pattern in $patterns) { [regex]::Matches($source, $pattern) }
    foreach ($block in ($blocks | Sort-Object Index)) {
      foreach ($pair in [regex]::Matches($block.Groups[1].Value, '(\w+):\s*''((?:\\.|[^''\\])*)''')) {
        $texts[$lang][$pair.Groups[1].Value] = $pair.Groups[2].Value.Replace('\n', "`n").Replace("\'", "'").Replace('\\', '\')
      }
    }
}
$urls = @{ru = $SiteUrl; el = ($SiteUrl + 'el/'); uk = ($SiteUrl + 'uk/'); en = ($SiteUrl + 'en/')}
$locales = @{el='el_GR'; ru='ru_RU'; uk='uk_UA'; en='en_GB'}
foreach ($lang in $languages) {
  $text = $texts[$lang]
  $prefix = if ($lang -eq 'ru') { '' } else { '../' }
  $html = $template.Replace('<html lang="ru">', ('<html lang="' + $lang + '">'))
  $html = [regex]::Replace($html, '(?s)(<([a-z0-9]+)\b[^>]*\bdata-i18n="([^"]+)"[^>]*>).*?(</\2>)', {
    param($m)
    $key = $m.Groups[3].Value
    if (!$text.ContainsKey($key)) { throw "Missing translation: $lang/$key" }
    $m.Groups[1].Value + (Escape $text[$key]).Replace("`n", '<br>') + $m.Groups[4].Value
  })
  foreach ($kind in @(@('data-alt','alt'), @('data-label','aria-label'))) {
    $html = [regex]::Replace($html, '<[^>]+\b' + $kind[0] + '="([^"]+)"[^>]*>', {
      param($m)
      $key = $m.Groups[1].Value
      if (!$text.ContainsKey($key)) { throw "Missing translation: $lang/$key" }
      [regex]::Replace($m.Value, '(?<![\w-])' + $kind[1] + '="[^"]*"', ($kind[1] + '="' + (Escape $text[$key]) + '"'))
    })
  }
  $html = [regex]::Replace($html, '<title>.*?</title>', ('<title>' + (Escape $text.pageTitle) + '</title>'))
  $html = [regex]::Replace($html, '<meta name="description"[^>]+>', ('<meta name="description" content="' + (Escape $text.description) + '">'))
  $html = [regex]::Replace($html, '<button type="button" data-lang="([^"]+)"(.*?)</button>', {
    param($m)
    $target = $m.Groups[1].Value
    $href = if ($target -eq 'ru') { $prefix + 'index.html' } else { $prefix + $target + '/index.html' }
    $attrs = [regex]::Replace($m.Groups[2].Value, ' aria-pressed="[^"]+"', '')
    if ($target -eq $lang) { $attrs = $attrs.Replace('>', ' aria-current="page">') }
    '<a data-lang="' + $target + '" href="' + $href + '" hreflang="' + $target + '"' + $attrs + '</a>'
  })
  $html = $html.Replace('href="styles.css"', ('href="' + $prefix + 'styles.css"')).Replace('src="script.js"', ('src="' + $prefix + 'script.js"')).Replace('src="assets/', ('src="' + $prefix + 'assets/')).Replace('href="assets/', ('href="' + $prefix + 'assets/')).Replace('poster="assets/', ('poster="' + $prefix + 'assets/'))
  $metadata = @('<link rel="canonical" href="' + $urls[$lang] + '">')
  foreach ($other in $languages) { $metadata += '<link rel="alternate" hreflang="' + $other + '" href="' + $urls[$other] + '">' }
  $metadata += '<link rel="alternate" hreflang="x-default" href="' + $SiteUrl + '">'
  $metadata += '<meta name="robots" content="index, follow, max-image-preview:large">'
  $properties = @{'og:type'='website'; 'og:site_name'='RodiArt'; 'og:title'=$text.pageTitle; 'og:description'=$text.description; 'og:url'=$urls[$lang]; 'og:locale'=$locales[$lang]; 'og:image'=($SiteUrl+'assets/dress-fuchsia.jpg'); 'og:image:alt'=$text.dress1Alt}
  foreach ($key in ($properties.Keys | Sort-Object)) { $metadata += '<meta property="' + $key + '" content="' + (Escape $properties[$key]) + '">' }
  $metadata += '<meta name="twitter:card" content="summary_large_image">'
  $business = @{'@type'='LocalBusiness'; '@id'=($SiteUrl+'#atelier'); name='RodiArt'; url=$SiteUrl; description=$text.description; image=@(($SiteUrl+'assets/dress-fuchsia.jpg'), ($SiteUrl+'assets/dress-monochrome.jpg')); address=@{'@type'='PostalAddress'; streetAddress='Efstathiadi 28'; addressLocality='Argyroupoli'; postalCode='164 52'; addressCountry='GR'}; sameAs=@('https://www.instagram.com/rodi_art_greece/'); hasMap='https://maps.app.goo.gl/AoLhNDZnJi8kwEkVA'; knowsLanguage=@('el','ru','uk','en')}
  $page = @{'@type'='WebPage'; '@id'=$urls[$lang]; url=$urls[$lang]; name=$text.pageTitle; description=$text.description; inLanguage=$lang; about=@{'@id'=($SiteUrl+'#atelier')}}
  $schema = @{'@context'='https://schema.org'; '@graph'=@($business,$page)} | ConvertTo-Json -Depth 12
  $metadata += '<script type="application/ld+json">' + $schema + '</script>'
  $html = $html.Replace('</head>', (($metadata -join "`n  ") + "`n</head>"))
  $folder = if ($lang -eq 'ru') { $dist } else { Join-Path $dist $lang }
  [IO.Directory]::CreateDirectory($folder) | Out-Null
  Write-Utf8 (Join-Path $folder 'index.html') $html
}
$sitemap = '<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
foreach ($lang in $languages) { $sitemap += '<url><loc>' + (Escape $urls[$lang]) + '</loc></url>' }
Write-Utf8 (Join-Path $dist 'sitemap.xml') ($sitemap + '</urlset>')
Write-Utf8 (Join-Path $dist 'robots.txt') ("User-agent: *`nAllow: /`n`nSitemap: " + $SiteUrl + "sitemap.xml`n")
Write-Output 'Generated four static language pages, structured data, sitemap and robots.txt.'
