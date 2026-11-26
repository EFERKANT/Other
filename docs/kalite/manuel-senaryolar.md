# Manuel ve yarı otomatik test senaryoları

Bu dosya `python3 tool/trace.py` ile üretilir; elle düzenlemeyin.
Her senaryonun adımları ve beklenen sonuçları paylaşılan izlenebilirlik
matrisinde ("Normal durum senaryosu" ve "Sınır ve hata durumu"
sütunları). Kaliteci her sürüm adayında bu listeyi kopyalayıp sonuç
sütununu doldurur ve [yayın kontrol listesine](yayin-kontrol-listesi.md)
ekler. Otomatik kısmı olan senaryolarda ilgili test dosyası da verilir.

MVP kapsamında 61 senaryo.

Sonuç: Geçti / Kaldı (hata no) / Bloke (neden) / Uygulanamaz.

## Fiziksel cihaz

| Senaryo | Gereksinim | Yöntem | Seviye | Otomatik kısım | Sonuç |
| --- | --- | --- | --- | --- | --- |
| TC-BRW-003 | KHV-FR-BRW-003 | Test | Entegrasyon + Cihaz | - |  |
| TC-BRW-004 | KHV-FR-BRW-004 | Test | Cihaz | - |  |
| TC-BRW-005 | KHV-FR-BRW-005 | Test | Cihaz | `platform_features_test.dart`, `brew_timer_test.dart` |  |
| TC-NFR-001 | KHV-NFR-001 | Test | Cihaz (performans) | `performans_test.dart` |  |
| TC-NFR-002 | KHV-NFR-002 | Test | Cihaz | `timer_stres_test.dart` |  |
| TC-NFR-003 | KHV-NFR-003 | Test | Cihaz | `brew_flow_test.dart`, `arayuz_stres_test.dart`, `brew_timer_test.dart`, `timer_stres_test.dart` |  |
| TC-NFR-004 | KHV-NFR-004 | Test | Entegrasyon + Cihaz | - |  |
| TC-NFR-006 | KHV-NFR-006 | Test | Cihaz | - |  |
| TC-NFR-008 | KHV-NFR-008 | Test | Widget + Cihaz | - |  |
| TC-HMI-005 | KHV-HMI-005 | Test | Birim + Cihaz | `screens_test.dart` |  |
| TC-HMI-007 | KHV-HMI-007 | Test | Cihaz | `platform_features_test.dart` |  |
| TC-HMI-022 | KHV-HMI-022 | Test | Cihaz | `platform_features_test.dart`, `brew_timer_test.dart` |  |
| TC-HMI-026 | KHV-HMI-026 | Test | Golden + Cihaz | - |  |
| TC-HMI-027 | KHV-HMI-027 | Test + İnceleme | Widget + Cihaz | - |  |
| TC-HMI-029 | KHV-HMI-029 | Test | Cihaz (performans) | - |  |
| TC-HMI-030 | KHV-HMI-030 | Test | Widget + Cihaz | - |  |
| TC-HMI-031 | KHV-HMI-031 | Test | Widget + Cihaz | `accessibility_test.dart` |  |
| TC-HMI-037 | KHV-HMI-037 | Test | Entegrasyon + Cihaz | `platform_features_test.dart` |  |
| TC-HMI-040 | KHV-HMI-040 | Test | Entegrasyon + Cihaz | - |  |
| TC-NFR-023 | KHV-NFR-023 | Test | Cihaz (performans) | `performans_test.dart`, `arayuz_stres_test.dart`, `veri_stres_test.dart` |  |
| TC-SOC-002 | KHV-FR-SOC-002 | Test | Cihaz | `platform_features_test.dart` |  |
| TC-SOC-003 | KHV-FR-SOC-003 | Test | Cihaz + Entegrasyon | `platform_features_test.dart`, `misc_test.dart` |  |
| TC-ARC-003 | KHV-ARC-003 | Test | Cihaz | `platform_features_test.dart` |  |
| TC-BRW-009 | KHV-FR-BRW-009 | Test | Entegrasyon + Cihaz | `platform_features_test.dart`, `brew_timer_test.dart`, `timer_stres_test.dart` |  |
| TC-BRW-011 | KHV-FR-BRW-011 | Test | Birim + Cihaz | `database_test.dart`, `brew_timer_test.dart`, `timer_stres_test.dart` |  |
| TC-BRW-012 | KHV-FR-BRW-012 | Test | Cihaz | - |  |
| TC-BRW-013 | KHV-FR-BRW-013 | Test | Cihaz | `platform_features_test.dart` |  |
| TC-NFR-026 | KHV-NFR-026 | Test | Entegrasyon + Cihaz | `misc_test.dart` |  |
| TC-NFR-030 | KHV-NFR-030 | Test | Cihaz | `database_test.dart`, `platform_features_test.dart`, `veri_stres_test.dart` |  |
| TC-SCL-002 | KHV-FR-SCL-002 | Test | Birim + Cihaz | `scale_test.dart`, `ble_scale_test.dart`, `scale_test.dart` |  |
| TC-SCL-003 | KHV-FR-SCL-003 | Test | Birim + Cihaz | `scale_test.dart`, `ble_scale_test.dart`, `scale_test.dart` |  |
| TC-SCL-004 | KHV-FR-SCL-004 | Test | Entegrasyon + Cihaz | `scale_test.dart`, `ble_scale_test.dart`, `scale_test.dart` |  |
| TC-SCL-005 | KHV-FR-SCL-005 | Test | Birim + Cihaz | `scale_test.dart`, `ble_scale_test.dart`, `scale_test.dart` |  |
| TC-SCL-007 | KHV-FR-SCL-007 | Test + İnceleme | Cihaz + Manifest incelemesi | `scale_test.dart` |  |
| TC-SCL-008 | KHV-FR-SCL-008 | Test | Cihaz | - |  |
| TC-SCL-010 | KHV-FR-SCL-010 | Test + İnceleme | Birim + Kod incelemesi + Cihaz | `scale_test.dart`, `ble_scale_test.dart`, `scale_test.dart` |  |

