# Gereksinim-test izlenebilirliği

Bu dosya `python3 tool/trace.py` ile üretilir; elle düzenlemeyin.
Kaynak: `docs/kalite/matris.csv` (paylaşılan izlenebilirlik matrisinin
anlık görüntüsü) ve test dosyalarındaki gereksinim kimlikleri.

| Modül | Gereksinim | MVP | Otomatik testte | Manuel/yarı otomatik | İstisna |
| --- | ---: | ---: | ---: | ---: | ---: |
| Kurulum | 5 | 5 | 5 | 0 | 0 |
| Tarif ve hesaplayıcı | 14 | 13 | 13 | 0 | 0 |
| Rehber mod | 13 | 13 | 10 | 7 | 0 |
| Tat teşhisi | 7 | 6 | 6 | 0 | 0 |
| Ekipman rehberi | 6 | 6 | 6 | 1 | 0 |
| Günlük ve çekirdek | 9 | 8 | 8 | 0 | 0 |
| Deneyim formu | 17 | 0 | 1 | 0 | 0 |
| İçerik | 9 | 9 | 5 | 7 | 0 |
| Fonksiyonel olmayan | 46 | 38 | 22 | 23 | 5 |
| HMI | 42 | 41 | 32 | 16 | 0 |
| Günlük kullanım | 9 | 7 | 7 | 1 | 0 |
| Sosyal | 14 | 6 | 10 | 4 | 0 |
| Altyapı | 7 | 7 | 6 | 2 | 0 |
| Ayarlar | 3 | 3 | 3 | 0 | 0 |
| Yardım | 3 | 3 | 3 | 0 | 0 |
| Yönetim paneli | 6 | 1 | 1 | 0 | 1 |
| Terazi | 10 | 0 | 7 | 8 | 0 |
| Profil | 5 | 0 | 4 | 0 | 0 |
| Etkinlik | 13 | 0 | 13 | 1 | 0 |

## Ayrıntı

