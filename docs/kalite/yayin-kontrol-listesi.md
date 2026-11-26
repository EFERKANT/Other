# Yayın kontrol listesi

Her sürüm mağazaya gönderilmeden önce kaliteci bu listeyi doldurur ve sürüm notuna ekler (KHV-NFR-025, NFR-043). MHG dokümanının yayın öncesi geçitlerinden uyarlanmıştır.

Sürüm: `x.y.z` · Tarih: · Kaliteci:

## 1. Otomatik kapılar

- [ ] `main` üzerinde CI yeşil: `core`, `app`, `android`, `izlenebilirlik`
- [ ] Son gecelik stres testi yeşil
- [ ] `python3 tool/trace.py --check` temiz; istisnalar ürün sahibince onaylı
- [ ] Release APK/AAB her mimaride 50 MB altında (KHV-NFR-032)

## 2. Platform yerelliği

- [ ] Android: geri hareketi, kenardan kaydırma, sistem çubuğu inset'leri (KHV-HMI-026, HMI-027)
- [ ] iOS: kenardan geri kaydırma, güvenli alan

## 3. Ergonomi ve erişilebilirlik

- [ ] Rehber mod 1 metreden 1,5 saniyede okunuyor (KHV-HMI-002) — 3 kişiyle
- [ ] TalkBack ile ve VoiceOver ile tam demleme (KHV-HMI-031, NFR-008)
- [ ] En büyük yazı boyutunda tüm MVP ekranları (KHV-HMI-028)

## 4. Renk ve kontrast

- [ ] Açık ve koyu temada golden görüntüler incelendi (KHV-HMI-034, HMI-036)

## 5. Dikkat ve gecikme

- [ ] Fiziksel cihaz matrisinde soğuk açılış ≤1,5 s, TTI <3 s, takılan kare oranı (KHV-NFR-001, NFR-023, NFR-024)

## 6. İlk kullanım

- [ ] Temiz kurulumda hesap ve izin istenmeden 3 ekranda ilk demleme (KHV-HMI-038)
- [ ] Bildirim izni yalnız ilk demlemede, ön izin ekranından sonra (KHV-HMI-037)

## 7. Rıza simetrisi

- [ ] Analitik ve çökme raporu varsayılan kapalı; aç/kapat eşit ağırlıkta (KHV-HMI-039)
- [ ] App Store gizlilik beyanı ve Google Play veri güvenliği formu gerçek davranışla aynı (KHV-NFR-035)
- [ ] Yeni üçüncü taraf SDK yok veya lisansı kayıtlı (KHV-NFR-045)

## 8. Davranışsal kullanılabilirlik

- [ ] Bu sürümde değişen akışlar için en az 5 kişiyle görev testi; SUS ≥ 75 (KHV-HMI-041, Bölüm 12.4)

## 9. Cihazda manuel senaryolar

- [ ] [Manuel senaryoların](manuel-senaryolar.md) hepsi geçti veya bulgusu açıldı
- [ ] Açık Ö1/Ö2 hata yok

## 10. Sürüm kaydı

- [ ] Sürüm numarası semantik; değişiklik notu karşılanan gereksinim kimliklerini listeliyor (KHV-NFR-043)
- [ ] İçerik paketi sürümü artırıldı (içerik değiştiyse)

Onay: Kaliteci ______ · Ürün sahibi ______
