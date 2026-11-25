#!/usr/bin/env python3
"""Gömülü içerik paketini üretir (KHV-NFR-026).

Çalıştırma: python3 tool/build_content.py
Çıktı: app/assets/content/bundle.json
İçerik değişikliklerinde sürüm numarasını artırın (KHV-FR-ADM-005).
"""
import json, os

VERSION = 2
VERIFIED = "2026-11-24"
SCA = "SCA Protocols & Best Practices; genel uygulama"
GEN = "Genel uygulama"

def step(title, trigger, desc="", water=None, dur=None, obs=None, safety=None):
    s = {"title": title, "trigger": trigger}
    if desc: s["description"] = desc
    if water is not None: s["targetWaterG"] = water
    if dur is not None: s["durationS"] = dur
    if obs: s["observation"] = obs
    if safety: s["safety"] = safety
    return s

methods = [
 {"id":"v60","name":"V60 / Pour over","summary":"Konik filtreden elle döküşle temiz ve berrak fincan.",
  "requiredEquipment":"Kağıt filtre; gooseneck kettle önerilir",
  "checklist":["Suyu ısıt","Kağıt filtreyi sıcak suyla durula, suyu dök","Kahveyi tart","Orta-ince öğüt","Teraziyi sıfırla"],
  "tips":["Bloom: kahve ağırlığının yaklaşık 2 katı su ile 30-45 saniye.","Suyu merkezden dışa doğru spiral dök, kağıdın kenarlarına doğrudan dökme.","Döküşü birkaç aşamaya böl, su seviyesini sabit tut.","Son aşamada yatak düz kalmalı. Kenarlarda yüksek kalan kahve düzensiz extraction göstergesidir.","Süre 4 dakikayı aşıyorsa öğütmeyi kalınlaştır, 2 dakikanın altındaysa incelt."]},
 {"id":"chemex","name":"Chemex","summary":"Kalın filtreyle çok temiz, hafif gövdeli fincan.",
  "requiredEquipment":"Chemex kalın filtresi",
  "checklist":["Suyu ısıt","Kalın filtreyi bol sıcak suyla durula, suyu dök","Üç katlı tarafı akıtıcıya (spout) yerleştir","Kahveyi tart ve orta-kalın öğüt"],
  "tips":["Kalın filtreyi bol sıcak suyla durula; kağıt tadı bu yöntemde daha belirgindir.","Üç katlı filtre tarafı akıtıcı tarafına gelmeli, yoksa filtre spout'u kapatır ve akış durur.","Kalın filtre akışı yavaşlattığından V60'a göre daha kalın öğüt."]},
 {"id":"french_press","name":"French Press","summary":"Daldırma yöntemiyle gövdeli, yağlı fincan.",
  "requiredEquipment":"Yok",
  "checklist":["Suyu ısıt","Press'i sıcak suyla ısıt, suyu dök","Kahveyi tart ve kalın öğüt"],
  "tips":["4. dakikada üstteki kabuğu kaşıkla kır, yüzeydeki köpüğü ve partikülleri al.","Pistonu yavaşça ve yalnız yüzeye kadar indir; dibe bastırmak tortuyu kaldırır.","Kahveyi press içinde bırakma; tamamını fincana veya sürahiye aktar.","Bulanıklığı azaltmak için demleme sonrası 2-3 dakika ek bekleme yapılabilir."]},
 {"id":"aeropress","name":"AeroPress","summary":"Kısa sürede temiz ve yoğun fincan; çok yönlü.",
  "requiredEquipment":"AeroPress filtresi",
  "checklist":["Suyu ısıt","Filtreyi kapağa yerleştir ve durula","Kahveyi tart ve orta-ince öğüt","AeroPress'i ters (inverted) kur"],
  "tips":["Ters (inverted) yöntem erken damlamayı önler.","Basış yaklaşık 20-30 saniye sürmeli, yavaş ve dengeli olmalı.","Tıslama sesi duyulunca basışı durdur; son kısım acılık taşır.","Konsantre demleyip sıcak suyla seyreltmek sık kullanılan bir varyanttır."]},
 {"id":"drip_machine","name":"Filtre kahve makinesi","summary":"Makineyle kolay ve tekrarlanabilir filtre kahve.",
  "requiredEquipment":"Kağıt veya kalıcı filtre",
  "checklist":["Hazneye su koy","Kağıt filtreyi yerleştir ve durula","Kahveyi tart ve orta incelikte öğüt"],
  "tips":["Ucuz makinelerin çoğu 93 °C hedefine ulaşamaz; SCA sertifikalı ev tipi makineler tercih edilir.","Kahveyi ısıtıcı plakada bekletme; tat yanık ve acılaşır. Termos sürahi tercih et.","Makineyi düzenli olarak kireçten arındır."]},
 {"id":"moka_pot","name":"Moka pot","summary":"Ocak üstünde yoğun, espressoya yakın kahve.",
  "requiredEquipment":"Ocak",
  "checklist":["Suyu ısıt","Kahveyi tart; filtreden ince, espressodan kalın öğüt"],
  "tips":["Hazneyi güvenlik valfinin altına kadar doldur, valfi su ile kapatma.","Hazneye önceden ısıtılmış su koy; soğuk su yanık tada yol açar.","Sepeti silme doldur ama bastırma.","Orta-düşük ateş kullan. Akış açık renge dönüp fışırtı başlayınca ocaktan al ve alt gövdeyi soğuk suyla soğut."]},
 {"id":"espresso","name":"Espresso","summary":"Basınçla kısa sürede yoğun shot; dial-in gerektirir.",
  "requiredEquipment":"Espresso makinesi, espresso grinder, terazi",
  "checklist":["Makineyi ısıt; portafilter ve fincanı ısıt","Gruptan kısa bir su akışı (flush) yap","Dozu tart","Topakları WDT ile dağıt","Düz ve tutarlı tamp yap"],
  "tips":["Çıktı ağırlığını terazide ölç; hacim veya krema yüksekliği güvenilir değildir.","Tamp'ta basınç miktarından çok düzlük önemlidir.","Shot hızlı ve ekşi ise öğütmeyi incelt, yavaş ve acı ise kalınlaştır.","Dipsiz portafilter'da erken açılan açık renkli akışlar veya fışkırmalar channeling işaretidir."]},
 {"id":"turkish","name":"Türk kahvesi","summary":"Cezvede köpüklü, telvesiyle servis edilen kahve.",
  "requiredEquipment":"Cezve veya Türk kahve makinesi",
  "checklist":["Suyu içilecek fincanla ölç","Kahveyi tart (fincan başına 6-7 g)","Fincan sayısına uygun cezve seç"],
  "tips":["Her zaman soğuk suyla başla; su ölçüsünü içilecek fincanla al.","Kahve ve şekeri başta soğuk suda karıştır; ısınmaya başlayınca karıştırma.","Düşük-orta ateş kullan; yüksek ateş köpük oluşmadan taşmaya neden olur.","Kenarlardan köpük kabarınca ocaktan al; kahve kaynatılmaz.","Birden fazla fincanda köpüğü önce fincanlara paylaştır, kalan kahveyi kısa ısıtıp ekle.","Geniş cezvede az kahve yapıldığında köpük oluşmaz."]},
 {"id":"cold_brew","name":"Cold brew","summary":"Saatlerce soğuk demlenen, yumuşak konsantre.",
  "requiredEquipment":"Kavanoz, filtre",
  "checklist":["Kahveyi tart ve kalın öğüt","Temiz bir kavanoz hazırla","Soğuk veya oda sıcaklığında su hazırla"],
  "tips":["Kalın öğütme zorunludur; ince öğütme bulanık ve acı sonuç verir.","Demleme sonrası çift filtreleme (metal + kağıt) tortuyu alır.","Konsantreyi buzdolabında kapalı kapta sakla, servis anında su veya sütle seyrelt."]},
]

