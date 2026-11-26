# Simge sözlüğü

Arayüzdeki her simgenin (`Icons.*`) tek bir anlamı ve net bir davranışı olmalıdır. Bu dosya her simgenin nerede kullanıldığını, ne anlama geldiğini, dokunulabilir olup olmadığını, dokununca ne olduğunu ve hangi gereksinime bağlandığını listeler. Kaynak: 2026-11-25 kod envanteri (KB-018).

Yeni simge eklerken veya bir simgeyi yeni bir yerde kullanırken bu tablo güncellenir; aynı simge ikinci bir anlamda kullanılmaz ([kod inceleme listesi](kod-inceleme.md)).

Sütunlar: **Dokunma**: "Düğme" dokunulabilir, "Gösterge" yalnız bilgi verir. **Gereksinim**: "Yok" olanlar ürün sahibinin gereksinim dokümanına eklemesi gereken davranışlardır.

## Çift anlamlı simgeler

| Simge | Eski çift anlam | Durum |
| --- | --- | --- |
| `star` / `star_border` | Favori ve puan | **Çözüldü (KB-026):** favori `bookmark` / `bookmark_border`; yıldız yalnız puan |
| `water_drop_outlined` | Ekşi tat ve su miktarı | **Çözüldü:** ekşi `science_outlined` (asidite), sulu `waves`; damla yalnız su |
| `local_fire_department_outlined` | Moka pot ve acı tat | **Çözüldü:** yöntemler artık kendi çizimleriyle (`MethodGlyph`); alev yalnız acı |
| `coffee` / `coffee_outlined` | Espresso ve "Demle" sekmesi | **Çözüldü:** espresso çizimle; fincan yalnız sekme |
| `grain` | Çekirdek ve öğütme | **Çözüldü:** öğütme `tune`; tane yalnız çekirdek |
| `check` | Rehber maddesi, seçildi, şüphe yok | **Kısmen:** rehber maddesi `thumb_up_alt_outlined`; "seçildi" ve "şüphe yok" (ikisi de olumlu onay) kaldı |
| `coffee_maker_outlined` | French press ve "Demleme araçları" | **Çözüldü:** French press çizimle; simge yalnız ayar bölümü |
| `stop` | Bitir (basılı tut) demlemeyi **kaydetmeden** bırakır | **Karar bekliyor (KB-025):** etiket "Demlemeyi bırak" mı, yoksa kayıt mı tutulmalı |

## Yöntem çizimleri

Yöntemler Material simgesiyle değil, "Sohbet" sahnesindeki kahve takımının küçük çizimiyle gösterilir (`lib/ui/scene.dart`, `MethodGlyph`): cezve, V60 damlatıcı, Chemex, espresso fincanı, French press, AeroPress, filtre makinesi, moka pot, cold brew kavanozu. Her yöntemin kendi çizimi vardır ve başka anlamda kullanılmaz. Aynı çizim ana ekranın sahnesinde (`CoffeeScene`, seçilen yönteme göre değişir) ve hazırlık ekranında (`MethodArt`) büyük olarak yer alır (KHV-HMI-016, KB-026).

## Durum gösteren simgeler

Simge, bir durumu gösteriyorsa bu durum kalıcı kaynaktan (veritabanı/ayar) okunmalı ve dokunuştan hemen sonra değişmelidir (KB-016).

