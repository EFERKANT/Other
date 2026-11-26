import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'data/database.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Gömülü yazı tiplerinin lisansları "Açık kaynak lisansları" sayfasında
  // görünür (OFL 1.1 koşulu, KB-026).
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in const [
      ('Figtree', 'assets/fonts/Figtree-OFL.txt'),
      ('Caveat', 'assets/fonts/Caveat-OFL.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString(file));
    }
  });
  await initializeDateFormatting('tr_TR');
  final db = AppDatabase(driftDatabase(name: 'ev_kahvesi'));
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const EvKahvesiApp(),
    ),
  );
}
