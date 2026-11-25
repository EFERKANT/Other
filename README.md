# Ev Kahvesi

Evde kahve hazırlayan kullanıcıya elindeki ekipmana göre adım adım rehberlik eden, demleme sonrasında tada göre bir sonraki deneme için **tek ve somut** düzeltme öneren Flutter uygulaması.

Bu depo, *Ev Kahvesi Uygulaması Gereksinim Dokümanı Rev1*'deki MVP çekirdek döngüsünü (tarif → rehberli demleme → tat geri bildirimi → düzeltme) gerçekler.

## Yapı

| Dizin | İçerik |
| --- | --- |
| `packages/kahve_core` | Flutter'dan bağımsız saf Dart iş kuralları (KHV-NFR-040): hesaplayıcı, ölçekleme, dial-in motoru, zamanlayıcı, stok/tazelik, profil atama, paylaşım doğrulama, Türkçe arama ve sayı biçimi |
| `app` | Flutter uygulaması (Riverpod, go_router, Drift) |
| `app/assets/content/bundle.json` | Gömülü içerik: 9 yöntem, başlangıç tarifleri, düzeltme kuralları, sözlük, ekipman rehberi ve katalog (KHV-NFR-026, KHV-CNT-002) |
| `tool/build_content.py` | İçerik paketini üreten betik. İçerik değişince sürüm numarasını artırın |

## Çalıştırma

Gereken Flutter sürümü 3.50.1 (Dart 3.14).

```bash
cd app
flutter pub get
dart run build_runner build
flutter run
```

Android APK (Android SDK gerekir):

```bash
cd app
flutter build apk
```

Testler:

```bash
cd packages/kahve_core && dart test
cd app && flutter test
```

Golden görüntüleri güncellemek için `flutter test --update-goldens` kullanın.

## Kodlama standardı

Effective Dart (Bölüm 8.1). CI şunları zorunlu tutar: `dart format`, statik analiz (`flutter_lints`, çekirdekte ek olarak `public_member_api_docs`), tüm testler ve çekirdek katmanda en az %90 satır kapsamı (`.github/workflows/ci.yml`).

## Gereksinim kapsamı

| Modül | Durum | Not |
| --- | --- | --- |
| ONB Kurulum ve ekipman profili | Uygulandı | ONB-001..005; öğütücü, terazi ve kettle ilk kullanımda sorulur (HMI-016) |
| RCP Tarif ve hesaplayıcı | Uygulandı | RCP-001..008, 010..014. RCP-009 (°F) S2 |
| BRW Rehber mod ve zamanlayıcı | Uygulandı | BRW-001..013. BRW-012: sessiz modda ses sistemin ses kanalına bırakılır; sessiz mod algılaması yerel kod gerektirir |
| DIA Tat teşhisi ve dial-in | Uygulandı | DIA-001..006, Bölüm 6 kural 1-5. DIA-007 S2 |
| EQP Ekipman rehberi | Uygulandı | EQP-001..006 |
| LOG Günlük ve çekirdek | Uygulandı | LOG-001..004, 006..009. LOG-005 (CSV) S2 |
| SET Ayarlar | Uygulandı | SET-001..003; yedekleme dışa/içe aktarma (NFR-030) |
| HLP Yardım | Uygulandı | HLP-001..003; hata bildirimi sistem paylaşım menüsüyle, cihaz bilgisi yalnız onayla |
| ENG Kullanım sıklığı | Uygulandı (MVP) | ENG-001..005, 008, 009. ENG-006/007 S2 |
| SOC Sosyal | Uygulandı (MVP) | SOC-001..004, 009, 010. SOC-005/006 S2 |
| ARC Altyapı | Uygulandı | ARC-001..006; özellik bayrakları içerik paketinde (`flags`) |
| HMI | Uygulandı | iOS Live Activity (HMI-022) hariç; Android'de kalıcı bildirim ve geri sayım |

### Yayın öncesi yapılması gerekenler

- **Paylaşım alanı:** `https://evkahvesi.app/r/...` bağlantıları için alan adı ve `/.well-known/assetlinks.json` (Android) ile `apple-app-site-association` (iOS) yayımlanmalı. Uygulaması olmayan alıcı bu sayfadan mağazaya yönlendirilir. Alan adı `lib/services/platform.dart` içindeki `shareBaseUrl` sabitindedir. Alan adı hazır olana kadar `evkahvesi://r/...` şeması çalışır.
- **iOS:** Universal Links için Xcode'da Associated Domains yeteneği, kilit ekranı için Live Activity widget uzantısı eklenmeli (Apple geliştirici hesabı gerektirir).
- **Android:** Uygulama kimliği (`com.evkahvesi.ev_kahvesi`) ve imzalama yapılandırması kesinleştirilmeli.

### Dokümandaki çelişkiler için verilen kararlar

1. **Tat girişi (DIA-001 / HMI-013):** İki boyutlu alan kullanılır. Alanda gösterilemeyen "hem ekşi hem acı" ve "düz/aromasız" ayrı onay kutularıyla alınır. Ekran okuyucu için alanın yanında seçim düğmeleri vardır.
2. **Uyarı kanalları (BRW-003 / HMI-005):** Kanallar ayrı ayrı kapatılabilir, ancak açık kanal sayısı ikinin altına inemez.
3. **Token (NFR-015):** MVP'de hesap olmadığından kimlik doğrulama S2'ye bırakıldı.
4. **Bölüm 6, kural 4:** Aynı yönde iki ardışık düzeltmeden sonra tat ters yöne dönerse uygulama bir önceki ayara dönmeyi önerir.
