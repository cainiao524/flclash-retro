import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/retro_theme.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/pages/home.dart';
import 'package:fl_clash/pages/retro_home.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/classic_home.dart';
import 'package:fl_clash/views/dashboard/dashboard.dart';
import 'package:fl_clash/views/dashboard/widgets/home_motion.dart';
import 'package:fl_clash/views/dashboard/widgets/retro_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> mountHome(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      dashboardStateProvider.overrideWithValue(
        const DashboardState(dashboardWidgets: []),
      ),
      navigationItemsStateProvider.overrideWithValue(
        NavigationItemsState(
          value: [
            NavigationItem(
              icon: const Icon(Icons.dashboard),
              label: PageLabel.dashboard,
              builder: (_) => const DashboardView(
                key: GlobalObjectKey(PageLabel.dashboard),
              ),
            ),
            NavigationItem(
              icon: const Icon(Icons.folder),
              label: PageLabel.profiles,
              builder: (_) => const Scaffold(
                body: Text('配置内容', key: GlobalObjectKey(PageLabel.profiles)),
              ),
            ),
            NavigationItem(
              icon: const Icon(Icons.build),
              label: PageLabel.tools,
              builder: (_) => const Scaffold(
                body: Text('工具内容', key: GlobalObjectKey(PageLabel.tools)),
              ),
            ),
          ],
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  globalState.container = container;
  container.read(viewSizeProvider.notifier).value = size;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        navigatorKey: globalState.navigatorKey,
        locale: const Locale('zh', 'CN'),
        theme: buildRetroTheme(brightness: Brightness.light),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.delegate.supportedLocales,
        builder: (context, child) {
          globalState.measure = Measure.of(context, 1);
          globalState.theme = CommonTheme.of(context, 1);
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          );
        },
        home: const RetroHomePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(844, 390),
    const Size(800, 1280),
    const Size(1280, 800),
  ]) {
    testWidgets('配置与工具切换后导航主页仍是复古界面 ${size.width}', (tester) async {
      await mountHome(tester, size);
      await tester.tap(find.byType(HomeConnectButton));
      await tester.pumpAndSettle();
      expect(find.text('配置内容'), findsOneWidget);
      final navigation = find
          .byWidgetPredicate(
            (widget) => widget is NavigationBar || widget is NavigationRail,
          )
          .hitTestable();
      await tester.tap(
        find.descendant(of: navigation, matching: find.byIcon(Icons.build)),
      );
      await tester.pumpAndSettle();
      expect(find.text('工具内容'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: navigation,
          matching: find.byIcon(Icons.home_outlined),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RetroDashboardPanel), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(DashboardView), findsNothing);
      expect(globalState.navigatorKey.currentState!.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('启动首先展示复古设计 ${size.width} × ${size.height}', (tester) async {
      await mountHome(tester, size);
      expect(find.byType(ClassicHomeView), findsOneWidget);
      expect(
        tester
            .widget<ClassicHomeView>(find.byType(ClassicHomeView))
            .originalLayout,
        isFalse,
      );
      expect(find.byType(RetroDashboardPanel), findsOneWidget);
      expect(
        find.text(AppLocalizations.current.classicPermanent),
        findsNothing,
      );
      expect(find.text(AppLocalizations.current.rule), findsOneWidget);
      expect(find.text(AppLocalizations.current.global), findsOneWidget);
      expect(find.text(AppLocalizations.current.direct), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(DashboardView), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(HomeConnectButton), findsOneWidget);
      expect(find.byType(HomeWave), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, const Color(0xFF3E5D9C));
      expect(globalState.navigatorKey.currentState!.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('仪表盘是高级入口且系统返回回到复古主页 ${size.width}', (tester) async {
      await mountHome(tester, size);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('仪表盘'));
      await tester.pumpAndSettle();
      expect(find.byType(DashboardView), findsOneWidget);
      expect(find.byType(ClassicHomeView), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ClassicHomeView), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      expect(globalState.navigatorKey.currentState!.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('原 APK 经典页是附加入口，返回不丢复古功能主页', (tester) async {
    await mountHome(tester, const Size(390, 844));
    await tester.tap(find.byTooltip(AppLocalizations.current.classicHome));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ClassicHomeView>(find.byType(ClassicHomeView))
          .originalLayout,
      isTrue,
    );
    expect(find.byType(RetroDashboardPanel), findsNothing);
    expect(
      find.text(AppLocalizations.current.classicPermanent),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(RetroDashboardPanel), findsOneWidget);
    expect(globalState.navigatorKey.currentState!.canPop(), isFalse);
  });

  testWidgets('从原 APK 经典页打开配置后返回默认功能主页', (tester) async {
    await mountHome(tester, const Size(1280, 800));
    await tester.tap(find.byTooltip(AppLocalizations.current.classicHome));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(HomeConnectButton));
    await tester.pumpAndSettle();
    expect(find.text('配置内容'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(RetroDashboardPanel), findsOneWidget);
    expect(find.byType(ClassicHomeView, skipOffstage: false), findsOneWidget);
    expect(globalState.navigatorKey.currentState!.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('手机横屏大字可滚动到全部快捷入口', (tester) async {
    await mountHome(tester, const Size(640, 320), textScale: 2);
    expect(find.byKey(const ValueKey('retro-functional-wide')), findsOneWidget);
    await tester.ensureVisible(find.text(AppLocalizations.current.tools));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppLocalizations.current.tools));
    await tester.pumpAndSettle();
    expect(find.text('工具内容'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('空配置连接跳转配置，返回仍是复古主页', (tester) async {
    final container = await mountHome(tester, const Size(390, 844));
    await tester.tap(find.byType(HomeConnectButton));
    await tester.pumpAndSettle();
    expect(container.read(currentPageLabelProvider), PageLabel.profiles);
    expect(find.text('配置内容'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ClassicHomeView), findsOneWidget);
    expect(container.read(currentPageLabelProvider), PageLabel.dashboard);
    expect(tester.takeException(), isNull);
  });

  testWidgets('仪表盘房子按钮回到已有主页而不是再叠一层', (tester) async {
    await mountHome(tester, const Size(390, 844));
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('仪表盘'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppLocalizations.current.classicHome));
    await tester.pumpAndSettle();
    expect(find.byType(ClassicHomeView, skipOffstage: false), findsOneWidget);
    expect(globalState.navigatorKey.currentState!.canPop(), isFalse);
  });
}
