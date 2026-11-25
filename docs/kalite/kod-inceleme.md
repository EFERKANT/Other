# Kod inceleme listesi

Linter'ın yakalayamadığı kurallar (KHV-NFR-022) ve projeye özgü riskler. İnceleyen her maddeyi PR üzerinde kontrol eder; otomatik inceleme de bu listeyi kullanır.

## Doğruluk

- [ ] Zaman, `DateTime.now()` yerine `clockProvider` veya `monotonicMsProvider` ile alınıyor (test edilebilirlik, KHV-FR-BRW-011)
- [ ] Zamanlayıcı mantığı monotonik saate dayanıyor; duvar saati yalnız kesinti sonrası kurtarmada
- [ ] Dial-in her durumda en fazla bir öneri üretiyor (KHV-FR-DIA-002)
- [ ] Veritabanı yazımları birbirine bağlıysa `transaction` içinde
- [ ] `ref` ve `context`, `await` sonrasında `mounted` kontrolüyle kullanılıyor; `dispose` içinde `ref` kullanılmıyor
- [ ] Platform eklentisi çağrıları hata verirse uygulama akışı sürüyor (izin reddi, ses motoru yok)

## Effective Dart (linter dışı)

- [ ] DO: adlar ne olduğunu söylüyor; kısaltma yok (`brewRecipe`, `brRcp` değil)
- [ ] DO: `bool` alanlar `is`, `has`, `can` gibi okunuyor ya da sıfat (`archived`, `editable`)
- [ ] PREFER: değişmez model (`@immutable`, `final` alanlar, `copyWith`)
- [ ] AVOID: `dynamic` ve kontrolsüz `as`; JSON okumada türler açıkça doğrulanıyor
- [ ] DO: doc comment ilk cümlesi tek başına anlaşılır; gereksinim kimliği parantez içinde
- [ ] PREFER/AVOID kuralından sapma varsa PR'da gerekçesi yazıldı (KHV-NFR-018)

## Gizlilik ve güvenlik

- [ ] Kişisel veri (e-posta, cihaz kimliği, konum) paylaşım bağlantısına, kayda veya günlüğe girmiyor (KHV-FR-SOC-010)
- [ ] Analitik ve çökme raporu rıza olmadan çalışmıyor; varsayılan kapalı (KHV-NFR-017, NFR-033)
- [ ] Dışarıdan gelen veri (paylaşım bağlantısı, yedek dosyası, terazi) doğrulanmadan kullanılmıyor
- [ ] Tanınmayan terazi cihazına yazma komutu yok (KHV-FR-SCL-010)
- [ ] Yeni izin isteniyorsa önce faydasını açıklayan ekran var (KHV-HMI-037, SCL-007)

## Arayüz

- [ ] Dokunma hedefi en az 48x48 dp, geri alınamaz işlem 56 dp (KHV-HMI-025)
- [ ] Rehber modda birincil bilgi en büyük öğe; dokunmadan ilerlenebiliyor (KHV-HMI-001, HMI-006)
- [ ] En büyük yazı boyutunda ve yatay ekranda taşma yok (KHV-HMI-019, HMI-028)
- [ ] Bilgi yalnız renkle verilmiyor (KHV-HMI-024)
