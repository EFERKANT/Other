import 'dart:convert';
import 'dart:io';

import 'package:kahve_core/kahve_core.dart';

/// Uygulamaya gömülü içerik paketini okur; testler gerçek içerikle çalışır.
ContentBundle loadBundle() {
  final file = File('../../app/assets/content/bundle.json');
  return ContentBundle.fromJson(
    (jsonDecode(file.readAsStringSync()) as Map).cast<String, Object?>(),
  );
}

Recipe recipeOf(ContentBundle b, BrewMethod m) =>
    b.recipes.firstWhere((r) => r.method == m);
