# Ev Kahvesi: depo kuralları

Bu dosya hem bu depoda çalışan Claude oturumları hem de PR'lardaki otomatik kod incelemesi için kuraldır.

## Proje

- Flutter 3.50.1 / Dart 3.14. Kod standardı Effective Dart (gereksinim dokümanı Bölüm 8.1).
- `packages/kahve_core`: saf Dart iş kuralları, Flutter'a bağımlı olamaz (KHV-NFR-040). Yeni iş kuralı buraya.
- `app`: Flutter arayüzü. Riverpod 3 (`Notifier`, `AsyncNotifier`), go_router, Drift. Material bileşenleri `package:material_ui/material_ui.dart` ile içe aktarılır.
- `app/assets/content/bundle.json` elle düzenlenmez; `tool/build_content.py` ile üretilir.
- Gereksinim kaynağı: Ev Kahvesi Uygulaması Gereksinim Dokümanı ve izlenebilirlik matrisi (`docs/kalite/matris.csv`).

## Kurallar

- Her davranış değişikliği testle gelir; test adında gereksinim kimliği yazılır: `'... (KHV-FR-BRW-005, HMI-022)'`. `python3 tool/trace.py --check` temiz kalmalı.
- Test ekleyen veya değiştiren her commit'ten önce `python3 tool/trace.py` çalıştırılır; üretilen `docs/kalite/izlenebilirlik.md` ve `manuel-senaryolar.md` aynı commit'e girer (CI güncel olmayan raporu reddeder).
- Zaman için `DateTime.now()` doğrudan kullanılmaz: `clockProvider` (duvar saati) ve `monotonicMsProvider` (zamanlayıcı).
- Platform servisleri (`lib/services/platform.dart`) arayüz arkasındadır; testte sahteleriyle değiştirilir.
- Renkler yalnız `ColorScheme` rolleriyle; `Color(0x...)` yalnız `theme.dart` içinde (test ile denetlenir).
- Kullanıcıya görünen metinler Türkçe; teknik terimler orijinal (bloom, grind size) ve sözlükte.
- Veritabanı şeması değişirse `schemaVersion` artar, `onUpgrade` adımı ve `test/data/schemas/schema_vN.sql` ile taşıma testi eklenir.
- Gizli bilgi, anahtar, `key.properties` ve `.jks` depoya girmez.

## Komutlar

```bash
cd packages/kahve_core && dart test
cd app && flutter test
cd app && flutter analyze --fatal-infos
python3 tool/trace.py --check
cd packages/kahve_core && dart test test_stres   # stres testleri
cd app && flutter test test_stres
```