recipes = [
 {"id":"sys-v60","method":"v60","name":"V60 başlangıç","coffeeG":15,"waterG":250,
  "grind":{"label":"Orta-ince"},"temperatureC":94,"targetTimeS":150,"targetTimeMaxS":210,"source":SCA,
  "steps":[
   step("Bloom: 30 g'a kadar dök","weight","Kahveyi tamamen ıslat.",30,10,safety="hotWater"),
   step("Bekle (bloom)","time","Gazın çıkmasını bekle.",30,35),
   step("150 g'a kadar dök","weight","Merkezden dışa spiral dök.",150,30),
   step("Bekle","time","Su seviyesinin inmesini bekle.",150,15),
   step("250 g'a kadar dök","weight","Kenarlara doğrudan dökme.",250,30),
   step("Süzülmeyi bekle","confirm","Yatak düz kalmalı.",250,None,"Su tamamen süzülünce"),
  ]},
 {"id":"sys-chemex","method":"chemex","name":"Chemex başlangıç","coffeeG":30,"waterG":500,
  "grind":{"label":"Orta-kalın"},"temperatureC":95,"targetTimeS":240,"targetTimeMaxS":300,"source":SCA,
  "steps":[
   step("Bloom: 60 g'a kadar dök","weight","Kahveyi tamamen ıslat.",60,15,safety="hotWater"),
   step("Bekle (bloom)","time","Gazın çıkmasını bekle.",60,30),
   step("300 g'a kadar dök","weight","Yavaş spiral döküş.",300,45),
   step("Bekle","time","",300,20),
   step("500 g'a kadar dök","weight","Kenarlara doğrudan dökme.",500,40),
   step("Süzülmeyi bekle","confirm","",500,None,"Su tamamen süzülünce"),
  ]},
 {"id":"sys-french-press","method":"french_press","name":"French Press başlangıç","coffeeG":30,"waterG":420,
  "grind":{"label":"Kalın"},"temperatureC":95,"targetTimeS":240,"targetTimeMaxS":240,"source":GEN,
  "steps":[
   step("420 g suyun tamamını dök","weight","Tüm kahveyi ıslat.",420,20,safety="hotWater"),
   step("Demlen","time","Kapağı kapat, pistonu indirme.",420,220),
   step("Kabuğu kır, köpüğü al","confirm","Kaşıkla kabuğu kır, yüzeydeki köpük ve partikülleri al.",None,None,"Yüzey temizlenince"),
   step("Pistonu yüzeye indir ve aktar","confirm","Dibe bastırma. Tamamını fincana veya sürahiye aktar.",None,None,"Aktarım bitince"),
  ]},
 {"id":"sys-aeropress","method":"aeropress","name":"AeroPress (ters yöntem)","coffeeG":15,"waterG":225,
  "grind":{"label":"Orta-ince"},"temperatureC":85,"targetTimeS":90,"targetTimeMaxS":150,"source":GEN,
  "steps":[
   step("225 g'a kadar dök","weight","Ters kurulmuş AeroPress'e dök.",225,15,safety="hotWater"),
   step("Karıştır, kapağı tak ve demlen","time","3 kez karıştır.",225,60),
   step("Çevir ve yavaşça bas","time","Basış 20-30 sn sürmeli.",225,25),
   step("Tıslama duyulunca dur","confirm","Son kısım acılık taşır.",None,None,"Tıslama sesi gelince"),
  ]},
 {"id":"sys-drip","method":"drip_machine","name":"Filtre makinesi 1 litre","coffeeG":60,"waterG":1000,
  "grind":{"label":"Orta"},"targetTimeS":240,"targetTimeMaxS":360,"source":"SCA (55-60 g/L)",
  "steps":[
   step("Makineyi çalıştır","confirm","Su ve filtreli kahve yerinde olmalı.",None,None,"Makine çalışınca"),
   step("Demlenmesini bekle","time","",None,300),
   step("Sürahiyi ısıtıcıdan al","confirm","Isıtıcı plakada bekletmek tadı acılaştırır.",None,None,"Demleme bitince"),
  ]},
 {"id":"sys-moka","method":"moka_pot","name":"Moka pot başlangıç","coffeeG":17,"waterG":150,
  "grind":{"label":"Filtreden ince, espressodan kalın"},"targetTimeS":240,"targetTimeMaxS":360,"source":GEN,
  "steps":[
   step("Hazneye sıcak su koy","confirm","Güvenlik valfinin altına kadar doldur, valfi kapatma.",None,None,"Hazne dolunca","pressureValve"),
   step("Sepeti doldur, bastırma","confirm","Silme doldur, tamp yapma. Gövdeyi bezle tutarak kapat.",None,None,"Pot kapatılınca","hotWater"),
   step("Orta-düşük ateşe koy","confirm","Kapağı açık tutup akışı izle.",None,None,"Akış başlayınca","stove"),
   step("Fışırtı başlayınca ocaktan al","confirm","Akış açık renge dönünce ocaktan al.",None,None,"Fışırtı başlayınca"),
   step("Alt gövdeyi soğut","confirm","Soğuk su altında soğutarak extraction'ı durdur.",None,None,"Soğutunca"),
  ]},
 {"id":"sys-espresso","method":"espresso","name":"Espresso 1:2","coffeeG":18,"waterG":36,
  "grind":{"label":"İnce"},"temperatureC":93,"targetTimeS":25,"targetTimeMaxS":30,"source":GEN,
  "steps":[
   step("Shot'ı başlat","confirm","Portafilter'ı tak, fincanı teraziye koy.",None,None,"Pompa çalışınca"),
   step("36 g çıkışta durdur","weight","Hedef 25-30 sn.",36,None,"Terazide 36 g görünce"),
  ]},
 {"id":"sys-turkish","method":"turkish","name":"Türk kahvesi 2 fincan","coffeeG":13,"waterG":135,"cups":2,
  "grind":{"label":"Çok ince (toz)"},"targetTimeS":120,"targetTimeMaxS":240,"source":GEN,
  "steps":[
   step("Soğuk su, kahve ve şekeri karıştır","confirm","Ölçüyü fincanla al.",None,None,"Karıştırınca"),
   step("Düşük-orta ateşe koy","confirm","Isınırken karıştırma.",None,None,"Kenarlarda köpük kabarınca","stove"),
   step("Köpüğü fincanlara paylaştır","confirm","",None,None,"Paylaştırınca"),
   step("Kısa ısıt ve fincanlara ekle","confirm","Kaynatma.",None,None,"Yeniden kabarınca"),
  ]},
 {"id":"sys-cold-brew","method":"cold_brew","name":"Cold brew konsantre","coffeeG":100,"waterG":800,
  "grind":{"label":"Kalın"},"targetTimeS":50400,"targetTimeMaxS":64800,"source":GEN,
  "notes":"Servis: 1 ölçü konsantreye 1 ölçü su veya süt.",
  "steps":[
   step("Kahve ve suyu karıştır","weight","Tüm kahve ıslanmalı.",800,None,"Karıştırınca"),
   step("Demlen (14 saat)","time","Kapalı kapta, oda sıcaklığında veya buzdolabında.",800,50400),
   step("Çift filtrele","confirm","Önce metal, sonra kağıt filtre.",None,None,"Filtreleyince"),
   step("Buzdolabına kaldır","confirm","Kapalı kapta sakla.",None,None,"Kaldırınca"),
  ]},
]

