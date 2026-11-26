/// Çekirdek stoğu ve tazelik hesapları (KHV-FR-LOG-004, ENG-003 - ENG-005).
library;

/// Kavurma tarihinden bu yana geçen tam gün sayısı (KHV-FR-LOG-004).
///
/// Saat dilimi farklarından etkilenmemek için yalnız takvim günleri
/// karşılaştırılır. Kavurma tarihi bugünden sonraysa 0 döner.
int daysSinceRoast(DateTime roastDate, DateTime today) {
  final a = DateTime.utc(roastDate.year, roastDate.month, roastDate.day);
  final b = DateTime.utc(today.year, today.month, today.day);
  final d = b.difference(a).inDays;
  return d < 0 ? 0 : d;
}

/// Tazelik bildirimi gerekiyor mu (KHV-FR-ENG-005, varsayılan 30 gün).
bool isPastFreshness(
  DateTime roastDate,
  DateTime today, {
  int thresholdDays = 30,
}) => daysSinceRoast(roastDate, today) > thresholdDays;

/// Demleme sonrası kalan stok (g); 0'ın altına inmez (KHV-FR-ENG-003).
double deductStock(double remainingG, double doseG) {
  final r = remainingG - doseG;
  return r < 0 ? 0 : (r * 10).roundToDouble() / 10;
}

/// Ortalama doz (g); kayıt yoksa `null`.
double? averageDose(Iterable<double> doses) {
  var n = 0;
  var sum = 0.0;
  for (final d in doses) {
    if (d > 0) {
      n++;
      sum += d;
    }
  }
  return n == 0 ? null : sum / n;
}

/// Stok, ortalama doza göre 3 demlemelik miktarın altına indiyse `true`
/// (KHV-FR-ENG-004).
bool isLowStock(double remainingG, double? averageDoseG, {int brews = 3}) {
  if (averageDoseG == null || averageDoseG <= 0) return false;
  return remainingG < averageDoseG * brews;
}

/// Kalan demleme sayısı tahmini.
int? brewsLeft(double remainingG, double? averageDoseG) {
  if (averageDoseG == null || averageDoseG <= 0) return null;
  return (remainingG / averageDoseG).floor();
}
