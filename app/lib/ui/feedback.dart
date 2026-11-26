import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../services/platform.dart';

/// Uygulama içinden hata bildirimi ve öneri (KHV-FR-HLP-003). Cihaz
/// bilgisi yalnız kullanıcı onay verirse eklenir.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _text = TextEditingController();
  bool _bug = true;
  bool _includeInfo = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen kısaca açıklayın.')));
      return;
    }
    final info = _includeInfo
        ? await ref.read(deviceInfoProvider).describe()
        : null;
    final message = [body, if (info != null) '\n---\n$info'].join();
    await ref
        .read(sharerProvider)
        .shareText(
          message,
          subject: _bug ? 'Ev Kahvesi hata bildirimi' : 'Ev Kahvesi önerisi',
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Geri bildirim')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Hata')),
            ButtonSegment(value: false, label: Text('Öneri')),
          ],
          selected: {_bug},
          onSelectionChanged: (s) => setState(() => _bug = s.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _text,
          minLines: 4,
          maxLines: 8,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _bug
                ? 'Ne oldu? Hangi ekrandaydınız?'
                : 'Neyi daha iyi yapabiliriz?',
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _includeInfo,
          title: const Text(
            'Uygulama sürümü, işletim sistemi ve cihaz modelini ekle',
          ),
          subtitle: const Text('Sorunu yeniden üretmemize yardımcı olur.'),
          onChanged: (v) => setState(() => _includeInfo = v ?? false),
        ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: _send,
          child: const Text('Gönder'),
        ),
      ),
    ),
  );
}
