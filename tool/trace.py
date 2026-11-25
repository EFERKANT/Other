#!/usr/bin/env python3
"""Gereksinim-test izlenebilirliği (Bölüm 11).

Test dosyalarındaki gereksinim kimliklerini toplar ve docs/kalite/matris.csv
ile karşılaştırır. Kısaltmalar çözülür: "KHV-FR-SOC-001, SOC-002, 010" ve
"KHV-FR-DIA-002 - DIA-006" aralığı.

Kullanım:
  python3 tool/trace.py            # docs/kalite/izlenebilirlik.md üretir
  python3 tool/trace.py --check    # MVP otomatik gereksinimlerde açık varsa 1 döner
  python3 tool/trace.py --json     # gereksinim -> test dosyaları (matris güncellemesi için)

Kapı kuralı: önceliği MVP olan ve otomasyonu "Otomatik" olan her gereksinimin
en az bir otomatik testte geçmesi ya da docs/kalite/istisnalar.csv içinde
gerekçesiyle yer alması gerekir.
"""
from __future__ import annotations

import csv
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MATRIX = ROOT / "docs/kalite/matris.csv"
EXCEPTIONS = ROOT / "docs/kalite/istisnalar.csv"
REPORT = ROOT / "docs/kalite/izlenebilirlik.md"
MANUAL = ROOT / "docs/kalite/manuel-senaryolar.md"
TEST_DIRS = [
    ROOT / "packages/kahve_core/test",
    ROOT / "app/test",
    ROOT / "app/integration_test",
    ROOT / "packages/kahve_core/test_stres",
    ROOT / "app/test_stres",
]
# CI'da otomatik doğrulanan gereksinimler iş akışı dosyalarında yazılır.
CI_DIR = ROOT / ".github/workflows"

FR = {"ONB", "RCP", "BRW", "DIA", "EQP", "LOG", "COM", "ENG", "SOC", "SET",
      "HLP", "ADM", "SCL", "PRO", "EVT"}
OTHER = {"CNT", "NFR", "HMI", "ARC"}
MODULES = FR | OTHER
MOD_NAMES = {
    "ONB": "Kurulum", "RCP": "Tarif ve hesaplayıcı", "BRW": "Rehber mod",
    "DIA": "Tat teşhisi", "EQP": "Ekipman rehberi", "LOG": "Günlük ve çekirdek",
    "COM": "Deneyim formu", "CNT": "İçerik", "NFR": "Fonksiyonel olmayan",
    "HMI": "HMI", "ENG": "Günlük kullanım", "SOC": "Sosyal", "ARC": "Altyapı",
    "SET": "Ayarlar", "HLP": "Yardım", "ADM": "Yönetim paneli", "SCL": "Terazi",
    "PRO": "Profil", "EVT": "Etkinlik",
}

TOKEN = re.compile(
    r"(?:KHV-)?(?:FR-)?\b(?P<mod>" + "|".join(sorted(MODULES)) + r")-(?P<n>\d{3})\b"
    r"|(?<![\w.-])(?P<bare>\d{3})\b"
)
CHAIN = re.compile(r"^\s*(,|/|ve)\s*$")
RANGE = re.compile(r"^\s*(-|–|\.\.)\s*$")


def full_id(mod: str, n: int) -> str:
    return f"KHV-FR-{mod}-{n:03d}" if mod in FR else f"KHV-{mod}-{n:03d}"


def extract(text: str) -> set[str]:
    """Metindeki gereksinim kimliklerini kısaltmalarla birlikte çözer."""
    found: set[str] = set()
    prev = None  # (mod, n, end)
    for m in TOKEN.finditer(text):
        gap = text[prev[2]:m.start()] if prev else None
        if m.group("mod"):
            mod, n = m.group("mod"), int(m.group("n"))
        else:
            if not prev or not (CHAIN.match(gap) or RANGE.match(gap)):
                prev = None
                continue
            mod, n = prev[0], int(m.group("bare"))
        if prev and gap is not None and RANGE.match(gap) and prev[0] == mod \
                and prev[1] < n <= prev[1] + 30:
            for k in range(prev[1] + 1, n):
                found.add(full_id(mod, k))
        found.add(full_id(mod, n))
        prev = (mod, n, m.end())
    return found


