/// Türkçe metin ve sayı yardımcıları (KHV-FR-RCP-012, KHV-NFR-031).
library;

const _fold = {
  'ç': 'c',
  'Ç': 'c',
  'ğ': 'g',
  'Ğ': 'g',
  'ı': 'i',
  'I': 'i',
  'İ': 'i',
  'i': 'i',
  'ö': 'o',
  'Ö': 'o',
  'ş': 's',
  'Ş': 's',
  'ü': 'u',
  'Ü': 'u',
  'â': 'a',
  'Â': 'a',
  'î': 'i',
  'û': 'u',
};

/// Aramada kullanılmak üzere metni Türkçe karakterlere duyarsız biçime
/// getirir: küçük harf, aksansız, tek boşluk.
String foldTurkish(String input) {
  final b = StringBuffer();
  for (final ch in input.split('')) {
    final f = _fold[ch];
    b.write(f ?? ch.toLowerCase());
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// [query] kelimelerinin tamamı [haystack] alanlarından birinde geçiyorsa
/// `true`. Boş sorgu her şeyle eşleşir.
bool matchesQuery(String query, Iterable<String> haystack) {
  final q = foldTurkish(query);
  if (q.isEmpty) return true;
  final text = haystack.map(foldTurkish).join(' ');
  return q.split(' ').every(text.contains);
}

/// Sayıyı Türkçe biçimde (ondalık ayırıcı virgül) gösterir. Tam sayılar
/// ondalıksız yazılır; [decimals] en fazla ondalık basamaktır.
String formatNumber(num value, {int decimals = 1}) {
  if (value.isNaN || value.isInfinite) return '-';
  final fixed = value.toStringAsFixed(decimals);
  var s = fixed.contains('.')
      ? fixed.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : fixed;
  if (s == '-0') s = '0';
  return s.replaceAll('.', ',');
}

/// Kullanıcı girdisini sayıya çevirir; ondalık ayırıcı olarak hem virgül hem
/// nokta kabul edilir (KHV-NFR-031). Geçersizse `null`.
double? parseNumber(String input) {
  final s = input.trim().replaceAll(' ', '');
  if (s.isEmpty) return null;
  if (!RegExp(r'^-?\d+([.,]\d+)?$').hasMatch(s)) return null;
  return double.tryParse(s.replaceAll(',', '.'));
}

/// Saniyeyi "d:ss" biçiminde gösterir.
String formatDuration(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = (s % 60).toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$sec';
  return '$m:$sec';
}

/// Oranı "1:16" veya "1:16,5" biçiminde gösterir.
String formatRatio(double ratio) => '1:${formatNumber(ratio)}';
