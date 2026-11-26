# Ev Kahvesi

Evde kahve hazırlayan kullanıcıya elindeki ekipmana göre adım adım rehberlik eden, demleme sonrasında tada göre bir sonraki deneme için **tek ve somut** düzeltme öneren Flutter uygulaması.

Bu depo, *Ev Kahvesi Uygulaması Gereksinim Dokümanı Rev1*'deki MVP çekirdek döngüsünü (tarif → rehberli demleme → tat geri bildirimi → düzeltme) gerçekler.

## Yapı

| Dizin | İçerik |
| --- | --- |
| `packages/kahve_core` | Flutter'dan bağımsız saf Dart iş kuralları (KHV-NFR-040): hesaplayıcı, ölçekleme, dial-in motoru, zamanlayıcı, stok/tazelik, profil atama, paylaşım doğrulama, Türkçe arama ve sayı biçimi |
| `app` | Flutter uygulaması (Riverpod, go_router, Drift) |
| `app/assets/content/bundle.json` | Gömülü içerik: 9 yöntem, başlangıç tarifleri, düzeltme kuralları, sözlük ve ekipman seçim kriterleri (KHV-NFR-026, KHV-CNT-002) |
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

## Kalite süreci

Ayrıntılar [`docs/kalite/`](docs/kalite/README.md) altında: tamamlanma tanımı, kod inceleme ve yayın kontrol listeleri, test planı, kaliteci rolü, hata yaşam döngüsü, stres testleri ve bulgular.

- **İzlenebilirlik:** `python3 tool/trace.py --check`. MVP'de otomatik test olarak işaretlenmiş her gereksinim bir testte geçmeli ya da `docs/kalite/istisnalar.csv` içinde gerekçesiyle yer almalı. CI'da zorunlu.
- **Otomatik kod incelemesi:** `.github/workflows/claude-review.yml`; depo sırlarına `ANTHROPIC_API_KEY` eklenince her PR'da çalışır.
- **Stres testleri:** `test_stres/` klasörleri; CI'da her gece (`.github/workflows/stres.yml`).
- **Şablonlar:** PR şablonu ve hata/gereksinim issue şablonları `.github/` altında.

## Kodlama standardı

Effective Dart (Bölüm 8.1). CI şunları zorunlu tutar: `dart format`, statik analiz (`flutter_lints`, çekirdekte ek olarak `public_member_api_docs`), tüm testler ve çekirdek katmanda en az %90 satır kapsamı (`.github/workflows/ci.yml`).

## Gereksinim kapsamı

| Modül | Durum | Not |
| --- | --- | --- |
| ONB Kurulum ve ekipman profili | Uygulandı | ONB-001..005; öğütücü, terazi ve kettle ilk kullanımda sorulur (HMI-016). Marka/model serbest metinle girilir (KB-017) |
| RCP Tarif ve hesaplayıcı | Uygulandı | RCP-001..008, 010..014. RCP-009 (°F) S2 |
| BRW Rehber mod ve zamanlayıcı | Uygulandı | BRW-001..013. BRW-012: sessiz modda ses sistemin ses kanalına bırakılır; sessiz mod algılaması yerel kod gerektirir |
| DIA Tat teşhisi ve dial-in | Uygulandı | DIA-001..006, Bölüm 6 kural 1-5. DIA-007 S2 |
| EQP Ekipman rehberi | Uygulandı (karar KB-017) | EQP-001, 002, 004, 006. Ürün sahibi kararıyla marka/model önerileri, model sayfası ve bütçe filtresi kaldırıldı; EQP-003, EQP-005 ve CNT-004 gerekçeli istisna |
| LOG Günlük ve çekirdek | Uygulandı | LOG-001..004, 006..009. LOG-005 (CSV) S2 |
| SET Ayarlar | Uygulandı | SET-001..003; yedekleme dışa/içe aktarma (NFR-030) |
| HLP Yardım | Uygulandı | HLP-001..003; hata bildirimi sistem paylaşım menüsüyle, cihaz bilgisi yalnız onayla |
| ENG Kullanım sıklığı | Uygulandı (MVP) | ENG-001..005, 008, 009. ENG-006/007 S2 |
| SOC Sosyal | Uygulandı (MVP) | SOC-001..004, 009, 010. SOC-005/006 S2 |
| ARC Altyapı | Uygulandı | ARC-001..006; özellik bayrakları içerik paketinde (`flags`) |
| HMI | Uygulandı | iOS Live Activity (HMI-022) hariç; Android'de kalıcı bildirim ve geri sayım |
| ARC-007 Terazi arayüzü | Uygulandı (MVP) | Ortak `Scale` arayüzü; MVP gerçekleştirimi elle giriş (`ManualScale`). Tartılan doz ve ölçülen su demleme kaydına yalnız sonuç olarak yazılır (SCL-009, şema v2) |
| Topluluk: PRO, SOC-011..014, EVT, ADM-006, NFR-046 (S2, Bölüm 16) | Çekirdek kurallar hazır | Profil ve Instagram görünürlüğü, gizli profil, etkinlik ilanı ve adres görünürlüğü (24 saat), adresin 30 günde silinmesi, 18 yaş beyanı, kontenjan ve yedek liste, engelleme, nötr ret bildirimi, anonim etkinlik tadımı, tarif oyları ve "yeni" etiketi, şikayet önceliği, bağlantı/telefon/e-posta tespiti. Sunucu, hesap ve arayüz sunucu altyapısı kararını bekliyor |
| SCL Bluetooth terazi | Uygulandı (karar KB-028, S2'den MVP'ye) | Desteklenen: BOOKOO Themis Mini ve Ultra (üreticinin MIT lisanslı açık protokolü). Tanınmayan terazide dinleme modu: açık protokoller denenir, kullanıcı değeri onaylar, cihaza komut yazılmaz (SCL-003, SCL-010). İzin açıklaması (SCL-007), destek talebinde yalnız yayınlanan ad (SCL-006). Bluetooth: universal_ble (BSD-3). Gerçek cihazla deneme kalitecide (SCL-002/003/004/007/008) |

