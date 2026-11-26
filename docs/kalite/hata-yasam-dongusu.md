# Hata yaşam döngüsü

## Önem

| Seviye | Tanım | Örnek | Hedef süre |
| --- | --- | --- | --- |
| Ö1 Kritik | Çökme, veri kaybı, emniyet riski, gizlilik ihlali | Günlük kaybı; sıcak su adımında emniyet uyarısı yok | Sürüm durdurulur, 1 gün |
| Ö2 Yüksek | Ana akış bozuk, geçici çözüm yok | Zamanlayıcı adımı geçirmiyor; yanlış düzeltme önerisi | Sürümden önce |
| Ö3 Orta | Geçici çözümü olan hata | Filtre sıfırlanmıyor | Sonraki sürüm |
| Ö4 Düşük | Görünüm, metin | Hizalama, yazım | Planlanır |

## Durumlar

```
Yeni ─► Triyaj ─► Onaylandı ─► Düzeltiliyor ─► Doğrulanacak ─► Kapandı
            │                                        │
            └─► Reddedildi (yeniden üretilemedi,     └─► Yeniden açıldı
                tasarım gereği, kopya)
```

- **Triyaj:** Kaliteci haftada en az iki kez yapar; önem, gereksinim kimliği ve yeniden üretme adımları netleşir.
- **Düzeltiliyor:** Düzeltme PR'ı hatayı yeniden üreten bir test içerir. Test adında hata numarası ve gereksinim kimliği yazar.
- **Doğrulanacak:** Kaliteci düzeltmeyi bildirildiği ortamda dener; geçerse kapatır.
- **Kapandı:** Ö1 ve Ö2 hatalar [bulgular](bulgular.md) dosyasına kök nedeniyle eklenir.

## Sürüm kuralı

Açık Ö1 veya Ö2 varken sürüm çıkmaz. Ö3 sayısı 10'u geçerse sürüm toplantısında değerlendirilir.
