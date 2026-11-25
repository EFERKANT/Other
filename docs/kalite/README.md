# Kalite süreci

Ev Kahvesi'nde kalite üç katmanda sağlanır: otomatik kapılar (her PR'da CI), otomatik kod incelemesi (her PR'da Claude) ve kalitecinin manuel doğrulaması (cihazda, kullanıcı bağlamında). Hiçbir katman diğerinin yerine geçmez.

## Akış

```
Gereksinim (doküman + matris)
   │
   ▼
Geliştirme ─► PR ─► CI kapıları ──► Otomatik inceleme ──► Kaliteci ──► Birleştirme
                     │ biçim          │ hata, güvenlik,     │ manuel senaryo,
                     │ analiz         │ Effective Dart,     │ cihaz, golden
                     │ testler        │ gereksinim uyumu    │ görüntü onayı
                     │ kapsam ≥%90    │                     │
                     │ izlenebilirlik │                     │
                     │ APK ≤50 MB     │                     │
                     ▼                ▼                     ▼
               Gecelik stres testleri          Sürüm öncesi kontrol listesi ─► Mağaza
```

## Roller

| Rol | Sorumluluk |
| --- | --- |
| Geliştirici | Gereksinimi testle birlikte gerçekler; test adına gereksinim kimliğini yazar; PR şablonunu doldurur |
| Kaliteci | Test planını yürütür, manuel ve cihaz senaryolarını koşar, hataları triyaj eder, sürüm kapısını onaylar ([rol tanımı](kaliteci.md)) |
| Ürün sahibi | Gereksinimleri ve istisnaları onaylar, açık konuları kapatır |
| Otomatik inceleme | Her PR'da hata, güvenlik ve standart ihlali arar; yorum bırakır, onay vermez |

## Belgeler

| Belge | Ne zaman |
| --- | --- |
| [Tamamlanma tanımı](tamamlanma-tanimi.md) | Her PR |
| [Kod inceleme listesi](kod-inceleme.md) | Her PR'da inceleyen |
| [Test planı](test-plani.md) | Sürüm planlarken, kaliteci |
| [Manuel test senaryoları](manuel-senaryolar.md) | Her sürüm adayı |
| [Hata yaşam döngüsü](hata-yasam-dongusu.md) | Hata açılırken ve kapatılırken |
| [Yayın kontrol listesi](yayin-kontrol-listesi.md) | Mağazaya göndermeden önce (KHV-NFR-025) |
| [Stres testleri](stres-testleri.md) | Gecelik ve sürüm öncesi |
| [Bulgular](bulgular.md) | Süreçte bulunan sorunların kaydı |
| [İzlenebilirlik](izlenebilirlik.md) | Otomatik üretilir |

## Kapılar

Birleştirme şu kapılar geçmeden yapılmaz (KHV-NFR-042): `core`, `app`, `android`, `izlenebilirlik` iş akışları yeşil; otomatik incelemede kritik bulgu yok; kaliteci onayı (insan kaliteci atandıktan sonra, CODEOWNERS ile).

Ana dal korumasını depo yöneticisi açar: Settings > Branches > `main` > "Require a pull request", "Require status checks" (yukarıdaki dört iş), "Require review from Code Owners".

## Matris ve depo

Paylaşılan izlenebilirlik matrisi (Claude Sheets) gereksinim ve senaryoların kaynağıdır. `matris.csv` onun anlık görüntüsüdür; matriste satır eklenir veya öncelik değişirse CSV de güncellenir. `tool/trace.py --json` hangi gereksinimin hangi testte geçtiğini verir; matrisin "Durum" sütunu buna göre güncellenebilir.