def load_matrix() -> list[dict[str, str]]:
    with MATRIX.open(encoding="utf-8") as f:
        return list(csv.DictReader(f))


def load_exceptions() -> dict[str, str]:
    if not EXCEPTIONS.exists():
        return {}
    with EXCEPTIONS.open(encoding="utf-8") as f:
        return {r["gereksinim"]: r["gerekce"] for r in csv.DictReader(f)}


def scan_tests() -> dict[str, set[str]]:
    refs: dict[str, set[str]] = defaultdict(set)
    for d in TEST_DIRS:
        if not d.exists():
            continue
        for p in sorted(d.rglob("*.dart")):
            rel = str(p.relative_to(ROOT))
            for rid in extract(p.read_text(encoding="utf-8")):
                refs[rid].add(rel)
    if CI_DIR.exists():
        for p in sorted(CI_DIR.glob("*.yml")):
            rel = str(p.relative_to(ROOT))
            for rid in extract(p.read_text(encoding="utf-8")):
                refs[rid].add(rel)
    return refs


def gated(row: dict[str, str]) -> bool:
    return row["oncelik"].startswith("MVP") and row["otomasyon"] == "Otomatik"


def main(argv: list[str]) -> int:
    matrix = load_matrix()
    known = {r["gereksinim"] for r in matrix}
    exceptions = load_exceptions()
    refs = scan_tests()

    unknown_refs = sorted(set(refs) - known)
    stale_exceptions = sorted(set(exceptions) - known)
    gaps = [r for r in matrix if gated(r) and r["gereksinim"] not in refs
            and r["gereksinim"] not in exceptions]
    covered_exc = sorted(e for e in exceptions if e in refs)

    if "--json" in argv:
        json.dump({k: sorted(v) for k, v in sorted(refs.items())}, sys.stdout,
                  ensure_ascii=False, indent=1)
        return 0

    if "--check" in argv:
        ok = True
        for r in gaps:
            print(f"AÇIK: {r['gereksinim']} ({r['senaryo']}, {r['seviye']}) "
                  "otomatik testte yok ve istisna değil")
            ok = False
        for u in unknown_refs:
            print(f"BİLİNMEYEN KİMLİK testte: {u}")
            ok = False
        for e in stale_exceptions:
            print(f"BİLİNMEYEN KİMLİK istisnada: {e}")
            ok = False
        for e in covered_exc:
            print(f"UYARI: {e} artık testte geçiyor; istisnadan çıkarın")
        mvp_auto = [r for r in matrix if gated(r)]
        print(f"MVP otomatik: {len(mvp_auto)}, testte: "
              f"{sum(r['gereksinim'] in refs for r in mvp_auto)}, istisna: "
              f"{sum(r['gereksinim'] in exceptions for r in mvp_auto)}, açık: {len(gaps)}")
        return 0 if ok else 1

    REPORT.write_text(render(matrix, refs, exceptions), encoding="utf-8")
    MANUAL.write_text(render_manual(matrix, refs), encoding="utf-8")
    print(f"yazıldı: {REPORT.relative_to(ROOT)}, {MANUAL.relative_to(ROOT)}")
    return 0


