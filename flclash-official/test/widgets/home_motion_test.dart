import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/views/dashboard/widgets/home_motion.dart';
import 'package:fl_clash/widgets/inherited.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> mountMotion(
  WidgetTester tester, {
  bool running = true,
  bool active = true,
  bool reduced = false,
  VoidCallback? onTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.delegate.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: child!,
      ),
      home: Scaffold(
        body: PageActivityScope(
          isActive: active,
          child: HomeMotion(
            running: running,
            child: Column(
              children: [
                HomeEntrance(
                  child: HomeConnectButton(
                    running: running,
                    onPressed: onTap ?? () {},
                  ),
                ),
                const SizedBox(
                  height: 60,
                  width: 400,
                  child: HomeWave(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

HomeMotionData motionOf(WidgetTester tester) =>
    HomeMotionData.of(tester.element(find.byType(HomeWave)));

void main() {
  testWidgets('运行时波浪推进，停止后结束持续绘制', (tester) async {
    await mountMotion(tester);
    final phase = motionOf(tester).phase;
    final first = phase.value;
    await tester.pump(const Duration(milliseconds: 500));
    expect(phase.value, greaterThan(first));
    await mountMotion(tester, running: false);
    final stopped = phase.value;
    await tester.pumpAndSettle();
    expect(phase.value, stopped);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('减少动态效果时不循环且直接完成入场', (tester) async {
    await mountMotion(tester, reduced: true);
    final motion = motionOf(tester);
    expect(motion.entrance.value, 1);
    final first = motion.phase.value;
    await tester.pump(const Duration(seconds: 1));
    expect(motion.phase.value, first);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('隐藏页面与后台暂停，恢复后继续', (tester) async {
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await mountMotion(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await mountMotion(tester, active: false);
    final hidden = motionOf(tester).phase.value;
    await tester.pump(const Duration(seconds: 1));
    expect(motionOf(tester).phase.value, hidden);
    await mountMotion(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(motionOf(tester).phase.value, isNot(hidden));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    final paused = motionOf(tester).phase.value;
    await tester.pump(const Duration(seconds: 1));
    expect(motionOf(tester).phase.value, paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(motionOf(tester).phase.value, isNot(paused));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('连续点击不重复派发，取消按压不触发操作', (tester) async {
    var calls = 0;
    await mountMotion(tester, running: false, onTap: () => calls++);
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(HomeConnectButton));
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(calls, 3);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(HomeConnectButton)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(350, 200));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(calls, 3);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('回调失败后按压状态释放，动画不残留', (tester) async {
    await mountMotion(
      tester,
      running: false,
      onTap: () => throw StateError('测试错误'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(HomeConnectButton));
    expect(tester.takeException(), isA<StateError>());
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
