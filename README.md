# Ev Kahvesi

Evde kahve hazırlayan kullanıcıya elindeki ekipmana göre adım adım rehberlik eden, demleme sonrasında tada göre bir sonraki deneme için **tek ve somut** düzeltme öneren Flutter uygulaması.

Bu depo, *Ev Kahvesi Uygulaması Gereksinim Dokümanı Rev1*'deki MVP çekirdek döngüsünü (tarif → rehberli demleme → tat geri bildirimi → düzeltme) gerçekler.

## Yapı

| Dizin | İçerik |
| --- | --- |
| `packages/kahve_core` | Flutter'dan bağımsız saf Dart iş kuralları (KHV-NFR-040): hesaplayıcı, ölçekleme, dial-in motoru, zamanlayıcı, stok/tazelik, profil atama, paylaşım doğrulama, Türkçe arama ve sayı biçimi |
| `app` | Flutter uygulaması (Riverpod, go_router, Drift) |
| `app/assets/content/bundle.json` | Gömülü içerik: 9 yöntem, başlangıç tarifleri, düzeltme kuralları, sözlük, ekipman rehberi ve katalog (KHV-NFR-026, KHV-CNT-002) |
| `tool/build_content.py` | İçerik paketini üreten betik. İçerik değişince sürüm numarasını artırın |

## Çalıştırma

Gereken Flutter sürümü 3.50.1 (Dart 3.14).

```bash
cd app
flutter pub get
dart run build_runner build
flutter run
```

Testler:

```bash
cd packages/kahve_core && dart test
cd app && flutter test
```

Golden görüntüleri güncellemek için `flutter test --update-goldens` kullanın.

## Kodlama standardı

Effective Dart (Bölüm 8.1). CI şunları zorunlu tutar: `dart format`, statik analiz (`flutter_lints`, çekirdekte ek olarak `public_member_api_docs`), tüm testler ve çekirdek katmanda en az %90 satır kapsamı (`.github/workflows/ci.yml`).

## Gereksinim kapsamı

| Modül | Durum | Not |
| --- | --- | --- |
| ONB Kurulum ve ekipman profili | Uygulandı | ONB-001..005; öğütücü, terazi ve kettle ilk kullanımda sorulur (HMI-016) |
| RCP Tarif ve hesaplayıcı | Uygulandı | RCP-001..008, 010..014. RCP-009 (°F) S2 |
| BRW Rehber mod ve zamanlayıcı | Kısmen | BRW-001..004, 006..011 uygulandı. BRW-005 (arka planda bildirim), BRW-012'nin sessiz mod algılaması ve BRW-013 (TTS) yerel eklenti gerektirir, sonraki adım |
| DIA Tat teşhisi ve dial-in | Uygulandı | DIA-001..006, Bölüm 6 kural 1-5. DIA-007 S2 |
| EQP Ekipman rehberi | Uygulandı | EQP-001..006 |
| LOG Günlük ve çekirdek | Uygulandı | LOG-001..004, 006..009. LOG-005 (CSV) S2 |
| SET Ayarlar | Uygulandı | SET-001..003. Yedekleme/dışa aktarma (NFR-030) sonraki adım |
| HLP Yardım | Kısmen | HLP-001, HLP-002. HLP-003 (hata bildirimi) sunucu kararı bekliyor |
| HMI | Büyük ölçüde | HMI-001..006, 009..021, 023..028, 030..036, 038..040. HMI-007 (TTS), HMI-022 (Live Activity / kalıcı bildirim), HMI-037 (bildirim izni) yerel eklenti gerektirir |
| ENG, SOC, ARC | Kısmen | Stok düşümü ve tazelik/stok göstergeleri (ENG-003..005, uygulama içi), paylaşım kodlama/doğrulama çekirdekte hazır (SOC-003/004/009/010). Bildirimler, paylaşım kartı ve deep link sonraki adım |

### Dokümandaki çelişkiler için verilen kararlar

1. **Tat girişi (DIA-001 / HMI-013):** İki boyutlu alan kullanılır. Alanda gösterilemeyen "hem ekşi hem acı" ve "düz/aromasız" ayrı onay kutularıyla alınır. Ekran okuyucu için alanın yanında seçim düğmeleri vardır.
2. **Uyarı kanalları (BRW-003 / HMI-005):** Kanallar ayrı ayrı kapatılabilir, ancak açık kanal sayısı ikinin altına inemez.
3. **Token (NFR-015):** MVP'de hesap olmadığından kimlik doğrulama S2'ye bırakıldı.
4. **Bölüm 6, kural 4:** Aynı yönde iki ardışık düzeltmeden sonra tat ters yöne dönerse uygulama bir önceki ayara dönmeyi önerir.
