import 'package:kahve_core/kahve_core.dart';
import 'package:material_ui/material_ui.dart';

import 'theme.dart';

/// "Sohbet" sahnesi: gün batımına bakan masada seçilen yöntemin kahve takımı
/// (KB-026). Çizim 390x250 tasarım alanında yapılır ve genişliğe ölçeklenir.
class CoffeeScene extends StatelessWidget {
  /// Seçilen yöntemle bir sahne oluşturur.
  const CoffeeScene({super.key, required this.method});

  /// Masadaki takımı belirleyen yöntem.
  final BrewMethod method;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<SceneColors>()!;
    return Semantics(
      image: true,
      label: 'Gün batımına bakan masada ${methodSetLabel(method)}',
      child: AspectRatio(
        aspectRatio: 390 / 250,
        child: CustomPaint(painter: _ScenePainter(method, colors, _View.scene)),
      ),
    );
  }
}

/// Hazırlık ekranında yöntemin yakın plan çizimi (KB-026).
class MethodArt extends StatelessWidget {
  /// Yöntemin yakın plan çizimini oluşturur.
  const MethodArt({super.key, required this.method});

  /// Çizilecek yöntem.
  final BrewMethod method;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<SceneColors>()!;
    return Semantics(
      image: true,
      label: methodSetLabel(method),
      child: AspectRatio(
        aspectRatio: 220 / 121,
        child: CustomPaint(
          painter: _ScenePainter(method, colors, _View.closeUp),
        ),
      ),
    );
  }
}

/// Listelerde yöntem simgesi: takımın demleme aracı, simge boyutunda.
/// Malzeme simgelerinin yerine geçer; her yöntemin kendi çizimi vardır,
/// başka anlamda kullanılmaz (KB-018, KB-026).
class MethodGlyph extends StatelessWidget {
  /// Yöntem simgesi oluşturur.
  const MethodGlyph(this.method, {super.key, this.size = 28});

  /// Çizilecek yöntem.
  final BrewMethod method;

  /// Kenar uzunluğu.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<SceneColors>()!;
    // Yanında her zaman yöntem adı yazar; ekran okuyucu iki kez okumasın.
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _ScenePainter(method, colors, _View.glyph)),
      ),
    );
  }
}

/// Erişilebilirlik ve testler için takımın sözlü tarifi.
String methodSetLabel(BrewMethod m) => switch (m) {
  BrewMethod.turkish => 'cezve ve iki Türk kahvesi fincanı',
  BrewMethod.v60 => 'sürahi üstünde V60 damlatıcı ve bir kupa',
  BrewMethod.chemex => 'Chemex ve bir kupa',
  BrewMethod.espresso => 'iki espresso fincanı',
  BrewMethod.frenchPress => 'French press ve iki kupa',
  BrewMethod.aeropress => 'kupa üstünde AeroPress',
  BrewMethod.dripMachine => 'filtre kahve makinesi ve bir kupa',
  BrewMethod.mokaPot => 'moka pot ve iki küçük fincan',
  BrewMethod.coldBrew => 'cold brew kavanozu ve buzlu iki bardak',
};

