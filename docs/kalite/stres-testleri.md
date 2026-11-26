# Stres testleri

Normal test koşusunu yavaşlatmamak için ayrı klasörlerdedir ve CI'da her gece çalışır (`.github/workflows/stres.yml`). Rastgele girdili testler bir **tohumla** üretilir: başarısız bir gece koşusu, kayıttaki tohumla yerelde aynen yeniden üretilir.

```bash
cd packages/kahve_core && STRES_TOHUM=123 dart test test_stres
cd app && STRES_TOHUM=123 flutter test test_stres
```

## İş kuralları (`packages/kahve_core/test_stres`)

| Test | Ne zorlar | Değişmez / eşik | Gereksinim |
| --- | --- | --- | --- |
| 10 dakika, düzensiz yoklama | 16-400 ms arası rastgele yoklama, arada 2 sn takılma | Toplam süre tam 600 sn; her geçiş planlanan anda veya en fazla bir yoklama gecikmesiyle, asla erken; sapma birikmez | KHV-NFR-002 |
| 100 ms yoklamada sapma | Uygulamanın gerçek yoklama aralığı, 40 adım | Her geçiş ±0,5 sn içinde | KHV-NFR-002 |
| Rastgele işlem dizileri | 2.000 koşu x 60 işlem: duraklat, devam, atla, geri al, onayla, yokla, sonlandırıp geri yükle (geriye giden saat dahil) | Adım indeksi sınırlarda; toplam süre asla geri gitmez; duraklatılmış süre ilerlemez; kalan süre negatif olmaz | KHV-NFR-003, KHV-FR-BRW-011 |
| 18 saatlik cold brew | Saniyelik yoklama, 64.800 tik | Adım tam 18 saatte biter | KHV-FR-BRW-009 |
| Dial-in | 50.000 rastgele değerlendirme ve geçmiş | Belirti varsa tek öneri ve gerekçe; dengeli fincanda öneri yok | KHV-FR-DIA-002, DIA-006 |
| Düzeltme zinciri | Her tarife 50 x 30 rastgele düzeltme | Doz, su, oran sonlu ve pozitif; sıcaklık 70-100 °C; adım süreleri pozitif | KHV-FR-DIA-005 |
| Paylaşım bağlantısı | 20.000 rastgele/bozuk/kesik bağlantı; 20.000 alanı bozulmuş JSON | Ya geçerli tarif ya gerekçeli doğrulama hatası; başka hata yok | KHV-FR-SOC-009 |
| Hesaplayıcı | 100.000 girdi: sıfır, negatif, NaN, sonsuz, çok büyük | Sonuç sonlu ve negatif değil ya da açık hata | KHV-FR-RCP-002 |
| Türkçe sayı girişi | 50.000 rastgele metin | Ayrıştırılan değer sonlu; biçimle-ayrıştır gidiş-dönüş tutarlı | KHV-NFR-031 |

## Uygulama (`app/test_stres`)

| Test | Ne zorlar | Eşik | Gereksinim |
| --- | --- | --- | --- |
| Büyük günlük sorgusu | 5.500 demleme (günde 3 x 5 yıl), 250 çekirdek | Liste sorgusu < 1 sn | KHV-NFR-023 |
| Dial-in zinciri sorgusu | Aynı veri | < 500 ms | KHV-FR-DIA-006 |
| Yedek | 5.500 kaydı dışa ve içe aktarma | Kayıpsız, toplam < 10 sn | KHV-NFR-030 |
| Hatırlatıcılar | Aynı veri | Hesap < 2 sn; günde en fazla 2 bildirim | KHV-FR-ENG-004, ENG-008 |
| Stok | 500 ardışık demleme | Stok negatife düşmez | KHV-FR-ENG-003 |
| Monkey | Rehber modda 400 rastgele işlem: ekrana dokunma, duraklat, atla, geri al, zaman sıçraması; akış bitince yeniden başlatma | Hiç hata yok; adım göstergesi her an tutarlı; oluşan kayıtlar geçerli | KHV-NFR-003, KHV-HMI-006, HMI-009 |
| Büyük liste | 2.000 kayıtlı günlükte filtre ve 40 hızlı kaydırma | Hata yok; filtre doğru | KHV-FR-LOG-002, KHV-NFR-023 |

Süre eşikleri CI makinesine göre geniştir; amaç kötüleşmeyi yakalamaktır. Gerçek performans fiziksel cihazda ölçülür.

## Fiziksel cihaz performansı (`app/integration_test`)

Kaliteci sürüm öncesi cihaz matrisinde çalıştırır ([test planı](test-plani.md)). Profil derleme, fiziksel cihaz:

```bash
cd app
flutter drive --profile --driver=test_driver/performans_driver.dart --target=integration_test/performans_test.dart -d CIHAZ_KIMLIGI
```

Rehber mod ve günlük kaydırmasında kare süreleri ölçülür; ortalama build veya p90 raster 16 ms'yi aşarsa koşu başarısız olur (KHV-NFR-023). Özet `build/*.timeline_summary.json` dosyalarına yazılır.

Soğuk açılış (KHV-NFR-001) için referans cihazda 10 ölçümün ortalaması:

```bash
flutter run --profile --trace-startup -d CIHAZ_KIMLIGI
```

`build/start_up_info.json` içindeki `timeToFirstFrameMicros` değeri 1.500.000'in altında olmalıdır.

## Henüz otomatik olmayanlar

- **10 dakikalık gerçek cihaz zamanlayıcı ölçümü** (TC-NFR-002): ön plan, arka plan, ekran kilidi, gelen arama. Kaliteci kronometreyle yapar; mantık doğruluğu yukarıdaki testlerle güvence altında.
- **Pil ve ısınma:** 30 dakikalık rehber mod açık ekranda pil tüketimi, cihaz matrisinde elle.
- **Bellek:** Uzun oturumda (100 demleme) bellek artışı, DevTools ile elle.