| Simge | Yer | Durum kaynağı | Dokununca | Gereksinim | Etkisi testte |
| --- | --- | --- | --- | --- | --- |
| `bookmark` ↔ `bookmark_border` | Tarif ekranı üst çubuğu | Veritabanı `favorites` (kayıtlı tarif) | Favoriye ekler/çıkarır; simge ve ipucu değişir | KHV-FR-RCP-011 | Evet (KB-016) |
| `star` ↔ `star_border` (5 adet) | Tat ekranı puanı | Ekran durumu `_score` | Puanı seçer; seçilene kadar dolu | Yok (puan ölçeği tanımsız) | Kısmen |
| `pause` ↔ `play_arrow` | Rehberli demleme | Zamanlayıcı | Duraklatır / devam ettirir; "DURAKLATILDI" bandı | KHV-HMI-009 | Evet |
| `notification_important_outlined` ↔ `build_outlined` | Bakım kartı | Görev vadesi | Gösterge | KHV-FR-ENG-001 | Hayır |
| `check_circle` ↔ `lightbulb_outline` | Demleme kaydı, öneri satırı | Öneri uygulandı mı | Gösterge | KHV-FR-DIA-005 | Hayır |
| `grain` ↔ `inventory_2_outlined` | Çekirdek listesi | Çekirdek arşivde mi | Satıra dokununca düzenleme açılır | KHV-FR-LOG-008 | Kısmen |
| `check_circle_outline` ↔ `speed` | Espresso shot özeti | Süre aralıkta mı | Gösterge | Yok | Hayır |
| `priority_high` ↔ `check` | Tat sonucu kök neden listesi | Şüpheli kök neden | Gösterge | KHV-FR-DIA-0xx (kimlik yok) | Hayır |
| Sekme simgeleri (dolu ↔ boş) | Alt gezinme | Seçili sekme | Sekmeye geçer | Yok | Evet |

## Tüm simgeler