enum _View { scene, closeUp, glyph }

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.method, this.c, this.view);

  final BrewMethod method;
  final SceneColors c;
  final _View view;

  @override
  void paint(Canvas canvas, Size size) {
    final box = switch (view) {
      _View.scene => const Rect.fromLTWH(0, 0, 390, 250),
      _View.closeUp => const Rect.fromLTWH(40, 118, 220, 121),
      _View.glyph => const Rect.fromLTWH(46, 122, 108, 108),
    };
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..scale(size.width / box.width, size.height / box.height)
      ..translate(-box.left, -box.top);
    if (view == _View.scene) _background(canvas);
    if (view == _View.closeUp) {
      canvas.drawRect(const Rect.fromLTWH(40, 226, 220, 14), _fill(c.table));
    }
    _set(canvas, cups: view != _View.glyph);
    canvas.restore();
  }

  Paint _fill(Color color, [double opacity = 1]) => Paint()
    ..color = color.withValues(alpha: opacity)
    ..isAntiAlias = true;

  Paint _stroke(Color color, double width, [double opacity = 1]) => Paint()
    ..color = color.withValues(alpha: opacity)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;

  Path _poly(List<double> xy) {
    final p = Path()..moveTo(xy[0], xy[1]);
    for (var i = 2; i < xy.length; i += 2) {
      p.lineTo(xy[i], xy[i + 1]);
    }
    return p..close();
  }

  void _rrect(
    Canvas k,
    double x,
    double y,
    double w,
    double h,
    double r,
    Paint p,
  ) => k.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
    p,
  );

  void _oval(Canvas k, double cx, double cy, double rx, double ry, Paint p) =>
      k.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
        p,
      );

  void _background(Canvas k) {
    const bands = [0.0, 70.0, 115.0, 150.0, 178.0, 200.0];
    for (var i = 0; i < c.sky.length; i++) {
      k.drawRect(
        Rect.fromLTRB(0, bands[i], 390, bands[i + 1]),
        _fill(c.sky[i]),
      );
    }
    k
      ..drawCircle(const Offset(300, 200), 36, _fill(c.sun))
      ..drawPath(
        Path()
          ..moveTo(0, 190)
          ..cubicTo(60, 172, 110, 176, 160, 186)
          ..cubicTo(200, 194, 240, 186, 270, 196)
          ..lineTo(270, 200)
          ..lineTo(0, 200)
          ..close(),
        _fill(c.ridge),
      )
      ..drawRect(const Rect.fromLTWH(0, 200, 390, 50), _fill(c.sea));
    final glint = _stroke(c.glint, 2, 0.7);
    k
      ..drawLine(const Offset(262, 210), const Offset(342, 210), glint)
      ..drawLine(const Offset(274, 218), const Offset(330, 218), glint)
      ..drawRect(const Rect.fromLTWH(0, 226, 390, 24), _fill(c.table));
  }

  void _steam(Canvas k, List<double> xs, double top) {
    final p = _stroke(c.foam, 2, 0.6);
    for (final x in xs) {
      k.drawPath(
        Path()
          ..moveTo(x, top)
          ..quadraticBezierTo(x - 6, top - 6, x, top - 10)
          ..quadraticBezierTo(x + 6, top - 14, x, top - 18),
        p,
      );
    }
  }

  void _mug(Canvas k, double x, Color color) {
    k.drawRect(Rect.fromLTWH(x, 194, 34, 32), _fill(color));
    k.drawArc(
      Rect.fromLTWH(x + 28, 200, 14, 16),
      -1.57,
      3.14,
      false,
      _stroke(color, 4),
    );
  }

  void _smallCup(Canvas k, double cx, Color color, {bool crema = false}) {
    _oval(k, cx, 226, 22, 4, _fill(c.saucer));
    k.drawPath(
      _poly([cx - 13, 205, cx + 13, 205, cx + 10, 225, cx - 10, 225]),
      _fill(color),
    );
    if (crema) _oval(k, cx, 206, 11, 2.5, _fill(c.crema));
  }

  void _set(Canvas k, {required bool cups}) {
    switch (method) {
      case BrewMethod.turkish:
        k
          ..drawPath(
            _poly([60, 176, 104, 176, 98, 226, 66, 226]),
            _fill(c.copper),
          )
          ..drawLine(
            const Offset(102, 186),
            const Offset(146, 178),
            _stroke(c.copper, 7),
          );
        _oval(k, 82, 177, 22, 5, _fill(c.foam));
        if (cups) {
          _smallCup(k, 183, c.foam);
          _smallCup(k, 229, c.apricot);
          _steam(k, [178, 224], 198);
        }
      case BrewMethod.v60:
        k
          ..drawPath(
            _poly([64, 190, 120, 190, 126, 226, 58, 226]),
            _fill(c.glass, 0.55),
          )
          ..drawPath(
            _poly([62, 206, 122, 206, 126, 226, 58, 226]),
            _fill(c.coffee),
          )
          ..drawPath(
            _poly([56, 152, 128, 152, 106, 186, 78, 186]),
            _fill(c.apricot),
          );
        _rrect(k, 52, 148, 80, 6, 3, _fill(c.apricot));
        if (cups) {
          _mug(k, 168, c.foam);
          _steam(k, [180, 192], 188);
        }
      case BrewMethod.chemex:
        k
          ..drawPath(
            _poly([66, 140, 124, 140, 100, 184, 90, 184]),
            _fill(c.glass, 0.6),
          )
          ..drawPath(
            _poly([90, 184, 100, 184, 128, 226, 62, 226]),
            _fill(c.glass, 0.6),
          )
          ..drawPath(
            _poly([80, 204, 110, 204, 128, 226, 62, 226]),
            _fill(c.coffee),
          );
        _rrect(k, 84, 176, 22, 12, 4, _fill(c.crema));
        if (cups) {
          _mug(k, 168, c.apricot);
          _steam(k, [180, 192], 188);
        }
      case BrewMethod.espresso:
        if (cups) {
          _smallCup(k, 92, c.foam, crema: true);
          _smallCup(k, 156, c.apricot, crema: true);
          _steam(k, [88, 152], 198);
        } else {
          _rrect(k, 56, 138, 88, 20, 6, _fill(c.metal));
          k.drawLine(
            const Offset(96, 158),
            const Offset(96, 196),
            _stroke(c.crema, 3),
          );
          _smallCup(k, 96, c.foam, crema: true);
        }
      case BrewMethod.frenchPress:
        _rrect(k, 68, 150, 48, 76, 4, _fill(c.glass, 0.5));
        _rrect(k, 68, 176, 48, 50, 3, _fill(c.coffee));
        _rrect(k, 64, 146, 56, 6, 3, _fill(c.copper));
        k
          ..drawLine(
            const Offset(92, 146),
            const Offset(92, 132),
            _stroke(c.copper, 3),
          )
          ..drawCircle(const Offset(92, 130), 5, _fill(c.copper))
          ..drawArc(
            const Rect.fromLTWH(108, 160, 18, 40),
            -1.57,
            3.14,
            false,
            _stroke(c.copper, 5),
          );
        if (cups) {
          _mug(k, 156, c.foam);
          _mug(k, 206, c.apricot);
          _steam(k, [166, 216], 188);
        }
      case BrewMethod.aeropress:
        _rrect(k, 74, 186, 42, 40, 4, _fill(c.foam));
        _rrect(k, 70, 180, 50, 7, 3, _fill(c.copper));
        _rrect(k, 78, 140, 34, 42, 4, _fill(c.glass, 0.7));
        _rrect(k, 78, 160, 34, 22, 3, _fill(c.coffee));
        _rrect(k, 82, 124, 26, 20, 4, _fill(c.metal));
        if (cups) {
          _mug(k, 168, c.apricot);
          _steam(k, [180, 192], 188);
        }
      case BrewMethod.dripMachine:
        _rrect(k, 56, 136, 66, 90, 8, _fill(c.metal));
        _rrect(k, 56, 136, 66, 20, 8, _fill(c.copper));
        k
          ..drawPath(
            _poly([70, 196, 108, 196, 112, 226, 66, 226]),
            _fill(c.glass, 0.7),
          )
          ..drawPath(
            _poly([68, 210, 110, 210, 112, 226, 66, 226]),
            _fill(c.coffee),
          );
        _rrect(k, 98, 164, 14, 6, 2, _fill(c.apricot));
        if (cups) {
          _mug(k, 168, c.foam);
          _steam(k, [180, 192], 188);
        }
      case BrewMethod.mokaPot:
        k
          ..drawPath(
            _poly([70, 226, 110, 226, 104, 190, 76, 190]),
            _fill(c.metal),
          )
          ..drawPath(
            _poly([74, 186, 106, 186, 100, 150, 80, 150]),
            _fill(c.metal),
          )
          ..drawLine(
            const Offset(80, 152),
            const Offset(70, 146),
            _stroke(c.metal, 4),
          )
          ..drawLine(
            const Offset(102, 160),
            const Offset(118, 176),
            _stroke(c.copper, 5),
          )
          ..drawCircle(const Offset(90, 145), 4, _fill(c.copper));
        _rrect(k, 78, 186, 24, 6, 2, _fill(c.coffee));
        if (cups) {
          _smallCup(k, 170, c.foam, crema: true);
          _smallCup(k, 220, c.apricot, crema: true);
          _steam(k, [166, 216], 198);
        }
      case BrewMethod.coldBrew:
        _rrect(k, 64, 152, 56, 74, 10, _fill(c.coffee));
        _rrect(k, 60, 144, 64, 12, 4, _fill(c.copper));
        _rrect(k, 74, 166, 12, 12, 2, _fill(c.foam, 0.5));
        _rrect(k, 96, 178, 12, 12, 2, _fill(c.foam, 0.5));
        if (cups) {
          for (final x in [160.0, 206.0]) {
            k.drawPath(
              _poly([x, 178, x + 28, 178, x + 25, 226, x + 3, 226]),
              _fill(c.iced),
            );
            _rrect(k, x + 6, 186, 10, 10, 2, _fill(c.foam, 0.7));
            _rrect(k, x + 14, 198, 9, 9, 2, _fill(c.foam, 0.7));
          }
        }
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.method != method || old.view != view || old.c != c;
}

/// Demleme adımının türü; animasyonun ne göstereceğini belirler.
enum BrewMotion {
  /// Su dökülüyor (hedef ağırlıklı adım).
  pour,

  /// Bekleme: damla, buhar, kabarcık.
  wait,

  /// Gözlem bekleniyor (ör. köpük kabarması).
  watch,
}

/// Rehberli demlemede yöntemin canlı çizimi: dökülen su, düşen damlalar,
/// kabaran köpük, yükselen buhar (KB-027). Adım bilgisinden küçük kalır
/// (KHV-HMI-001); [animate] `false` ise (duraklatıldı veya "hareketi azalt",
/// KHV-HMI-024) donuk çizilir.
class BrewAnimation extends StatefulWidget {
  /// Bir demleme animasyonu oluşturur.
  const BrewAnimation({
    super.key,
    required this.method,
    required this.motion,
    required this.animate,
    this.size = 96,
  });

  /// Çizilecek yöntem.
  final BrewMethod method;

  /// Adımın türü.
  final BrewMotion motion;

  /// Oynasın mı.
  final bool animate;

  /// Kenar uzunluğu.
  final double size;

  @override
  State<BrewAnimation> createState() => _BrewAnimationState();
}

class _BrewAnimationState extends State<BrewAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(BrewAnimation old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.animate) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<SceneColors>()!;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _ScenePainter(widget.method, colors, _View.glyph),
            foregroundPainter: _MotionPainter(
              widget.method,
              widget.motion,
              colors,
              _c.value,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animasyon katmanı; [_ScenePainter] ile aynı tasarım alanında çizer.
class _MotionPainter extends CustomPainter {
  _MotionPainter(this.method, this.motion, this.c, this.t);

  final BrewMethod method;
  final BrewMotion motion;
  final SceneColors c;
  final double t;

  static const _box = Rect.fromLTWH(46, 122, 108, 108);

  /// Dökülen suyun ulaştığı yükseklik; dökme olmayan yöntemlerde `null`.
  double? get _pourTo => switch (method) {
    BrewMethod.v60 => 152,
    BrewMethod.chemex => 142,
    BrewMethod.frenchPress => 150,
    BrewMethod.aeropress => 140,
    BrewMethod.coldBrew => 146,
    _ => null,
  };

  bool get _drips =>
      method == BrewMethod.v60 ||
      method == BrewMethod.chemex ||
      method == BrewMethod.aeropress ||
      method == BrewMethod.dripMachine;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..scale(size.width / _box.width, size.height / _box.height)
      ..translate(-_box.left, -_box.top);
    final pourTo = _pourTo;
    if (motion == BrewMotion.pour && pourTo != null) {
      _stream(canvas, 92, 120, pourTo, c.foam);
    }
    if (method == BrewMethod.espresso) _stream(canvas, 96, 158, 202, c.crema);
    if (_drips && motion != BrewMotion.pour) _drops(canvas);
    if (method == BrewMethod.turkish) _foam(canvas);
    if (method == BrewMethod.coldBrew) _bubbles(canvas);
    _steam(canvas);
    canvas.restore();
  }

  void _stream(Canvas k, double x, double from, double to, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    // Akan suyun içinde aşağı kayan çizgiler.
    const dash = 6.0;
    for (var y = from - dash * 2 + (t * dash * 2); y < to; y += dash * 2) {
      k.drawLine(
        Offset(x, y.clamp(from, to)),
        Offset(x, (y + dash).clamp(from, to)),
        p,
      );
    }
  }

  void _drops(Canvas k) {
    final top = method == BrewMethod.dripMachine ? 156.0 : 188.0;
    const bottom = 206.0;
    for (final phase in [0.0, 0.5]) {
      final f = (t + phase) % 1;
      k.drawCircle(
        Offset(92, top + (bottom - top) * f),
        2.2,
        Paint()..color = c.coffee.withValues(alpha: 1 - f * 0.6),
      );
    }
  }

  void _foam(Canvas k) {
    // Köpük kabarır: gözlem adımında belirgin, beklerken hafif.
    final rise = motion == BrewMotion.watch ? 10.0 : 4.0;
    final h = rise * (0.5 - (t - 0.5).abs()) * 2;
    final p = Paint()..color = c.foam;
    k
      ..drawOval(
        Rect.fromCenter(center: Offset(82, 176 - h), width: 44, height: 12),
        p,
      )
      ..drawCircle(Offset(72, 172 - h), 4 + h / 3, p)
      ..drawCircle(Offset(92, 171 - h), 5 + h / 3, p);
  }

  void _bubbles(Canvas k) {
    final p = Paint()..color = c.foam.withValues(alpha: 0.5);
    for (final (x, phase) in [(78.0, 0.0), (96.0, 0.33), (108.0, 0.66)]) {
      final f = (t + phase) % 1;
      k.drawCircle(Offset(x, 220 - 56 * f), 2.5, p);
    }
  }

  void _steam(Canvas k) {
    final (double x, double top) = switch (method) {
      BrewMethod.turkish => (82, 168),
      BrewMethod.mokaPot => (70, 142),
      BrewMethod.espresso => (96, 200),
      BrewMethod.coldBrew => (0, 0),
      _ => (92, 140),
    };
    if (top == 0) return;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final (dx, phase) in [(-6.0, 0.0), (6.0, 0.5)]) {
      final f = (t + phase) % 1;
      final y = top - 14 * f;
      p.color = c.foam.withValues(alpha: 0.6 * (1 - f));
      k.drawPath(
        Path()
          ..moveTo(x + dx, y)
          ..quadraticBezierTo(x + dx - 4, y - 5, x + dx, y - 9)
          ..quadraticBezierTo(x + dx + 4, y - 13, x + dx, y - 17),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_MotionPainter old) =>
      old.t != t || old.motion != motion || old.method != method;
}
