import 'dart:math' as math;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/widgets/inherited.dart';
import 'package:flutter/material.dart';

const _orange = Color(0xFFFF7901);

class HomeMotion extends StatefulWidget {
  final bool running;
  final Widget child;

  const HomeMotion({super.key, required this.running, required this.child});

  @override
  State<HomeMotion> createState() => _HomeMotionState();
}

class _HomeMotionState extends State<HomeMotion>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final _phase = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  bool _reduced = false;
  bool _visible = true;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    _visible =
        TickerMode.valuesOf(context).enabled &&
        PageActivityScope.isActiveOf(context) &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    _sync();
  }

  @override
  void didUpdateWidget(covariant HomeMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _foreground = state == AppLifecycleState.resumed;
      _sync();
    });
  }

  void _sync() {
    if (_reduced) {
      _entrance.value = 1;
    } else if (_visible && _foreground) {
      if (!_entrance.isCompleted && !_entrance.isAnimating) _entrance.forward();
    } else {
      _entrance.stop();
    }
    if (!_reduced && _visible && _foreground && widget.running) {
      if (!_phase.isAnimating) _phase.repeat();
    } else {
      _phase.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phase.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TickerMode(
    enabled: _visible && _foreground,
    child: HomeMotionData(
      phase: _phase,
      entrance: _entrance,
      reduced: _reduced,
      child: widget.child,
    ),
  );
}

class HomeMotionData extends InheritedWidget {
  final Animation<double> phase;
  final Animation<double> entrance;
  final bool reduced;

  const HomeMotionData({
    super.key,
    required this.phase,
    required this.entrance,
    required this.reduced,
    required super.child,
  });

  static HomeMotionData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeMotionData>()!;

  @override
  bool updateShouldNotify(HomeMotionData oldWidget) =>
      reduced != oldWidget.reduced;
}

class HomeEntrance extends StatelessWidget {
  final double start;
  final Widget child;

  const HomeEntrance({super.key, this.start = 0, required this.child});

  @override
  Widget build(BuildContext context) {
    final motion = HomeMotionData.of(context);
    final animation = motion.entrance.drive(
      CurveTween(curve: Interval(start, 1, curve: Curves.easeOutCubic)),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(
          Tween(begin: const Offset(0, .045), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }
}

class HomePress extends StatefulWidget {
  final VoidCallback onTap;
  final ShapeBorder? shape;
  final Widget child;

  const HomePress({
    super.key,
    required this.onTap,
    this.shape,
    required this.child,
  });

  @override
  State<HomePress> createState() => _HomePressState();
}

class _HomePressState extends State<HomePress> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: reduced
          ? 1
          : _pressed
          ? .955
          : _hovered
          ? 1.015
          : 1,
      duration: reduced ? Duration.zero : const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      child: InkWell(
        customBorder: widget.shape,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        onHover: (value) => setState(() => _hovered = value),
        onTap: widget.onTap,
        child: widget.child,
      ),
    );
  }
}

class HomeConnectButton extends StatelessWidget {
  final double size;
  final bool running;
  final VoidCallback onPressed;

  const HomeConnectButton({
    super.key,
    this.size = 200,
    required this.running,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final motion = HomeMotionData.of(context);
    final strings = context.appLocalizations;
    return Semantics(
      button: true,
      label: running ? strings.stopVpn : strings.startVpn,
      child: SizedBox(
        width: size,
        height: size,
        child: HomePress(
          shape: const CircleBorder(),
          onTap: onPressed,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/retro/new_startroot_waibiankuanng.png',
                excludeFromSemantics: true,
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: Ink.image(
                    image: const AssetImage(
                      'assets/images/retro/new_startroot_normal.png',
                    ),
                    fit: BoxFit.contain,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: motion.reduced
                                    ? Duration.zero
                                    : const Duration(milliseconds: 220),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                child: Text(
                                  running ? strings.stop : strings.connection,
                                  key: ValueKey(running),
                                  style: const TextStyle(
                                    color: _orange,
                                    fontSize: 35,
                                  ),
                                ),
                              ),
                              const Text(
                                'VPN',
                                style: TextStyle(color: _orange, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: RepaintBoundary(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: running ? 1 : 0),
                    duration: motion.reduced
                        ? Duration.zero
                        : const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (_, active, _) => CustomPaint(
                      painter: _ConnectHalo(
                        phase: motion.phase,
                        active: active,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectHalo extends CustomPainter {
  final Animation<double> phase;
  final double active;

  _ConnectHalo({required this.phase, required this.active})
    : super(repaint: phase);

  @override
  void paint(Canvas canvas, Size size) {
    if (active == 0) return;
    final center = size.center(Offset.zero);
    final pulse = (math.sin(phase.value * math.pi * 4) + 1) / 2;
    final radius = size.shortestSide * .465;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 + pulse * 3
        ..color = Colors.white.withValues(alpha: active * (.16 + pulse * .14)),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5
      ..color = _orange.withValues(alpha: active * .8);
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(bounds, phase.value * math.pi * 2, .7, false, paint);
    canvas.drawArc(
      bounds,
      phase.value * math.pi * 2 + math.pi,
      .7,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ConnectHalo oldDelegate) =>
      active != oldDelegate.active || phase != oldDelegate.phase;
}

class HomeWave extends StatelessWidget {
  final Color color;

  const HomeWave({super.key, required this.color});

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ClipRect(
      child: CustomPaint(
        painter: HomeWavePainter(
          phase: HomeMotionData.of(context).phase,
          color: color,
        ),
      ),
    ),
  );
}

class HomeWavePainter extends CustomPainter {
  final Animation<double> phase;
  final Color color;

  HomeWavePainter({required this.phase, required this.color})
    : super(repaint: phase);

  @override
  void paint(Canvas canvas, Size size) {
    for (var layer = 0; layer < 3; layer++) {
      final baseline = size.height * (.46 + layer * .1);
      final amplitude = math.min(size.height * .18, 9.0);
      final path = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width + 8; x += 8) {
        final progress = x / math.max(size.width, 1);
        final angle =
            progress * math.pi * 2 +
            phase.value * math.pi * 2 * (layer == 1 ? -1 : 1) +
            layer * 1.8;
        path.lineTo(x, baseline + math.sin(angle) * amplitude);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = layer == 2
              ? color
              : Colors.white.withValues(alpha: .09 + layer * .04),
      );
    }
  }

  @override
  bool shouldRepaint(HomeWavePainter oldDelegate) =>
      phase != oldDelegate.phase || color != oldDelegate.color;
}
