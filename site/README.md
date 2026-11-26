# Paylaşım alanı (evkahvesi.app)

Paylaşılan tarif bağlantılarının (`https://evkahvesi.app/r/...`) uygulamada açılması ve uygulaması olmayanın mağazaya yönlendirilmesi için yayımlanacak statik site (KHV-FR-SOC-003, KHV-ARC-003).

| Dosya | Görevi |
| --- | --- |
| `.well-known/assetlinks.json` | Android App Links doğrulaması |
| `.well-known/apple-app-site-association` | iOS Universal Links doğrulaması |
| `404.html`, `redirect.js` | `/r/<tarif>` yolları: uygulamayı açmayı dener, olmazsa mağazaya gider |
| `.nojekyll` | GitHub Pages'in `.well-known` klasörünü yayımlaması için |

## Yayından önce doldurulacak yer tutucular

`tool/fill_site.sh` betiği hepsini bir kerede doldurur.

| Yer tutucu | Nereden |
| --- | --- |
| `__ANDROID_PACKAGE__` | Uygulama kimliği (`applicationId`) |
| `__PLAY_APP_SIGNING_SHA256__` | Play Console > Kurulum > Uygulama imzalama > SHA-256 |
| `__APPLE_TEAM_ID__` | developer.apple.com > Membership > Team ID |
| `__IOS_BUNDLE_ID__` | Xcode > Runner > Bundle Identifier |
| `__APP_STORE_ID__` | App Store Connect > Uygulama > Apple ID (sayı) |

## GitHub Pages ile yayın

1. Depo > Settings > Pages > Source: GitHub Actions.
2. `.github/workflows/pages.yml` bu klasörü yayımlar.
3. Settings > Pages > Custom domain: `evkahvesi.app`; alan adı sağlayıcısında GitHub Pages DNS kayıtlarını ekleyin.
4. Doğrulama: `https://evkahvesi.app/.well-known/assetlinks.json` açılmalı.
