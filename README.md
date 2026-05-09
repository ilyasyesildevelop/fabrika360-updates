# Fabrika360 güncelleme yayınları

Mobil uygulamalar (Vardiya, Performans, Üretim) `version.json` dosyasındaki **`latestVersionCode`**, **`latestVersionName`** ve **`apkUrl`** ile güncelleme kontrolü yapar. Kaynak URL olarak GitHub **Contents API** kullanılıyor; JSON gövdesi bazen doğrudan, bazen base64 olarak gelir (`UpdateService.kt` ikisini de destekler).

## Dizim

| Uygulama     | Dosya                         | Mobil `UPDATE_INFO_URL` (Fabrika360Suite) |
|-------------|-------------------------------|--------------------------------------------|
| Vardiya 360 | `vardiya360/version.json`     | `.../repos/ilyasyesildevelop/fabrika360-updates/contents/vardiya360/version.json?ref=master` |
| Performans  | `performans360/version.json`  | `.../contents/performans360/version.json?ref=master` |
| Üretim      | `uretim360/version.json`      | `.../contents/uretim360/version.json?ref=master` |

## `version.json` şeması

```json
{
  "latestVersionCode": 8,
  "latestVersionName": "26.04.3.8",
  "apkUrl": "https://github.com/ilyasyesildevelop/fabrika360-updates/releases/download/EK_ETIKET/APK_ADI.apk"
}
```

- **`latestVersionCode`**: Android `versionCode`; uygulamadaki değerden büyükse “yeni sürüm” sayılır.
- **`apkUrl`**: GitHub Releases’taki doğrudan indirme linki (`/releases/download/` …). Mobil uygulama bu adresi kullanıcıya açar/indirtir.

## Yeni APK (aynı sürüm, yeni ikili)

Kod düzelttiniz ama `versionCode` **artmadıysa**: yalnızca release altındaki APK’yı aynı adla yenileyin — `apkUrl` aynı kalır, `version.json` commit gerekmiyor.

PowerShell (`fabrika360-updates` kökünden, APK’lar varsayılan Gradle çıktısında ise):

```powershell
.\scripts\publish-mobile.ps1
```

Dosyalar başka klasördeyse:

```powershell
.\scripts\publish-mobile.ps1 `
  -VardiyaApk "D:\build\Vardiya360Mobil-v26.04.3.8-release.apk" `
  -PerformansApk "D:\build\Performans360-v26.04.2.6-release.apk" `
  -UretimApk "D:\build\Uretim360-v26.04.2.6-release.apk"
```

Önkoşul: [GitHub CLI](https://cli.github.com/) ve `gh auth login`.

## Yeni sürüm (versionCode / versionName artışı)

1. **Fabrika360Suite** içinde ilgili `app/build.gradle.kts`: `versionCode` ve `versionName` artırın; Android Studio’dan release APK üretin (çıktı adı `archivesName` ile üretilir).
2. GitHub’da **yeni release** oluşturun; etiket adı `version.json` içindeki `apkUrl` ile **birebir** uyumlu olsun.
   - Örnek etiketler: `vardiya-v26.04.3.8`, `performans-v26.04.2.6`, `uretim-v26.04.2.6`
3. APK’yı bu release’e yükleyin (asset adı, `apkUrl` son segmenti ile aynı olmalı).
4. Bu repoda ilgili `version.json` güncelleyin; `master`’a push edin.

Örnek `gh` ile yeni sürüm (tek seferde):

```text
gh release create vardiya-v26.04.3.9 "Vardiya360Mobil v26.04.3.9" --repo ilyasyesildevelop/fabrika360-updates
gh release upload vardiya-v26.04.3.9 "....\Vardiya360Mobil-v26.04.3.9-release.apk" --repo ilyasyesildevelop/fabrika360-updates
```

Ardından `vardiya360/version.json` içinde `latestVersionCode`, `latestVersionName` ve yeni `apkUrl` satırını güncelleyip commit/push.

## Masaüstü

`Fabrika360Desktop` güncellemeleri ayrı release etiketleriyle bu repoda tutulabilir (ör. `Fabrika360Desktop_v26.4.3`); mobil `version.json` dosyalarından bağımsızdır.