POUR = ["v60","chemex"]
def rule(id, symptom, tier, var, dir, text, reason, amount=0, methods=None):
    r = {"id":id,"symptom":symptom,"tier":tier,"variable":var,"direction":dir,"amount":amount,"text":text,"reason":reason}
    if methods: r["methods"] = methods
    return r

UNDER_R = "Ekşi ve kısa biten tat, çözünebilir maddelerin yeterince suya geçmediğini (under-extraction) gösterir."
OVER_R = "Acı ve kurutan tat, fazla maddenin suya geçtiğini (over-extraction) gösterir."
rules = [
 rule("under-1","underExtraction",1,"grind","finer","Öğütmeyi bir kademe incelt",UNDER_R+" İnce öğütme extraction'ı hızlandırır.",1),
 rule("under-2","underExtraction",2,"temperature","increase","Su sıcaklığını 2-3 °C artır",UNDER_R+" Sıcak su daha hızlı çözer.",2),
 rule("under-2-imm","underExtraction",2,"time","increase","Demleme süresini 30 sn uzat",UNDER_R+" Uzun temas daha fazla çözer.",30,["french_press","aeropress"]),
 rule("under-2-cold","underExtraction",2,"time","increase","Demleme süresini 2 saat uzat",UNDER_R+" Soğuk suda extraction yavaştır.",7200,["cold_brew"]),
 rule("under-2-drip","underExtraction",2,"equipment","none","Makinenin 93 °C'ye ulaştığını kontrol et",UNDER_R+" Pek çok makine yeterli sıcaklığa ulaşamaz.",0,["drip_machine"]),
 rule("over-1","overExtraction",1,"grind","coarser","Öğütmeyi bir kademe kalınlaştır",OVER_R+" Kalın öğütme extraction'ı yavaşlatır.",1),
 rule("over-2","overExtraction",2,"temperature","decrease","Su sıcaklığını 2-3 °C düşür",OVER_R+" Daha düşük sıcaklık daha yavaş çözer.",2),
 rule("over-2-imm","overExtraction",2,"time","decrease","Demleme süresini 30 sn kısalt",OVER_R+" Kısa temas daha az çözer.",30,["french_press","aeropress"]),
 rule("over-2-cold","overExtraction",2,"time","decrease","Demleme süresini 2 saat kısalt",OVER_R,7200,["cold_brew"]),
 rule("over-2-drip","overExtraction",2,"equipment","none","Kahveyi ısıtıcı plakada bekletme",OVER_R+" Plakada bekleyen kahve acılaşır.",0,["drip_machine"]),
 rule("uneven-1-pour","unevenExtraction",1,"technique","none","Döküş tekniğini düzelt: merkezden spiral, sabit su seviyesi","Hem ekşi hem acı tat, kahvenin bir kısmının az, bir kısmının fazla demlendiğini gösterir.",0,POUR),
 rule("uneven-1-esp","unevenExtraction",1,"technique","none","Dağıtımı (WDT) ve tampı düzelt","Hem ekşi hem acı tat channeling ile düzensiz extraction'a işaret eder.",0,["espresso"]),
 rule("uneven-1","unevenExtraction",1,"technique","none","Karıştırmayı ve döküşü tutarlı yap","Hem ekşi hem acı tat düzensiz extraction'a işaret eder."),
 rule("uneven-2","unevenExtraction",2,"equipment","none","Öğütücünü sorgula; blade grinder ise burr grinder'a geç","Homojen olmayan öğütme aynı fincanda ekşi ve acıyı birlikte üretir."),
 rule("weak-1","weak",1,"ratio","decrease","Kahve miktarını artır (oranı bir birim daralt, ör. 1:17 → 1:16)","Tat dengeli ama sulu: sorun extraction değil strength. Yalnız oran değiştirilir.",1),
 rule("strong-1","strong",1,"ratio","increase","Su miktarını artır (oranı bir birim genişlet, ör. 1:15 → 1:16)","Tat dengeli ama ağır: sorun extraction değil strength. Yalnız oran değiştirilir.",1),
 rule("stale-1","stale",1,"beans","none","Kavurma tarihi yakın çekirdek kullan","Düz ve kartonsu tat bayat çekirdeğin tipik belirtisidir."),
 rule("stale-2","stale",2,"beans","none","Kahveyi demlemeden hemen önce öğüt","Öğütülmüş kahve aromasını dakikalar içinde kaybetmeye başlar."),
 rule("water-1","waterQuality",1,"water","none","Filtrelenmiş veya düşük-orta mineralli şişe suyu kullan","Fincanın %90'dan fazlası sudur; klor ve koku doğrudan tada geçer."),
 rule("water-2","waterQuality",2,"equipment","none","Makineyi kireçten arındır","Kireç metalik ve düz tat bırakır."),
 rule("drawdown-1","slowDrawdown",1,"grind","coarser","Öğütmeyi bir kademe kalınlaştır","Çok ince öğütme veya fazla fines akışı yavaşlatır ve filtreyi tıkar.",1),
 rule("drawdown-2","slowDrawdown",2,"technique","none","Döküşte karıştırmayı azalt","Fazla karıştırma fines'ı filtrenin dibine taşır."),
 rule("shotfast-1","shotFast",1,"grind","finer","Öğütmeyi incelt","Shot 20 sn'den kısa aktı; su kahveden çok hızlı geçiyor.",1,["espresso"]),
 rule("shotfast-2","shotFast",2,"dose","increase","Dozu 0,5 g artır","Daha yüksek doz direnci artırır.",0.5,["espresso"]),
 rule("shotslow-1","shotSlow",1,"grind","coarser","Öğütmeyi kalınlaştır","Shot 35 sn'den uzun aktı; su kahveden çok yavaş geçiyor.",1,["espresso"]),
 rule("shotslow-2","shotSlow",2,"dose","decrease","Dozu 0,5 g azalt","Daha düşük doz direnci azaltır.",0.5,["espresso"]),
 rule("nofoam-1","turkishNoFoam",1,"heat","none","Ateşi kıs, ısınırken karıştırma","Yüksek ateş ve karıştırma köpüğü dağıtır.",0,["turkish"]),
 rule("nofoam-2","turkishNoFoam",2,"beans","none","Taze, toz incelikte kahve ve uygun boy cezve kullan","Bayat veya iri öğütülmüş kahve ve büyük cezve köpük tutmaz.",0,["turkish"]),
 rule("overflow-1","turkishOverflow",1,"technique","none","Köpük kabarmaya başlayınca ocaktan al","Kahve kaynama noktasına ulaşınca taşar.",0,["turkish"]),
 rule("overflow-2","turkishOverflow",2,"heat","none","Ateşi kıs","Düşük ateş köpüğün yükselişini izlemeye zaman tanır.",0,["turkish"]),
 rule("burnt-1","mokaBurnt",1,"heat","none","Hazneye sıcak su koy ve orta-düşük ateş kullan","Soğuk suyla başlamak ve yüksek ateş kahveyi üst gövdede yakar.",0,["moka_pot"]),
 rule("burnt-2","mokaBurnt",2,"technique","none","Fışırtı başlayınca ocaktan al, alt gövdeyi soğut","Fışırtıdan sonra gelen akış yanık ve metalik tat taşır.",0,["moka_pot"]),
]

