# Kaliteci rolü

## Amaç

Ev Kahvesi'nin, gereksinim dokümanındaki davranışı gerçek mutfak koşullarında, gerçek cihazlarda ve gerçek kullanıcılarla gösterdiğini doğrulamak. Otomatik testlerin göremediğini görmek: elleri ıslak, gözü kettle'da, telefonu tezgahta duran kullanıcı (Bölüm 12.1).

## Sorumluluklar

1. **Test planı:** [test planını](test-plani.md) her sürüm için günceller; cihaz matrisini (KHV-NFR-024) yönetir.
2. **Manuel ve cihaz testleri:** [Manuel senaryoları](manuel-senaryolar.md) her sürüm adayında koşar. Zamanlayıcı doğruluğu, arka plan bildirimleri, kilit ekranı, TTS, ekran okuyucu ve performans ölçümleri bu kapsamdadır.
3. **PR doğrulaması:** Kullanıcıya görünen değişiklik içeren PR'larda değişikliği cihazda dener, golden görüntülerini inceler ve PR şablonundaki "Kaliteci notu" bölümünü doldurur.
4. **Hata yönetimi:** Hataları triyaj eder, önemini belirler, düzeltmeyi doğrular ([hata yaşam döngüsü](hata-yasam-dongusu.md)).
5. **Matris:** Paylaşılan izlenebilirlik matrisinin "Durum" sütununu günceller; `docs/kalite/matris.csv` ile senkron tutar.
6. **Sürüm kapısı:** [Yayın kontrol listesini](yayin-kontrol-listesi.md) doldurur ve onaylar. Açık Ö1 veya Ö2 hata varsa sürümü durdurma yetkisi vardır.
7. **Kullanılabilirlik:** Bölüm 12.4'teki mutfak ortamı testlerini planlar ve yürütür: profil başına 5-8 katılımcı, SUS, NASA-TLX, sesli düşünme (KHV-HMI-041).
8. **Süreç iyileştirme:** Bulguları [bulgular](bulgular.md) dosyasına kök nedeniyle yazar; aynı sınıftan hata tekrarlıyorsa otomatik kontrol önerir.

## Haftalık ritim

| Gün | İş |
| --- | --- |
| Pazartesi | Gecelik stres testi sonuçları, hata triyajı |
| Her gün | Açılan PR'larda cihaz doğrulaması (kullanıcıya görünen değişiklikler) |
| Perşembe | Hata triyajı, matris durumu güncellemesi |
| Sürüm haftası | Manuel senaryolar, cihaz matrisi, yayın kontrol listesi |

## Yetki ve sınırlar

- CODEOWNERS ile kullanıcıya görünen kod ve içerikte zorunlu inceleyendir.
- Sürümü durdurabilir, kapsamı değiştiremez: kapsam kararı ürün sahibinindir.
- Otomatik incelemenin bulgularını onaylar veya reddeder; otomatik inceleme onay vermez.

## İlk 30 gün

1. **1. hafta:** Gereksinim dokümanını ve matrisi okur; uygulamayı her yöntemle bir kez demler; `flutter test` ve `tool/trace.py` çalıştırır.
2. **2. hafta:** Cihaz matrisini kurar (KHV-NFR-024); manuel senaryoların ilk tam koşusunu yapar; bulguları açar.
3. **3. hafta:** Açık karar bekleyen bulguları (ör. KB-001) ürün sahibiyle kapatır; matris "Durum" sütununu doldurur.
4. **4. hafta:** İlk kullanılabilirlik oturumu (en az 5 katılımcı); SUS ölçümü; sonuçları test planına ekler.

## Gereken beceriler

- Mobil uygulama testi (Android ve iOS), ekran okuyucu kullanımı
- Flutter test çıktısını ve CI kayıtlarını okuyabilme; basit test yazabilme tercih sebebi
- Kullanılabilirlik testi yürütme deneyimi
- Tercihen ev kahvesi demleme bilgisi (içerik ve tat doğruluğu için)
