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