def render_manual(matrix, refs) -> str:
    """Kalitecinin sürüm adayında koşacağı manuel ve yarı otomatik senaryolar."""
    rows = [r for r in matrix if r["otomasyon"] != "Otomatik"
            and r["oncelik"].startswith("MVP")]
    groups: dict[str, list[dict[str, str]]] = defaultdict(list)
    for r in rows:
        seviye = r["seviye"]
        if "Kullanılabilirlik" in seviye:
            key = "Kullanılabilirlik oturumu"
        elif "Cihaz" in seviye:
            key = "Fiziksel cihaz"
        elif "inceleme" in seviye.lower() or "geçidi" in seviye:
            key = "İnceleme ve sürüm geçidi"
        else:
            key = "Yarı otomatik (otomatik kısım + elle onay)"
        groups[key].append(r)
    out = [
        "# Manuel ve yarı otomatik test senaryoları",
        "",
        "Bu dosya `python3 tool/trace.py` ile üretilir; elle düzenlemeyin.",
        "Her senaryonun adımları ve beklenen sonuçları paylaşılan izlenebilirlik",
        "matrisinde (\"Normal durum senaryosu\" ve \"Sınır ve hata durumu\"",
        "sütunları). Kaliteci her sürüm adayında bu listeyi kopyalayıp sonuç",
        "sütununu doldurur ve [yayın kontrol listesine](yayin-kontrol-listesi.md)",
        "ekler. Otomatik kısmı olan senaryolarda ilgili test dosyası da verilir.",
        "",
        f"MVP kapsamında {len(rows)} senaryo.",
        "",
        "Sonuç: Geçti / Kaldı (hata no) / Bloke (neden) / Uygulanamaz.",
    ]
    order = ["Fiziksel cihaz", "Kullanılabilirlik oturumu",
             "Yarı otomatik (otomatik kısım + elle onay)",
             "İnceleme ve sürüm geçidi"]
    for key in order:
        if key not in groups:
            continue
        out += ["", f"## {key}", "",
                "| Senaryo | Gereksinim | Yöntem | Seviye | Otomatik kısım | Sonuç |",
                "| --- | --- | --- | --- | --- | --- |"]
        for r in groups[key]:
            auto = ", ".join(f"`{Path(p).name}`" for p in sorted(refs.get(r["gereksinim"], [])))
            out.append(f"| {r['senaryo']} | {r['gereksinim']} | {r['dogrulama']} | "
                       f"{r['seviye']} | {auto or '-'} |  |")
    return "\n".join(out) + "\n"


def render(matrix, refs, exceptions) -> str:
    by_mod: dict[str, list[dict[str, str]]] = defaultdict(list)
    for r in matrix:
        by_mod[r["senaryo"].split("-")[1]].append(r)
    out = [
        "# Gereksinim-test izlenebilirliği",
        "",
        "Bu dosya `python3 tool/trace.py` ile üretilir; elle düzenlemeyin.",
        "Kaynak: `docs/kalite/matris.csv` (paylaşılan izlenebilirlik matrisinin",
        "anlık görüntüsü) ve test dosyalarındaki gereksinim kimlikleri.",
        "",
        "| Modül | Gereksinim | MVP | Otomatik testte | Manuel/yarı otomatik | İstisna |",
        "| --- | ---: | ---: | ---: | ---: | ---: |",
    ]
    for mod in sorted(by_mod, key=lambda m: list(MOD_NAMES).index(m)):
        rows = by_mod[mod]
        out.append(
            f"| {MOD_NAMES[mod]} | {len(rows)} | "
            f"{sum(r['oncelik'].startswith('MVP') for r in rows)} | "
            f"{sum(r['gereksinim'] in refs for r in rows)} | "
            f"{sum(r['otomasyon'] != 'Otomatik' for r in rows)} | "
            f"{sum(r['gereksinim'] in exceptions for r in rows)} |")
    out += ["", "## Ayrıntı", "",
            "| Gereksinim | Öncelik | Otomasyon | Durum | Test dosyaları / gerekçe |",
            "| --- | --- | --- | --- | --- |"]
    for r in matrix:
        rid = r["gereksinim"]
        if rid in refs:
            status, note = "Testte", ", ".join(f"`{p}`" for p in sorted(refs[rid]))
        elif rid in exceptions:
            status, note = "İstisna", exceptions[rid]
        elif r["otomasyon"] != "Otomatik":
            status, note = "Manuel kontrol", f"{r['seviye']} (test planı)"
        elif not r["oncelik"].startswith("MVP"):
            status, note = "Sonraki sürüm", ""
        else:
            status, note = "AÇIK", ""
        out.append(f"| {rid} | {r['oncelik']} | {r['otomasyon']} | {status} | {note} |")
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
