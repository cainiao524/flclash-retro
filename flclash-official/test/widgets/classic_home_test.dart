import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/classic_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> openClassic(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  globalState.container = container;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.delegate.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ClassicHomeView(),
                ),
              ),
              child: const Text('打开经典主页'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('打开经典主页'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(320, 568),
    const Size(800, 1280),
    const Size(1280, 800),
  ]) {
    testWidgets('经典主页适配 ${size.width} × ${size.height}', (tester) async {
      await openClassic(tester, size);
      expect(
        find.byKey(
          ValueKey(
            size.width > size.height
                ? 'classic-landscape'
                : size.width >= 700
                ? 'classic-tablet'
                : 'classic-portrait',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Google官网'), findsOneWidget);
      expect(find.text('Youtube官网'), findsOneWidget);
      expect(find.text('获取永久使用权'), findsOneWidget);
      expect(find.text('当前代理组无法选中'), findsNothing);
      expect(find.text('出站模式'), findsNothing);
      expect(tester.takeException(), null);
      if (size.width > size.height) {
        expect(
          tester.getCenter(find.byKey(const ValueKey('classic-connect'))).dx,
          lessThan(
            tester.getCenter(find.byKey(const ValueKey('classic-line'))).dx,
          ),
        );
      }
    });
  }

  testWidgets('手机大字体与旋转保持经典页可操作', (tester) async {
    await openClassic(tester, const Size(320, 568), textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('获取永久使用权'));
    await tester.tap(find.text('获取永久使用权'));
    await tester.pumpAndSettle();
    expect(find.textContaining('不会收取费用'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(TextButton, AppLocalizations.current.confirm),
    );
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('classic-landscape')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('没有配置时连接跳转配置并关闭经典页', (tester) async {
    final container = await openClassic(tester, const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('classic-connect')));
    await tester.pumpAndSettle();
    expect(container.read(currentPageLabelProvider), PageLabel.profiles);
    expect(find.byType(ClassicHomeView), findsNothing);
    expect(find.text('打开经典主页'), findsOneWidget);
  });

  testWidgets('经典侧栏返回功能主页', (tester) async {
    final container = await openClassic(tester, const Size(390, 844));
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('仪表盘'));
    await tester.pumpAndSettle();
    expect(container.read(currentPageLabelProvider), PageLabel.dashboard);
    expect(find.byType(ClassicHomeView), findsNothing);
    expect(tester.takeException(), null);
  });

  testWidgets('原购买入口只展示说明且模式连接官方状态', (tester) async {
    final container = await openClassic(tester, const Size(390, 844));
    await tester.tap(find.text('获取永久使用权'));
    await tester.pumpAndSettle();
    expect(find.textContaining('不会收取费用'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(TextButton, AppLocalizations.current.confirm),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(ClassicHomeView));
    await tester.tap(
      find.widgetWithText(
        CheckedPopupMenuItem<Mode>,
        context.appLocalizations.direct,
      ),
    );
    await tester.pumpAndSettle();
    expect(container.read(patchClashConfigProvider).mode, Mode.direct);
    expect(tester.takeException(), null);
  });
}