| Simge | Yer | Anlam | Dokunma | Gereksinim |
| --- | --- | --- | --- | --- |
| `coffee_maker_outlined` | Ayarlar | "Demleme araçları" bölümü | Düğme | KHV-FR-ONB-003 |
| `science_outlined`, `local_fire_department_outlined`, `waves`, `fitness_center`, `crop_square`, `check_circle_outline` | Tat notları | Ekşi, acı, sulu, yoğun, düz, dengeli | Gösterge (renk yanında) | KHV-HMI-024 |
| `water_drop_outlined` | Paylaşım kartı | Su miktarı | Gösterge | KHV-FR-SOC-001 |
| `tune` | Paylaşım kartı | Öğütme | Gösterge | KHV-FR-SOC-001 |
| `coffee` / `coffee_outlined`, `menu_book` / `menu_book_outlined`, `devices_other` / `devices_other_outlined`, `settings` / `settings_outlined` | Alt gezinme (dolu: seçili sekme) | Demle, Günlük, Ekipman, Ayarlar sekmeleri | Düğme | Yok |
| `add` | Sayı adımlayıcı, çekirdek, bakım, demleme | Artır / yeni ekle | Düğme | Bağlama göre (KHV-HMI-025) |
| `remove` | Sayı adımlayıcı | Azalt | Düğme | KHV-HMI-025 |
| `arrow_forward` | Kurulum "Devam" | Sonraki adım | Düğme | KHV-FR-ONB-001 |
| `thumb_up_alt_outlined` | Ekipman rehberi | "Dikkat edin" maddesi | Gösterge | KHV-FR-EQP-002 |
| `block` | Ekipman rehberi | "Kaçının" maddesi | Gösterge | KHV-FR-EQP-002 |
| `check` | Kurulum, tat sonucu | Seçildi / şüphe yok | Gösterge | Bağlama göre |
| `build_outlined` | Bakım, ayarlar | Bakım | Düğme (ayarlar), gösterge | KHV-FR-ENG-001 |
| `calculate_outlined` | Ana ekran | Hesaplayıcıyı aç | Düğme | KHV-FR-RCP-002 |
| `chevron_right` | Tarif satırı | Ayrıntıya git | Gösterge | Yok |
| `delete_forever_outlined` | Ayarlar | Tüm verileri sil | Düğme (onaylı) | KHV-NFR-0xx (kimlik bağlanmalı) |
| `delete_outline` | Demleme kaydı, çekirdek | Kaydı sil | Düğme | KHV-FR-LOG-00x |
| `description_outlined`, `gavel_outlined`, `info_outline` | Ayarlar | Lisanslar, koşullar, hakkında | Düğme | KHV-NFR-037 (koşullar) |
| `download_outlined`, `upload_file_outlined` | Ayarlar | Yedek al / geri yükle | Düğme | KHV-FR-SET-0xx |
| `edit_note` | Günlük | Elle kaydet | Düğme | KHV-FR-LOG-006 |
| `edit_outlined` | Demleme kaydı, ekipman profili | Düzenle | Düğme | KHV-FR-ONB-004 |
| `error_outline` | İçerik açılamadı | Hata | Gösterge | KHV-HMI-042 |
| `event` | Çekirdek düzenleme | Kavurma tarihi seç | Düğme | KHV-FR-LOG-004 |
| `exposure_zero` | Rehberli demleme | Dara (teraziyi sıfırla) | Düğme | KHV-FR-SCL-0xx |
| `feedback_outlined` | Ayarlar | Geri bildirim | Düğme | Yok |
| `filter_alt_off` | Günlük | Filtreyi temizle | Düğme | KHV-FR-LOG-00x |
| `flash_on_outlined` | Ayarlar | Görsel uyarı (flaş) kanalı | Anahtar | KHV-HMI-005 |
| `help_outline` | Ana ekran, terim çipi, ayarlar | Yardım / sözlük | Düğme | KHV-FR-HLP-001 |
| `ios_share` | Demleme kaydı, paylaşım | Paylaş | Düğme | KHV-FR-SOC-0xx |
| `lightbulb_outline` | Tarif, kayıt | Öneri | Gösterge | KHV-FR-DIA-0xx |
| `link_off` | Tarif içe aktarma | Bağlantı geçersiz | Gösterge | KHV-HMI-042 |
| `menu_book_outlined` | Günlük boş durumu, kayıt yok | Günlük | Gösterge | KHV-HMI-032 |
| `notifications_off_outlined` | Ayarlar | Sessiz saatler | Düğme | KHV-FR-ENG-008 |
| `person_outline` | Ayarlar | Profil seviyesi | Düğme | KHV-FR-SET-002 |
| `play_arrow` | Tarif, ana ekran favori, demleme | Demlemeyi başlat / devam et | Düğme | KHV-FR-BRW-001, RCP-011 |
| `quiz_outlined` | Tat ekranı | "Emin değilim" soruları | Düğme | KHV-FR-DIA-0xx |
| `radio_button_checked` | Tat alanı | Tat konumu (sürüklenebilir top) | Sürükleme | KHV-HMI-013 |
| `receipt_long_outlined` | Tarif bulunamadı | Tarif | Gösterge | KHV-HMI-042 |
| `record_voice_over_outlined`, `volume_up_outlined`, `vibration` | Ayarlar | Sesli rehber, ses, titreşim uyarı kanalları | Anahtar | KHV-HMI-005 |
| `replay` | Demleme kaydı | Aynı parametrelerle demle | Düğme | KHV-FR-LOG-003 |
| `scale` | Demleme, paylaşım kartı | Terazi değeri / kahve ağırlığı | Düğme, gösterge | KHV-FR-SCL-0xx |
| `schedule` | Rehberli demleme | Arka planda takip et (uzun demleme) | Düğme | KHV-FR-BRW-0xx |
| `search`, `search_off` | Ana ekran, yardım | Ara / sonuç yok | Alan, gösterge | KHV-FR-HLP-001 |
| `skip_next` | Rehberli demleme | Adımı atla | Düğme | KHV-HMI-009 |
| `stop` | Rehberli demleme | Bitir (basılı tut) | Basılı tutma | KHV-HMI-025 |
| `thermostat`, `timer_outlined`, `percent` | Tarif, paylaşım kartı | Sıcaklık, süre, oran | Gösterge | KHV-FR-RCP-0xx |
| `trending_up` | Ekipman | Sıradaki öneri | Gösterge | KHV-FR-EQP-004 |
| `warning_amber_rounded` | Emniyet bandı | Emniyet uyarısı | Gösterge | KHV-HMI-021 |
| `eco_outlined` | Paylaşım kartı | Çekirdek adı | Gösterge | Yok |
| `speed`, `check_circle_outline` | Espresso shot özeti | Süre aralık dışı / içinde | Gösterge | Yok |

"0xx" ile yazılan kimlikler, kodda ilgili ekranın belge yorumunda aralık olarak geçiyor ama tek bir maddeye bağlanmamış; ürün sahibi kesin kimliği belirlemeli.
