# Kalite bulguları

Süreçte bulunan, kök nedeni kayda değer sorunlar. Yeni Ö1/Ö2 hatalar ve süreç bulguları buraya eklenir.

| No | Tarih | Kaynak | Bulgu | Durum |
| --- | --- | --- | --- | --- |
| KB-001 | 2026-11-25 | Matris incelemesi | TC-ONB-003 "tüm ekipman silinince P1'e döner" diyor; Bölüm 2'ye göre ekipmanı olmayan kullanıcı P5 (Ekipman alacak kullanıcı). Kod Bölüm 2'yi izliyor (P5). Matris ve doküman çelişiyor. | **Karar bekliyor** (ürün sahibi) |
| KB-002 | 2026-11-25 | Erişilebilirlik testi | Rehber mod yatay telefonda 143 px taşıyordu (KHV-HMI-019). | Düzeltildi, testli |
| KB-003 | 2026-11-25 | Hata mesajı testi | İçerik yüklenemezse Riverpod'un otomatik yeniden denemesi yüzünden hata mesajı yerine sonsuz yükleme görünüyordu (KHV-HMI-042). | Düzeltildi, testli |
| KB-004 | 2026-11-25 | Tam test koşusu | Rehber mod, terazi kullanılmadan kapatılınca `dispose` sırasında `ref` kullanıldığı için hata veriyordu. | Düzeltildi, testli |
| KB-005 | 2026-11-24 | Yazı boyutu testi | En büyük yazı boyutunda sayı giriş satırları ve tarif ekranı alt düğmeleri taşıyordu (KHV-HMI-028). | Düzeltildi, testli |
| KB-006 | 2026-11-25 | İzlenebilirlik kapısı | MVP otomatik 113 gereksinimin 47'sinin testle ilişkisi yoktu; 41'i test yazılarak veya etiketlenerek, 6'sı gerekçeli istisnayla kapatıldı. | Kapandı |
| KB-007 | 2026-11-25 | Matris incelemesi | Matrisin "Durum" sütununun tamamı "Yazılmadı"; depodaki test durumu matrise yansımıyor. | Öneri: `tool/trace.py --json` ile güncelleme |
| KB-008 | 2026-11-25 | Doküman Rev1 (güncel) incelemesi | Bölüm 10 giriş paragrafı "topluluk özellikleri sonraki sürümlere bırakılmıştır" diyor; aynı bölümün tablosu topluluğu (Bölüm 16) S2'ye koyuyor. | **Karar bekliyor** (doküman düzeltmesi) |
| KB-009 | 2026-11-25 | Doküman Rev1 (güncel) incelemesi | S3 adayları hâlâ "kullanıcıların tarif paylaşımı" ve "aylık topluluk etkinliği"ni içeriyor; bunlar S2'deki KHV-FR-SOC-011..014 ve EVT modülüyle örtüşüyor. KHV-FR-SOC-007 (misafir tadım, S3) ile KHV-FR-EVT-009 (etkinlikte anonim puanlama, S2) da benzer. | **Karar bekliyor** (kapsam netleştirme) |
| KB-010 | 2026-11-25 | Matris incelemesi | KHV-NFR-013 metni "18 yaşından büyük olduğuna ilişkin beyan" içerecek şekilde değişti; matristeki TC-NFR-013 senaryosu hâlâ "yalnız e-posta ve takma ad" diyor. | **Matris güncellenmeli** |
| KB-011 | 2026-11-25 | Tasarım analizi | KHV-FR-SOC-012 oyu "tarifle demleme kaydı oluşturmuş" kullanıcıya sınırlıyor; ancak hesapsız kullanımda günlük yalnız cihazda (KHV-NFR-012). Sunucunun doğrulayabilmesi için oy verirken o tarifin demleme kaydının (yalnız tarif kimliği ve tarih) sunucuya bildirilmesi gerekir; bu, hesaplı kullanıcı senkronizasyonu (S2) ve KVKK aydınlatma metnine eklenmeli. | Öneri |