glossary = [
 ["Brew ratio","Kahve ağırlığının su ağırlığına oranı, 1:16 gibi gösterilir (1 g kahveye 16 g su)."],
 ["Grind size","Öğütme inceliği. Yönteme göre çok inceden (Türk kahvesi) kalına (French Press, cold brew) değişir."],
 ["Extraction","Kahvedeki çözünebilir maddelerin suya geçme oranı. Az ise ekşi/sulu, fazla ise acı/buruk tat oluşur."],
 ["TDS","Total Dissolved Solids. Fincandaki çözünmüş madde yoğunluğu (strength)."],
 ["Bloom","Pour over başlangıcında az su ile kahvenin ıslatılıp gazının (CO₂) çıkmasının beklendiği ön adım."],
 ["Dial-in","Tat sonucuna göre öğütme, oran, sıcaklık veya süreyi tek tek ayarlayarak hedef tada yaklaşma süreci."],
 ["Channeling","Espresso'da suyun kahve yatağında tercihli kanallar açarak düzensiz extraction oluşturması."],
 ["Burr grinder","İki öğütme yüzeyi arasında kahveyi kıran öğütücü. Blade grinder'a göre homojen sonuç verir."],
 ["Blade grinder","Bıçaklı öğütücü. Parçacık boyutu homojen olmadığından aynı fincanda ekşi ve acı tat üretir."],
 ["Fines","Öğütme sırasında oluşan çok ince parçacıklar. Fazlası akışı yavaşlatır ve acılık üretir."],
 ["WDT","Weiss Distribution Technique. Espresso dozundaki topakları ince iğneyle karıştırarak dağıtma."],
 ["Tamp","Espresso'da öğütülmüş kahveyi portafilter içinde düz ve tutarlı biçimde sıkıştırma."],
 ["Portafilter","Espresso makinesinde kahvenin konduğu saplı sepet tutucu."],
 ["Gooseneck kettle","İnce, kıvrık ağızlı kettle. Pour over'da akışı kontrol etmeyi sağlar."],
 ["Immersion","Kahvenin demleme süresince suyun içinde bekletildiği yöntem (French Press, AeroPress, cold brew)."],
 ["Pour over","Suyun öğütülmüş kahvenin üzerine elle döküldüğü ve filtreden süzüldüğü yöntem."],
 ["Crust","French Press'te yüzeyde toplanan kahve tabakası (kabuk)."],
 ["Inverted","AeroPress'in ters çevrilerek kurulduğu, erken damlamayı önleyen yöntem."],
 ["Retention","Öğütücünün içinde kalan kahve miktarı."],
 ["PID","Espresso makinesinde su sıcaklığını sabit tutan elektronik kontrol."],
 ["Pre-infusion","Espresso'da tam basınç öncesi kahvenin düşük basınçla ıslatılması."],
 ["Rehber mod","Uygulamanın demleme adımlarını zamanlayıcıyla birlikte tek tek yönettiği ekran."],
 ["Demleme kaydı","Bir demlemenin parametreleri, sonucu ve tat değerlendirmesinden oluşan günlük kaydı."],
]