### Mac'te kurulum

```bash
git clone https://github.com/EFERKANT/Other.git ev-kahvesi
cd ev-kahvesi
tool/mac_setup.sh --keystore
```

Betik Xcode, Homebrew, CocoaPods ve Flutter'ı denetler, eksikleri kurar, `pod install` ve imzasız iOS derlemesi yapar. `--keystore` ile Android yayın anahtarını `~/.ev-kahvesi/` altına oluşturur ve `app/android/key.properties` dosyasını yazar (ikisi de depoya girmez). `key.properties` yoksa release derlemesi debug anahtarıyla imzalanır.

### Yayın öncesi yapılması gerekenler

- **Paylaşım alanı:** `site/` klasörü yayımlanmaya hazır (doğrulama dosyaları ve mağazaya yönlendiren sayfa). Yer tutucular `tool/fill_site.sh` ile doldurulur, `.github/workflows/pages.yml` GitHub Pages'e yayımlar; ayrıntılar `site/README.md` içinde. Alan adı `lib/services/platform.dart` içindeki `shareBaseUrl` sabitindedir. Alan adı hazır olana kadar `evkahvesi://r/...` şeması çalışır.
- **iOS:** Universal Links için Xcode'da Associated Domains yeteneği, kilit ekranı için Live Activity widget uzantısı eklenmeli (Apple geliştirici hesabı gerektirir).
- **Android:** Uygulama kimliği (`com.evkahvesi.ev_kahvesi`) ve imzalama yapılandırması kesinleştirilmeli.

### Dokümandaki çelişkiler için verilen kararlar

1. **Tat girişi (DIA-001 / HMI-013):** İki boyutlu alan kullanılır. Alanda gösterilemeyen "hem ekşi hem acı" ve "düz/aromasız" ayrı onay kutularıyla alınır. Ekran okuyucu için alanın yanında seçim düğmeleri vardır.
2. **Uyarı kanalları (BRW-003 / HMI-005):** Kanallar ayrı ayrı kapatılabilir, ancak açık kanal sayısı ikinin altına inemez.
3. **Token (NFR-015):** MVP'de hesap olmadığından kimlik doğrulama S2'ye bırakıldı.
4. **Terazi (Bölüm 15):** Desteklenen terazi listesinde (`scales`) BOOKOO Themis Mini ve Ultra var (KB-028). SCL-001'e göre bir model ancak resmi SDK, açık yayımlanmış protokol veya üreticinin yazılı izniyle ve lisans referansı kaydedilerek eklenebilir; referansı veya parmak izi olmayan kayıt içerik doğrulamasından geçmez.
5. **Bölüm 6, kural 4:** Aynı yönde iki ardışık düzeltmeden sonra tat ters yöne dönerse uygulama bir önceki ayara dönmeyi önerir.
