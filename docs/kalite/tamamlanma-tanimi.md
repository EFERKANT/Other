# Tamamlanma tanımı

Bir iş, aşağıdakilerin hepsi sağlandığında tamamdır.

## Kod

- [ ] Gereksinimin tüm "normal durum" ve "sınır ve hata durumu" senaryoları (matris, sütun I ve J) karşılanıyor
- [ ] İş kuralı `packages/kahve_core` içinde, Flutter'dan bağımsız (KHV-NFR-040)
- [ ] Public API'lerde `///` doc comment var (KHV-NFR-021)
- [ ] `dart format` ve `flutter analyze --fatal-infos` temiz (KHV-NFR-019, NFR-020)
- [ ] Kullanıcıya görünen her metin Türkçe; hata mesajları ne olduğunu ve ne yapılacağını söylüyor (KHV-HMI-042)
- [ ] Renkler yalnız `ColorScheme` rolleriyle; kırmızı yalnız hata ve geri alınamaz işlemde (KHV-HMI-033, HMI-035)

## Test

- [ ] Otomasyonu "Otomatik" olan senaryo için test yazıldı; test adında gereksinim kimliği var
- [ ] İş katmanı kapsamı %90'ın altına düşmedi (KHV-NFR-041)
- [ ] Arayüz değiştiyse golden testler güncellendi ve görüntüler gözle incelendi
- [ ] Yeni ekranda dokunma hedefi, kontrast ve etiket kılavuzları testte (`test/ui/accessibility_test.dart`)
- [ ] Şema değiştiyse taşıma testi eklendi (KHV-NFR-028)
- [ ] Manuel veya yarı otomatik senaryolar için [manuel senaryolar](manuel-senaryolar.md) güncellendi
- [ ] Widget testi bileşeni gerçek ekrandaki üst yapısıyla (kaydırma, Scaffold, bildirim) çalıştırıyor; sürükleme testleri küçük adımlarla, ekranın görünen kısmında (KB-015)
- [ ] Kullanıcıya görünen değişiklik cihazda veya simülatörde denendi; otomatik testlerin geçmesi tek başına "tamam" sayılmaz (KB-015)

## Süreç

- [ ] PR şablonu dolduruldu; CI ve izlenebilirlik yeşil
- [ ] Otomatik inceleme bulguları yanıtlandı
- [ ] Kaliteci onayı alındı (insan kaliteci atandıktan sonra)
- [ ] README'deki gereksinim kapsamı tablosu güncel