guides = [
 {"id":"brewer","name":"Demleme aracı","lookFor":["Yönteminize uygun boyut (fincan sayısı)","Kolay temizlenen malzeme","Yaygın bulunan filtre"],"avoid":["Filtresi zor bulunan modeller"]},
 {"id":"hand_grinder","name":"El grinder'ı","lookFor":["Çelik burr","İki noktalı rulman (yatak) ile sabit eksen","Kademe hassasiyeti","Sökülüp temizlenebilirlik"],"avoid":["Seramik burr ve ucuz plastik gövde","Sallantılı mil"]},
 {"id":"electric_grinder","name":"Elektrikli filtre grinder'ı","lookFor":["Flat veya conical burr","Düşük retention","Statik kontrolü","Yöntem aralığını kapsayan kademe sayısı"],"avoid":["Blade (bıçaklı) öğütücüler: homojen olmayan parçacık ekşi ve acıyı aynı fincanda üretir"]},
 {"id":"espresso_grinder","name":"Espresso grinder'ı","lookFor":["Kademesiz (stepless) veya çok ince kademeli ayar","Tek doz kullanımı","Düşük retention"],"avoid":["Yalnız filtre için tasarlanmış grinder ile espresso denemek"],"methods":["espresso"]},
 {"id":"scale","name":"Terazi","lookFor":["0,1 g çözünürlük","Hızlı tepki","Dahili zamanlayıcı","Şarjlı batarya","Espresso için damlama tablasına sığan boyut"],"avoid":["1 g çözünürlüklü mutfak terazisi (espresso ve küçük dozlarda yetersiz)"]},
 {"id":"kettle","name":"Kettle","lookFor":["Gooseneck ince akışlı ağız","Derece bazlı sıcaklık ayarı","Sıcak tutma"],"avoid":["Geniş ağızlı standart kettle ile pour over (akış kontrol edilemez)"],"methods":["v60","chemex"]},
 {"id":"espresso_machine","name":"Espresso makinesi","lookFor":["PID sıcaklık kontrolü","Pre-infusion","Hızlı ısınma","Standart portafilter çapı (54 mm veya 58 mm)","Süt için yeterli buhar gücü"],"avoid":["Basınçlandırılmış (pressurized) sepetle sınırlı modeller: dial-in imkanı vermez"],"methods":["espresso"]},
 {"id":"drip_machine","name":"Filtre kahve makinesi","lookFor":["SCA sertifikası (93 °C hedefine ulaşma)","Düzgün dağıtımlı duş başlığı","Termos sürahi"],"avoid":["Isıtıcı plakalı, düşük sıcaklıkta demleyen ucuz modeller"],"methods":["drip_machine"]},
 {"id":"turkish","name":"Türk kahve makinesi / cezve","lookFor":["Makinede köpük sensörü ve taşma koruması","Kolay temizlenen hazne","Cezvede ince boyun ve kalın taban","Fincan sayısına uygun hacim"],"avoid":["İhtiyacın çok üzerinde hacimli cezve (köpük oluşmaz)"],"methods":["turkish"]},
]