| Gereksinim | Öncelik | Otomasyon | Durum | Test dosyaları / gerekçe |
| --- | --- | --- | --- | --- |
| KHV-FR-ONB-001 | MVP | Otomatik | Testte | `app/test/ui/onboarding_test.dart` |
| KHV-FR-ONB-002 | MVP | Otomatik | Testte | `packages/kahve_core/test/misc_test.dart` |
| KHV-FR-ONB-003 | MVP | Otomatik | Testte | `app/test/ui/crud_test.dart` |
| KHV-FR-ONB-004 | MVP | Otomatik | Testte | `app/test/ui/crud_test.dart` |
| KHV-FR-ONB-005 | MVP | Otomatik | Testte | `app/test/ui/onboarding_test.dart`, `packages/kahve_core/test/misc_test.dart` |
| KHV-FR-RCP-001 | MVP | Otomatik | Testte | `packages/kahve_core/test/misc_test.dart` |
| KHV-FR-RCP-002 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart`, `packages/kahve_core/test/calculator_test.dart`, `packages/kahve_core/test_stres/kural_stres_test.dart` |
| KHV-FR-RCP-003 | MVP | Otomatik | Testte | `packages/kahve_core/test/calculator_test.dart` |
| KHV-FR-RCP-004 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart`, `packages/kahve_core/test/calculator_test.dart` |
| KHV-FR-RCP-005 | MVP | Otomatik | Testte | `packages/kahve_core/test/calculator_test.dart` |
| KHV-FR-RCP-006 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart` |
| KHV-FR-RCP-007 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart`, `packages/kahve_core/test/misc_test.dart` |
| KHV-FR-RCP-008 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart`, `packages/kahve_core/test/calculator_test.dart` |
| KHV-FR-RCP-009 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-BRW-001 | MVP | Otomatik | Testte | `app/test/ui/brew_flow_test.dart` |
| KHV-FR-BRW-002 | MVP | Otomatik | Testte | `app/test/ui/brew_flow_test.dart` |
| KHV-FR-BRW-003 | MVP | Yarı otomatik | Manuel kontrol | Entegrasyon + Cihaz (test planı) |
| KHV-FR-BRW-004 | MVP | Manuel | Manuel kontrol | Cihaz (test planı) |
| KHV-FR-BRW-005 | MVP | Manuel | Testte | `app/test/ui/platform_features_test.dart`, `packages/kahve_core/test/brew_timer_test.dart` |
| KHV-FR-BRW-006 | MVP | Otomatik | Testte | `packages/kahve_core/test/brew_timer_test.dart` |
| KHV-FR-BRW-007 | MVP | Otomatik | Testte | `app/test/ui/brew_flow_test.dart` |
| KHV-FR-BRW-008 | MVP | Otomatik | Testte | `app/test/ui/brew_flow_test.dart`, `app/test/ui/scale_test.dart`, `packages/kahve_core/test/calculator_test.dart` |
| KHV-FR-DIA-001 | MVP | Otomatik | Testte | `app/test/ui/brew_flow_test.dart` |
| KHV-FR-DIA-002 | MVP | Otomatik | Testte | `packages/kahve_core/test/dial_in_test.dart`, `packages/kahve_core/test_stres/kural_stres_test.dart` |
| KHV-FR-DIA-003 | MVP | Otomatik | Testte | `packages/kahve_core/test/dial_in_test.dart` |
| KHV-FR-DIA-004 | MVP | Otomatik | Testte | `packages/kahve_core/test/dial_in_test.dart` |
| KHV-FR-DIA-005 | MVP | Otomatik | Testte | `app/test/ui/brew_flow_test.dart`, `packages/kahve_core/test/dial_in_test.dart`, `packages/kahve_core/test_stres/kural_stres_test.dart` |
| KHV-FR-DIA-006 | MVP | Otomatik | Testte | `app/test_stres/veri_stres_test.dart`, `packages/kahve_core/test/dial_in_test.dart`, `packages/kahve_core/test_stres/kural_stres_test.dart` |
| KHV-FR-DIA-007 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-EQP-001 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart` |
| KHV-FR-EQP-002 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart` |
| KHV-FR-EQP-003 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart` |
| KHV-FR-EQP-004 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart`, `packages/kahve_core/test/misc_test.dart` |
| KHV-FR-EQP-005 | MVP | Otomatik | Testte | `app/test/ui/crud_test.dart` |
| KHV-FR-EQP-006 | MVP | Yarı otomatik | Testte | `app/test/ui/screens_test.dart` |
| KHV-FR-LOG-001 | MVP | Otomatik | Testte | `app/test/ui/brew_flow_test.dart` |
| KHV-FR-LOG-002 | MVP | Otomatik | Testte | `app/test/ui/crud_test.dart`, `app/test_stres/arayuz_stres_test.dart` |
| KHV-FR-LOG-003 | MVP | Otomatik | Testte | `app/test/ui/crud_test.dart` |
| KHV-FR-LOG-004 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart`, `packages/kahve_core/test/misc_test.dart` |
| KHV-FR-LOG-005 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-COM-001 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-COM-002 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-COM-003 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-COM-004 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-COM-005 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-COM-006 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-COM-007 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-COM-008 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-COM-009 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-COM-010 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-COM-011 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-COM-012 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-COM-013 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-COM-014 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-COM-015 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-COM-016 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-COM-017 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-CNT-001 | MVP | Manuel | Testte | `packages/kahve_core/test/misc_test.dart` |
| KHV-CNT-002 | MVP | Otomatik | Testte | `packages/kahve_core/test/misc_test.dart` |
| KHV-CNT-003 | MVP | Manuel | Testte | `packages/kahve_core/test/misc_test.dart` |
| KHV-CNT-004 | MVP | Yarı otomatik | Testte | `packages/kahve_core/test/misc_test.dart` |
| KHV-CNT-005 | MVP | Manuel | Manuel kontrol | İçerik incelemesi (test planı) |
| KHV-CNT-006 | MVP | Otomatik | Testte | `packages/kahve_core/test/misc_test.dart` |
| KHV-NFR-001 | MVP | Yarı otomatik | Testte | `app/integration_test/performans_test.dart` |
| KHV-NFR-002 | MVP | Yarı otomatik | Testte | `packages/kahve_core/test_stres/timer_stres_test.dart` |
| KHV-NFR-003 | MVP | Manuel | Testte | `app/test/ui/brew_flow_test.dart`, `app/test_stres/arayuz_stres_test.dart`, `packages/kahve_core/test/brew_timer_test.dart`, `packages/kahve_core/test_stres/timer_stres_test.dart` |
| KHV-NFR-004 | MVP | Yarı otomatik | Manuel kontrol | Entegrasyon + Cihaz (test planı) |
| KHV-NFR-005 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-NFR-006 | MVP | Yarı otomatik | Manuel kontrol | Cihaz (test planı) |
| KHV-NFR-007 | MVP | Yarı otomatik | Manuel kontrol | Widget + Kullanılabilirlik (test planı) |
| KHV-NFR-008 | MVP | Yarı otomatik | Manuel kontrol | Widget + Cihaz (test planı) |
| KHV-NFR-009 | MVP | Otomatik | Testte | `app/test/ui/accessibility_test.dart` |
| KHV-NFR-010 | MVP / S2 | Otomatik | Testte | `app/test/ui/screens_test.dart` |
| KHV-NFR-011 | MVP | Otomatik | İstisna | Uygulama sürümü olmadan içerik güncellemesi sunucu/CMS gerektirir; ContentBundle sürümlü ve doğrulamalı olduğu için istemci tarafı hazır. |
| KHV-NFR-012 | MVP | Otomatik | Testte | `app/test/ui/onboarding_test.dart` |
| KHV-NFR-013 | S2 | Manuel | Manuel kontrol | Hukuki inceleme + Entegrasyon (test planı) |
| KHV-NFR-014 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-NFR-015 | MVP | Yarı otomatik | Manuel kontrol | Sunucu + Güvenlik (test planı) |
| KHV-NFR-016 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-NFR-017 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart` |
| KHV-NFR-018 | MVP | Manuel | Manuel kontrol | Kod incelemesi (test planı) |
| KHV-NFR-019 | MVP | Otomatik | Testte | `.github/workflows/ci.yml` |
| KHV-NFR-020 | MVP | Otomatik | Testte | `.github/workflows/ci.yml` |
| KHV-NFR-021 | MVP | Otomatik | Testte | `.github/workflows/ci.yml` |
| KHV-NFR-022 | MVP | Manuel | Manuel kontrol | Kod incelemesi (test planı) |
| KHV-HMI-001 | MVP | Otomatik | Testte | `app/test/ui/brew_flow_test.dart` |
| KHV-HMI-002 | MVP | Manuel | Manuel kontrol | Kullanılabilirlik (test planı) |
| KHV-HMI-003 | MVP | Otomatik | Testte | `app/test/ui/brew_flow_test.dart`, `packages/kahve_core/test/brew_timer_test.dart` |
| KHV-HMI-004 | MVP | Otomatik | Testte | `packages/kahve_core/test/brew_timer_test.dart` |
| KHV-HMI-005 | MVP | Yarı otomatik | Testte | `app/test/ui/screens_test.dart` |
| KHV-HMI-006 | MVP | Otomatik | Testte | `app/test/ui/brew_flow_test.dart`, `app/test_stres/arayuz_stres_test.dart` |
| KHV-HMI-007 | MVP | Manuel | Testte | `app/test/ui/platform_features_test.dart` |
| KHV-HMI-008 | S2 | Manuel | Manuel kontrol | Cihaz (test planı) |
| KHV-HMI-009 | MVP | Otomatik | Testte | `app/integration_test/performans_test.dart`, `app/test/ui/accessibility_test.dart`, `app/test/ui/brew_flow_test.dart`, `app/test_stres/arayuz_stres_test.dart`, `packages/kahve_core/test/brew_timer_test.dart` |
| KHV-HMI-010 | MVP | Otomatik | Testte | `app/test/ui/brew_flow_test.dart`, `packages/kahve_core/test/brew_timer_test.dart` |
| KHV-HMI-011 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart` |
| KHV-HMI-012 | MVP | Otomatik | Testte | `packages/kahve_core/test/calculator_test.dart` |
| KHV-HMI-013 | MVP | Otomatik | Testte | `app/test/ui/accessibility_test.dart` |
| KHV-HMI-014 | MVP | Manuel | Manuel kontrol | İçerik incelemesi (test planı) |
| KHV-HMI-015 | MVP | Otomatik | Testte | `packages/kahve_core/test/misc_test.dart` |
| KHV-HMI-016 | MVP | Otomatik | Testte | `app/test/ui/onboarding_test.dart` |
| KHV-HMI-017 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart`, `packages/kahve_core/test/misc_test.dart` |
| KHV-HMI-018 | MVP | Otomatik | Testte | `app/test/ui/crud_test.dart` |
| KHV-HMI-019 | MVP | Otomatik | Testte | `app/test/ui/accessibility_test.dart` |
| KHV-HMI-020 | MVP | Otomatik | Testte | `app/test/ui/accessibility_test.dart` |
| KHV-HMI-021 | MVP | Otomatik | Testte | `app/test/ui/brew_flow_test.dart` |
| KHV-HMI-022 | MVP | Manuel | Testte | `app/test/ui/platform_features_test.dart`, `packages/kahve_core/test/brew_timer_test.dart` |
| KHV-HMI-023 | MVP | Otomatik | Testte | `app/test/ui/brew_flow_test.dart` |
| KHV-HMI-024 | MVP | Otomatik | Testte | `app/test/ui/accessibility_test.dart` |
| KHV-HMI-025 | MVP | Otomatik | Testte | `app/test/ui/accessibility_test.dart` |
| KHV-HMI-026 | MVP | Yarı otomatik | Manuel kontrol | Golden + Cihaz (test planı) |
| KHV-HMI-027 | MVP | Yarı otomatik | Manuel kontrol | Widget + Cihaz (test planı) |
| KHV-HMI-028 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart` |
| KHV-HMI-029 | MVP | Yarı otomatik | Manuel kontrol | Cihaz (performans) (test planı) |
| KHV-HMI-030 | MVP | Yarı otomatik | Manuel kontrol | Widget + Cihaz (test planı) |
| KHV-HMI-031 | MVP | Yarı otomatik | Testte | `app/test/ui/accessibility_test.dart` |
| KHV-HMI-032 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart` |
| KHV-HMI-033 | MVP | Otomatik | Testte | `app/test/ui/accessibility_test.dart` |
| KHV-HMI-034 | MVP | Otomatik | Testte | `app/test/ui/accessibility_test.dart` |
| KHV-HMI-035 | MVP | Yarı otomatik | Testte | `app/test/ui/accessibility_test.dart` |
| KHV-HMI-036 | MVP | Otomatik | Testte | `app/test/ui/accessibility_test.dart` |
| KHV-HMI-037 | MVP | Yarı otomatik | Testte | `app/test/ui/platform_features_test.dart` |
| KHV-HMI-038 | MVP | Otomatik | Testte | `app/test/ui/onboarding_test.dart` |
| KHV-HMI-039 | MVP | Yarı otomatik | Manuel kontrol | Widget + İnceleme (test planı) |
| KHV-HMI-040 | MVP | Yarı otomatik | Manuel kontrol | Entegrasyon + Cihaz (test planı) |
| KHV-HMI-041 | MVP | Manuel | Manuel kontrol | Kullanılabilirlik (test planı) |
| KHV-NFR-023 | MVP | Yarı otomatik | Testte | `app/integration_test/performans_test.dart`, `app/test_stres/arayuz_stres_test.dart`, `app/test_stres/veri_stres_test.dart` |
| KHV-NFR-024 | MVP | Manuel | Testte | `app/integration_test/performans_test.dart` |
| KHV-NFR-025 | MVP | Manuel | Manuel kontrol | Sürüm geçidi (test planı) |
| KHV-FR-ENG-001 | MVP | Otomatik | Testte | `app/test/state/engagement_test.dart`, `app/test/ui/platform_features_test.dart`, `packages/kahve_core/test/notifications_test.dart` |
| KHV-FR-ENG-002 | MVP | Otomatik | Testte | `app/test/ui/platform_features_test.dart`, `packages/kahve_core/test/notifications_test.dart` |
| KHV-FR-ENG-003 | MVP | Otomatik | Testte | `app/test/data/database_test.dart`, `app/test_stres/veri_stres_test.dart`, `packages/kahve_core/test/misc_test.dart` |
| KHV-FR-ENG-004 | MVP | Otomatik | Testte | `app/test/state/engagement_test.dart`, `app/test_stres/veri_stres_test.dart`, `packages/kahve_core/test/misc_test.dart` |
| KHV-FR-ENG-005 | MVP | Otomatik | Testte | `app/test/state/engagement_test.dart`, `packages/kahve_core/test/misc_test.dart` |
| KHV-FR-ENG-006 | S2 | Manuel | Manuel kontrol | Cihaz (test planı) |
| KHV-FR-ENG-007 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-ENG-008 | MVP | Otomatik | Testte | `app/test/state/engagement_test.dart`, `app/test_stres/veri_stres_test.dart`, `packages/kahve_core/test/notifications_test.dart` |
| KHV-FR-SOC-001 | MVP | Otomatik | Testte | `app/test/ui/platform_features_test.dart` |
| KHV-FR-SOC-002 | MVP | Manuel | Testte | `app/test/ui/platform_features_test.dart` |
| KHV-FR-SOC-003 | MVP | Yarı otomatik | Testte | `app/test/ui/platform_features_test.dart`, `packages/kahve_core/test/misc_test.dart` |
| KHV-FR-SOC-004 | MVP | Otomatik | Testte | `app/test/ui/platform_features_test.dart`, `packages/kahve_core/test/misc_test.dart` |
| KHV-FR-SOC-005 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-SOC-006 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-SOC-007 | S3 adayı | Yarı otomatik | Manuel kontrol | Entegrasyon (test planı) |
| KHV-FR-SOC-008 | S3 adayı | Manuel | Manuel kontrol | Sistem testi (test planı) |
| KHV-ARC-001 | MVP | Otomatik | Testte | `packages/kahve_core/test/misc_test.dart` |
| KHV-ARC-002 | MVP | Yarı otomatik | Manuel kontrol | Tasarım incelemesi + Birim (test planı) |
| KHV-ARC-003 | MVP | Yarı otomatik | Testte | `app/test/ui/platform_features_test.dart` |
| KHV-ARC-004 | MVP | Otomatik | Testte | `app/test/data/database_test.dart` |
| KHV-ARC-005 | MVP | Otomatik | Testte | `packages/kahve_core/test/notifications_test.dart` |
| KHV-ARC-006 | MVP | Otomatik | Testte | `packages/kahve_core/test/notifications_test.dart` |
| KHV-FR-RCP-010 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart`, `packages/kahve_core/test/calculator_test.dart` |
| KHV-FR-RCP-011 | MVP | Otomatik | Testte | `app/test/ui/crud_test.dart` |
| KHV-FR-RCP-012 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart`, `packages/kahve_core/test/misc_test.dart` |
| KHV-FR-RCP-013 | MVP | Otomatik | Testte | `app/test/ui/crud_test.dart` |
| KHV-FR-RCP-014 | MVP | Otomatik | Testte | `app/test/data/database_test.dart` |
| KHV-FR-BRW-009 | MVP | Yarı otomatik | Testte | `app/test/ui/platform_features_test.dart`, `packages/kahve_core/test/brew_timer_test.dart`, `packages/kahve_core/test_stres/timer_stres_test.dart` |
| KHV-FR-BRW-010 | MVP | Otomatik | Testte | `app/test/ui/platform_features_test.dart` |
| KHV-FR-BRW-011 | MVP | Yarı otomatik | Testte | `packages/kahve_core/test/brew_timer_test.dart`, `packages/kahve_core/test_stres/timer_stres_test.dart` |
| KHV-FR-BRW-012 | MVP | Manuel | Manuel kontrol | Cihaz (test planı) |
| KHV-FR-BRW-013 | MVP | Manuel | Testte | `app/test/ui/platform_features_test.dart` |
| KHV-FR-LOG-006 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart` |
| KHV-FR-LOG-007 | MVP | Otomatik | Testte | `app/test/ui/crud_test.dart` |
| KHV-FR-LOG-008 | MVP | Otomatik | Testte | `app/test/ui/crud_test.dart` |
| KHV-FR-LOG-009 | MVP | Otomatik | Testte | `app/test/data/database_test.dart` |
| KHV-FR-SET-001 | MVP | Otomatik | Testte | `app/test/ui/crud_test.dart` |
| KHV-FR-SET-002 | MVP | Otomatik | Testte | `app/test/ui/crud_test.dart` |
| KHV-FR-SET-003 | MVP | Otomatik | Testte | `app/test/data/database_test.dart` |
| KHV-FR-HLP-001 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart` |
| KHV-FR-HLP-002 | MVP | Otomatik | Testte | `app/test/ui/crud_test.dart` |
| KHV-FR-HLP-003 | MVP | Otomatik | Testte | `app/test/ui/platform_features_test.dart` |
| KHV-FR-ENG-009 | MVP | Otomatik | Testte | `packages/kahve_core/test/notifications_test.dart` |
| KHV-FR-SOC-009 | MVP | Otomatik | Testte | `app/test/ui/platform_features_test.dart`, `packages/kahve_core/test/misc_test.dart`, `packages/kahve_core/test_stres/kural_stres_test.dart` |
| KHV-FR-SOC-010 | MVP | Otomatik | Testte | `app/test/ui/platform_features_test.dart`, `packages/kahve_core/test/misc_test.dart` |
| KHV-CNT-007 | MVP | Manuel | Manuel kontrol | İçerik incelemesi (test planı) |
| KHV-CNT-008 | MVP | Manuel | Manuel kontrol | İçerik incelemesi (test planı) |
| KHV-CNT-009 | MVP | Manuel | Manuel kontrol | İçerik incelemesi (test planı) |
| KHV-FR-ADM-001 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-ADM-002 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-ADM-003 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-ADM-004 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-ADM-005 | MVP | Otomatik | İstisna | İçerik yönetim arayüzü sunucu altyapısı kararına bağlı (Bölüm 10 açık konu: Firebase/Supabase/özel API). İçerik şimdilik tool/build_content.py ile sürümlenip uygulamaya gömülüyor. |
| KHV-NFR-026 | MVP | Yarı otomatik | Testte | `packages/kahve_core/test/misc_test.dart` |
| KHV-NFR-027 | MVP | Otomatik | İstisna | Değişen içerik kayıtlarının indirilmesi sunucu/CMS gerektirir (KHV-NFR-011 ile aynı karar). |
| KHV-NFR-028 | MVP | Otomatik | Testte | `app/test/data/database_test.dart`, `app/test/data/migration_test.dart` |
| KHV-NFR-029 | MVP | Otomatik | İstisna | Desteklenen minimum sürüm bilgisi sunucudan okunur; sunucu altyapısı seçilmedi. |
| KHV-NFR-030 | MVP | Manuel | Testte | `app/test/data/database_test.dart`, `app/test/ui/platform_features_test.dart`, `app/test_stres/veri_stres_test.dart` |
| KHV-NFR-031 | MVP | Otomatik | Testte | `app/test/ui/screens_test.dart`, `packages/kahve_core/test/misc_test.dart`, `packages/kahve_core/test_stres/kural_stres_test.dart` |
| KHV-NFR-032 | MVP | Otomatik | Testte | `.github/workflows/ci.yml` |
| KHV-NFR-033 | MVP | Otomatik | İstisna | Çökme raporlama servisi seçilmedi (ör. Sentry/Crashlytics). Rıza ayarı ve varsayılan kapalı durumu hazır ve testli. |
| KHV-NFR-038 | S2 | Yarı otomatik | Manuel kontrol | Cihaz + Güvenlik (test planı) |
| KHV-NFR-039 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-NFR-034 | MVP | Yarı otomatik | Manuel kontrol | Hukuki inceleme + Entegrasyon (test planı) |
| KHV-NFR-035 | MVP | Manuel | Manuel kontrol | Sürüm geçidi (test planı) |
| KHV-NFR-036 | MVP | Otomatik | Testte | `app/test/ui/crud_test.dart` |
| KHV-NFR-037 | MVP | Yarı otomatik | Manuel kontrol | Widget + Hukuki inceleme (test planı) |
| KHV-NFR-040 | MVP | Otomatik | Testte | `.github/workflows/ci.yml` |
| KHV-NFR-041 | MVP | Otomatik | Testte | `.github/workflows/ci.yml`, `app/test/ui/golden_test.dart` |
| KHV-NFR-042 | MVP | Otomatik | Testte | `.github/workflows/ci.yml` |
| KHV-NFR-043 | MVP | Manuel | Manuel kontrol | Sürüm geçidi (test planı) |
| KHV-NFR-044 | MVP | Otomatik | İstisna | Analitik servisi seçilmedi. Olay kaydı (KHV-ARC-004) ve rıza ayarı hazır; ölçütler servis seçilince bağlanır. |
| KHV-HMI-042 | MVP | Otomatik | Testte | `app/test/helpers.dart`, `app/test/ui/crud_test.dart` |
| KHV-ARC-007 | MVP | Otomatik | Testte | `app/test/helpers.dart`, `app/test/ui/scale_test.dart`, `packages/kahve_core/test/scale_test.dart` |
| KHV-FR-SCL-001 | S2 | Manuel | Testte | `packages/kahve_core/test/scale_test.dart` |
| KHV-FR-SCL-002 | S2 | Yarı otomatik | Testte | `packages/kahve_core/test/scale_test.dart` |
| KHV-FR-SCL-003 | S2 | Yarı otomatik | Testte | `packages/kahve_core/test/scale_test.dart` |
| KHV-FR-SCL-004 | S2 | Yarı otomatik | Testte | `app/test/ui/scale_test.dart`, `packages/kahve_core/test/scale_test.dart` |
| KHV-FR-SCL-005 | S2 | Yarı otomatik | Testte | `app/test/ui/scale_test.dart`, `packages/kahve_core/test/scale_test.dart` |
| KHV-FR-SCL-006 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-SCL-007 | S2 | Yarı otomatik | Manuel kontrol | Cihaz + Manifest incelemesi (test planı) |
| KHV-FR-SCL-008 | S2 | Manuel | Manuel kontrol | Cihaz (test planı) |
| KHV-FR-SCL-009 | S2 | Otomatik | Testte | `app/test/ui/scale_test.dart` |
| KHV-FR-SCL-010 | S2 | Yarı otomatik | Testte | `packages/kahve_core/test/scale_test.dart` |
| KHV-NFR-045 | S2 | Manuel | Manuel kontrol | Hukuki inceleme + Sürüm geçidi (test planı) |
| KHV-FR-PRO-001 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-PRO-002 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-PRO-003 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-PRO-004 | S2 | Otomatik | Sonraki sürüm |  |
| KHV-FR-PRO-005 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-SOC-011 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-SOC-012 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-SOC-013 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-SOC-014 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-EVT-001 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-EVT-002 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-EVT-003 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-EVT-004 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-EVT-005 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-EVT-006 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-EVT-007 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-EVT-008 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-EVT-009 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-EVT-010 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-EVT-011 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-EVT-012 | S2 | Yarı otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-EVT-013 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-FR-ADM-006 | S2 | Otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
| KHV-NFR-046 | S2 | Yarı otomatik | Testte | `packages/kahve_core/test/community_test.dart` |