## Kullanılabilirlik oturumu

| Senaryo | Gereksinim | Yöntem | Seviye | Otomatik kısım | Sonuç |
| --- | --- | --- | --- | --- | --- |
| TC-NFR-007 | KHV-NFR-007 | Test + İnceleme | Widget + Kullanılabilirlik | - |  |
| TC-HMI-002 | KHV-HMI-002 | Gösterim | Kullanılabilirlik | - |  |
| TC-HMI-041 | KHV-HMI-041 | Gösterim + Analiz | Kullanılabilirlik | - |  |

## Yarı otomatik (otomatik kısım + elle onay)

| Senaryo | Gereksinim | Yöntem | Seviye | Otomatik kısım | Sonuç |
| --- | --- | --- | --- | --- | --- |
| TC-EQP-006 | KHV-FR-EQP-006 | İnceleme + Test | İnceleme + Otomatik metin taraması | `screens_test.dart` |  |
| TC-CNT-004 | KHV-CNT-004 | İnceleme + Test | CMS testi | - |  |
| TC-NFR-015 | KHV-NFR-015 | Test | Sunucu + Güvenlik | - |  |
| TC-HMI-035 | KHV-HMI-035 | İnceleme + Test | Golden + İnceleme | `accessibility_test.dart` |  |
| TC-HMI-039 | KHV-HMI-039 | Test + İnceleme | Widget + İnceleme | - |  |

## İnceleme ve sürüm geçidi

| Senaryo | Gereksinim | Yöntem | Seviye | Otomatik kısım | Sonuç |
| --- | --- | --- | --- | --- | --- |
| TC-CNT-001 | KHV-CNT-001 | İnceleme + Gösterim | İçerik incelemesi + Demleme denemesi | `misc_test.dart` |  |
| TC-CNT-003 | KHV-CNT-003 | İnceleme | İçerik incelemesi | `misc_test.dart` |  |
| TC-CNT-005 | KHV-CNT-005 | İnceleme | İçerik incelemesi | - |  |
| TC-NFR-018 | KHV-NFR-018 | İnceleme | Kod incelemesi | - |  |
| TC-NFR-022 | KHV-NFR-022 | İnceleme | Kod incelemesi | - |  |
| TC-HMI-014 | KHV-HMI-014 | İnceleme | İçerik incelemesi | - |  |
| TC-NFR-024 | KHV-NFR-024 | İnceleme | Test planı incelemesi | `performans_test.dart` |  |
| TC-NFR-025 | KHV-NFR-025 | İnceleme | Sürüm geçidi | - |  |
| TC-ARC-002 | KHV-ARC-002 | Analiz + Test | Tasarım incelemesi + Birim | - |  |
| TC-CNT-007 | KHV-CNT-007 | İnceleme + Gösterim | İçerik incelemesi | - |  |
| TC-CNT-008 | KHV-CNT-008 | İnceleme | İçerik incelemesi | - |  |
| TC-CNT-009 | KHV-CNT-009 | İnceleme + Gösterim | İçerik incelemesi | - |  |
| TC-NFR-034 | KHV-NFR-034 | İnceleme + Test | Hukuki inceleme + Entegrasyon | - |  |
| TC-NFR-035 | KHV-NFR-035 | İnceleme | Sürüm geçidi | - |  |
| TC-NFR-037 | KHV-NFR-037 | Test + İnceleme | Widget + Hukuki inceleme | - |  |
| TC-NFR-043 | KHV-NFR-043 | İnceleme | Sürüm geçidi | - |  |
| TC-SCL-001 | KHV-FR-SCL-001 | İnceleme | Lisans ve kaynak incelemesi | `scale_test.dart` |  |