def cat(id, category, brand, model, methods=None, usesFilter=False, budget="mid"):
    c = {"id":id,"category":category,"brand":brand,"model":model,"verifiedAt":VERIFIED,"usesFilter":usesFilter,"budget":budget}
    if methods: c["methods"] = methods
    return c

catalog = [
 cat("hario-v60-02","brewer","Hario","V60 02",["v60"],True,"low"),
 cat("chemex-6","brewer","Chemex","Classic 6 fincan",["chemex"],True,"mid"),
 cat("aeropress-original","brewer","AeroPress","Original",["aeropress"],True,"low"),
 cat("bodum-chambord","brewer","Bodum","Chambord",["french_press"],False,"low"),
 cat("bialetti-moka-express","brewer","Bialetti","Moka Express",["moka_pot"],False,"low"),
 cat("1zpresso-j","hand_grinder","1Zpresso","J",None,False,"mid"),
 cat("1zpresso-k-ultra","hand_grinder","1Zpresso","K-Ultra",None,False,"high"),
 cat("fellow-ode-2","electric_grinder","Fellow","Ode Gen 2",None,False,"high"),
 cat("baratza-encore-esp","electric_grinder","Baratza","Encore ESP",None,False,"mid"),
 cat("oxo-brew-conical","electric_grinder","OXO","Brew Conical",None,False,"low"),
 cat("eureka-mignon-specialita","espresso_grinder","Eureka","Mignon Specialita",["espresso"],False,"high"),
 cat("baratza-encore-esp-espresso","espresso_grinder","Baratza","Encore ESP",["espresso"],False,"mid"),
 cat("fellow-tally-pro","scale","Fellow","Tally Pro",None,False,"high"),
 cat("acaia-lunar","scale","Acaia","Lunar",None,False,"high"),
 cat("wacaco-exagram","scale","Wacaco","Exagram",None,False,"low"),
 cat("fellow-stagg-ekg-pro","kettle","Fellow","Stagg EKG Pro",["v60","chemex"],False,"high"),
 cat("breville-bambino","espresso_machine","Breville/Sage","Bambino",["espresso"],False,"low"),
 cat("breville-bambino-plus","espresso_machine","Breville/Sage","Bambino Plus",["espresso"],False,"mid"),
 cat("gaggia-classic-pro","espresso_machine","Gaggia","Classic Pro",["espresso"],False,"mid"),
 cat("rancilio-silvia","espresso_machine","Rancilio","Silvia",["espresso"],False,"high"),
 cat("lelit-mara-x","espresso_machine","Lelit","Mara X",["espresso"],False,"high"),
]

