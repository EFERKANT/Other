import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import 'common.dart';

/// Yardım: aranabilir sözlük, sık sorulan sorular ve ilk demleme rehberi
/// (KHV-FR-HLP-001, HLP-002).
class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

const _faq = [
  (
    'İlk demlememde neye dikkat etmeliyim?',
    'Elinizdeki araca uygun başlangıç tarifini seçin, hazırlık listesini '
        'izleyin ve rehber modda adımları takip edin. Bittiğinde tadı '
        'işaretleyin; bir sonraki denemede tek bir değişikliği uygulayın.',
  ),
  (
    'Neden her seferinde tek bir öneri alıyorum?',
    'Aynı anda iki şeyi değiştirirseniz hangisinin işe yaradığını '
        'bilemezsiniz. Dial-in, her denemede tek değişkenle ilerler.',
  ),
  (
    'Terazim yok, ne yapmalıyım?',
    'Tariflerde gramın yanında yaklaşık kaşık karşılığını gösteriyoruz. '
        'Ancak kaşık ölçüsü belirgin sapar; 0,1 g hassasiyetli bir terazi en '
        'iyi ilk yatırımdır.',
  ),
  (
    'Ekşi ile acıyı nasıl ayırırım?',
    'Ekşi tat limon gibi keskin ve kısa biter. Acı tat fazla demlenmiş çay '
        'gibi ağzı kurutur ve uzun kalır. Emin değilseniz tat ekranındaki '
        '"Emin değilim" sorularını kullanın.',
  ),
  (
    'Verilerim nerede saklanıyor?',
    'Hesap gerekmez; demleme günlüğünüz yalnız bu cihazda saklanır.',
  ),
];

class _HelpScreenState extends ConsumerState<HelpScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yardım ve sözlük')),
      body: ContentGate(
        builder: (context, content) {
          final terms = [
            for (final g in content.glossary)
              if (matchesQuery(_query, [g.term, g.definition])) g,
          ];
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SectionTitle('Sık sorulan sorular'),
              for (final (q, a) in _faq)
                ExpansionTile(
                  title: Text(q),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [Text(a)],
                ),
              const SectionTitle('Sözlük'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SearchBar(
                  hintText: 'Terim ara',
                  leading: const Icon(Icons.search),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              for (final g in terms)
                ListTile(title: Text(g.term), subtitle: Text(g.definition)),
              if (terms.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Bu aramaya uyan terim yok.'),
                ),
            ],
          );
        },
      ),
    );
  }
}
