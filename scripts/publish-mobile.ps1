#Requires -Version 5.1
<#
Üç mobil uygulamanın APK’sını GitHub Release’e yükler (aynı ada sahip varlığın üstüne yazar).

fabrika360-updates kökünden:
  .\scripts\publish-mobile.ps1
  .\scripts\publish-mobile.ps1 -FabrikaSuiteRoot "..\Fabrika360Suite"
  .\scripts\publish-mobile.ps1 -VardiyaApk "C:\path\Vardiya360Mobil-v26.04.3.8-release.apk"

Önkoşul: `gh auth login` (repo: ilyasyesildevelop/fabrika360-updates)
#>

param(
    [string] $Repo = "ilyasyesildevelop/fabrika360-updates",
    [string] $FabrikaSuiteRoot = "",
    [string] $VardiyaApk = "",
    [string] $PerformansApk = "",
    [string] $UretimApk = ""
)

$ErrorActionPreference = 'Stop'

function Get-ReleaseTagFromApkUrl([string]$apkUrl) {
    $marker = '/releases/download/'
    $i = $apkUrl.IndexOf($marker)
    if ($i -lt 0) { throw "apkUrl beklenen formatta değil: $apkUrl" }
    $rest = $apkUrl.Substring($i + $marker.Length)
    return ($rest.Split('/')[0])
}

function Get-UpdateSpec($repoRoot, $slug, $explicitApkPath, $fabrikaRoot) {
    $vj = Join-Path $repoRoot "$slug/version.json"
    $j = Get-Content $vj -Raw | ConvertFrom-Json
    $tag = Get-ReleaseTagFromApkUrl $j.apkUrl
    $leaf = Split-Path $j.apkUrl -Leaf
    $path = $explicitApkPath
    if ([string]::IsNullOrWhiteSpace($path) -and -not [string]::IsNullOrWhiteSpace($fabrikaRoot)) {
        $subdir = switch ($slug) {
            'vardiya360' { 'Vardiya360Mobil' }
            'performans360' { 'Performans360Mobil' }
            'uretim360' { 'Uretim360Mobil' }
        }
        $path = Join-Path $fabrikaRoot "$subdir/app/build/outputs/apk/release/$leaf"
    }
    return @{ Tag = $tag; Leaf = $leaf; Path = $path }
}

$updatesRoot = Split-Path $PSScriptRoot -Parent
if ([string]::IsNullOrWhiteSpace($FabrikaSuiteRoot)) {
    $candidate = Join-Path $updatesRoot '..\Fabrika360Suite'
    if (Test-Path (Join-Path $candidate 'Vardiya360Mobil')) {
        $FabrikaSuiteRoot = (Resolve-Path $candidate).Path
    }
}

$specs = @(
    (Get-UpdateSpec $updatesRoot 'vardiya360' $VardiyaApk $FabrikaSuiteRoot)
    (Get-UpdateSpec $updatesRoot 'performans360' $PerformansApk $FabrikaSuiteRoot)
    (Get-UpdateSpec $updatesRoot 'uretim360' $UretimApk $FabrikaSuiteRoot)
)

foreach ($s in $specs) {
    if (-not (Test-Path $s.Path)) {
        Write-Warning "APK bulunamadı (atlanıyor): $($s.Path)`n  Tag: $($s.Tag) — dosyayı -VardiyaApk / -PerformansApk / -UretimApk ile verin."
        continue
    }
    Write-Host ">>> gh release upload $($s.Tag) < $($s.Leaf)> --clobber"
    & gh release upload $s.Tag $s.Path --clobber --repo $Repo
    if ($LASTEXITCODE -ne 0) { throw "Yükleme başarısız: $($s.Tag)" }
}

Write-Host "`nTamam. Uygulamalar GitHub Contents API ile version.json okuyor; URL sabit olduğu sürece commite gerek yok."