maintenance = [
 {"id":"descale-espresso","title":"Kireç çözme","intervalDays":60,"methods":["espresso"],
  "description":"Üreticinin kireç çözücüsüyle hazne ve kazanı temizleyin. Sert suda aralığı kısaltın."},
 {"id":"backflush","title":"Grup başlığı temizliği (backflush)","intervalDays":14,"methods":["espresso"],
  "description":"Kör sepet ve temizlik tozuyla grup başlığını yıkayın."},
 {"id":"gasket","title":"Grup contası kontrolü","intervalDays":180,"methods":["espresso"],
  "description":"Conta sertleştiyse veya portafilter kenarından sızıntı varsa değiştirin."},
 {"id":"descale-drip","title":"Kireç çözme","intervalDays":60,"methods":["drip_machine"],
  "description":"Makineyi kireç çözücüyle bir döngü çalıştırın, ardından iki kez temiz suyla durulayın."},
 {"id":"descale-turkish","title":"Kireç çözme","intervalDays":60,"methods":["turkish"],
  "description":"Türk kahve makinesinin haznesini üreticinin önerdiği çözücüyle temizleyin."},
 {"id":"moka-gasket","title":"Moka pot contası ve filtresi","intervalDays":180,"methods":["moka_pot"],
  "description":"Conta ve süzgeci kontrol edin; çatlak veya sertleşme varsa değiştirin."},
 {"id":"grinder-clean","title":"Öğütücü temizliği","intervalDays":30,"requiresBurrGrinder":True,
  "description":"Burr'ları fırçayla temizleyin; yağ birikimi bayat tat bırakır."},
]

flags = {"maintenance":True,"share":True,"backup":True,"tts":True}

bundle = {"version":VERSION,"maintenance":maintenance,"flags":flags,"methods":methods,"recipes":recipes,"rules":rules,
  "glossary":[{"term":t,"definition":d} for t,d in glossary],"guides":guides,"catalog":catalog}
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out = os.path.join(root,"app","assets","content","bundle.json")
with open(out,"w",encoding="utf-8") as f:
    json.dump(bundle,f,ensure_ascii=False,indent=1)
print("yazıldı:",out)
