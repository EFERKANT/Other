# Test planı

## Kapsam

MVP önceliğindeki tüm gereksinimler (Bölüm 10). S2 gereksinimlerinden yalnız gerçekleştirilmiş iş kuralları (terazi çekirdek kuralları) birim seviyesinde test edilir. Sunucu gerektiren gereksinimler [istisnalardadır](istisnalar.csv).

## Test seviyeleri

| Seviye | Araç | Nerede | Ne zaman | Sahip |
| --- | --- | --- | --- | --- |
| Birim | `dart test` | `packages/kahve_core/test` | Her PR (CI) | Geliştirici |
| Widget ve entegrasyon | `flutter test` | `app/test` | Her PR (CI) | Geliştirici |
| Golden | `flutter test` + `matchesGoldenFile` | `app/test/ui/goldens` | Her PR (CI), görüntü incelemesi kaliteci | Geliştirici + kaliteci |
| Erişilebilirlik kılavuzları | `meetsGuideline` | `app/test/ui/accessibility_test.dart` | Her PR (CI) | Geliştirici |
| Taşıma | Drift + ham SQLite | `app/test/data/migration_test.dart` | Her PR (CI) | Geliştirici |
| İzlenebilirlik | `tool/trace.py --check` | CI | Her PR | Otomatik |
| Stres | `--tags stres` | [stres testleri](stres-testleri.md) | Gecelik (CI) ve sürüm öncesi | Kaliteci |
| Cihaz performansı | `integration_test` + profil derleme | `app/integration_test` | Sürüm öncesi, fiziksel cihaz | Kaliteci |
| Manuel cihaz | [manuel senaryolar](manuel-senaryolar.md) | Cihaz matrisi | Her sürüm adayı | Kaliteci |
| Kullanılabilirlik | Mutfak oturumu, SUS, NASA-TLX | Bölüm 12.4 | MVP öncesi ve büyük arayüz değişikliğinde | Kaliteci |
| İçerik | Barista/SCA eğitimli uzman incelemesi | Bölüm 11 | İçerik değiştiğinde | Ürün sahibi |

## Cihaz matrisi (KHV-NFR-024)

Performans ölçümleri emülatörde veya debug derlemede yapılmaz; profil veya release derleme, fiziksel cihaz.

| Sınıf | Örnek | Neden |
| --- | --- | --- |
| Desteklenen en düşük bellekli Android | 3 GB RAM, Android 7 (API 24) | Soğuk açılış, takılma, bellek |
| Orta sınıf Android (referans cihaz) | Bölüm 10 açık konusu: seçilecek | KHV-NFR-001 ölçümü |
| Güncel amiral gemisi Android | Android 16 | Bildirim, izin ve edge-to-edge davranışı |
| En küçük desteklenen iPhone | iPhone SE | Güvenli alan, yazı boyutu |
| En büyük desteklenen iPhone | Pro Max | Yatay yerleşim, Dynamic Island |

Minimum işletim sistemi sürümleri Bölüm 10'da açık konudur; karar verilince tablo güncellenir.

## Giriş ve çıkış kriterleri

**Sürüm adayı testine giriş:** `main` üzerinde CI yeşil; son gecelik stres testi yeşil; izlenebilirlik temiz; sürüm notu taslağı hazır.

**Çıkış (sürüme onay):** Manuel senaryoların hepsi koşuldu; açık Ö1/Ö2 yok; performans hedefleri cihaz matrisinde ölçüldü; [yayın kontrol listesi](yayin-kontrol-listesi.md) imzalı.

## Ölçütler

| Ölçüt | Hedef | Kaynak |
| --- | --- | --- |
| İş katmanı satır kapsamı | ≥ %90 | CI (KHV-NFR-041) |
| MVP otomatik gereksinimlerde test bağı | %100 (istisnalar hariç) | `tool/trace.py` |
| Gecelik stres başarısı | %100 | CI |
| Soğuk açılış (TTID) | ≤ 1,5 s, 10 ölçüm ortalaması | Referans cihaz (KHV-NFR-001) |
| Zamanlayıcı sapması (10 dk) | ≤ ±0,5 s | Cihaz (KHV-NFR-002) |
| Kullanıcı algılı çökme oranı | < %1,09 | Android vitals (KHV-NFR-023) |
| SUS | ≥ 75 | Kullanılabilirlik oturumu |
| Ö1/Ö2 kaçak hata (sürüm sonrası) | 0 | Hata kayıtları |

## Riskler

| Risk | Etki | Önlem |
| --- | --- | --- |
| Arka planda zamanlayıcı ve bildirim davranışı üreticiye göre değişir (pil optimizasyonu) | Adım geçişi kaçar | Cihaz matrisinde Samsung, Xiaomi gibi agresif pil yönetimli cihaz; manuel TC-BRW-005 |
| iOS derlemesi yalnız Mac'te | iOS hataları geç bulunur | Mac'te haftalık iOS derlemesi; `tool/mac_setup.sh` |
| Golden görüntüleri platforma göre farklılaşır | Sahte kırmızı CI | Goldenlar yalnız Linux CI'da üretilir ve karşılaştırılır |
| Golden görüntüleri test yazı tipiyle (Ahem) üretilir, metin kutu olarak görünür | Örtüşme, taşma ve kesik metin görüntü incelemesinde kaçar (KB-015) | Kullanıcıya görünen değişiklikte cihaz veya simülatör denemesi; öneri: goldenları gerçek yazı tipiyle üretmek |
| Tat girdisinin kalitesi (kullanıcı ekşi/acıyı karıştırır) | Yanlış düzeltme | Kullanılabilirlik oturumunda tat seçimi tutarlılığı ölçülür (Bölüm 12.4) |
