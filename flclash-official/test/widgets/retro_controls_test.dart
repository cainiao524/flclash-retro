import 'dart:async';

import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/dashboard/widgets/home_motion.dart';
import 'package:fl_clash/views/dashboard/widgets/retro_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pages/retro_home_test.dart' show mountHome;

const _profile = Profile(
  id: 1,
  label: '测试配置',
  currentGroupName: '线路组',
  autoUpdateDuration: Duration.zero,
);
const _nodes = [
  Proxy(name: '测试节点', type: 'Shadowsocks'),
  Proxy(name: '用于测试非常长的线路名称在手机横屏及系统大字体下是否正常换行', type: 'Trojan'),
];
const _groups = [
  Group(name: '线路组', type: GroupType.Selector, hidden: false, all: _nodes),
];

class _Setup extends SetupAction {
  final requests = <Completer<void>>[];

  @override
  Future<void> setRunning(bool running, {bool initialize = false}) {
    ref.read(runTimeProvider.notifier).value = running ? 1 : null;
    final request = Completer<void>();
    requests.add(request);
    return request.future;
  }
}

class _Proxies extends ProxiesAction {
  final requests = <(String, String)>[];
  Completer<void>? request;

  @override
  Future<void> changeProxy({
    required String groupName,
    required String proxyName,
  }) {
    requests.add((groupName, proxyName));
    return (request = Completer<void>()).future;
  }

  @override
  void updateGroupsDebounce([Duration? duration]) {}
}

class _Profiles extends ProfilesAction {
  final selections = <(String, String)>[];

  @override
  void updateCurrentSelectedMap(String groupName, String proxyName) {
    selections.add((groupName, proxyName));
  }
}

void main() {
  testWidgets('直连模式的底部代理入口不误导到配置导入', (tester) async {
    final container = await mountHome(
      tester,
      const Size(390, 844),
      profile: _profile,
      groups: _groups,
    );
    container
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith(mode: Mode.direct));
    await tester.pumpAndSettle();
    await tester.tap(find.text('代理'));
    await tester.pumpAndSettle();
    expect(find.textContaining('直连模式不使用代理线路'), findsOneWidget);
    expect(find.text('配置内容'), findsNothing);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(container.read(patchClashConfigProvider).mode, Mode.direct);
  });

  testWidgets('连接请求不冒充原生VPN已连通，旧请求错误不覆盖新操作', (tester) async {
    final setup = _Setup();
    await mountHome(
      tester,
      const Size(390, 844),
      profile: _profile,
      setupAction: setup,
    );
    await tester.tap(find.byType(HomeConnectButton));
    await tester.pump();
    expect(find.text('正在提交操作…'), findsOneWidget);
    expect(find.text('已连接'), findsNothing);
    await tester.tap(find.byType(HomeConnectButton));
    await tester.pump();
    expect(setup.requests, hasLength(2));
    setup.requests.first.completeError(StateError('过时请求'));
    await tester.pump();
    expect(find.text('正在提交操作…'), findsOneWidget);
    expect(find.text('操作未完成，请查看详情后重试'), findsNothing);
    setup.requests.last.complete();
    await tester.pumpAndSettle();
    expect(find.text('未开启 · 点击圆盘连接'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('请求异常可查看原始原因，页面离开后完成不更新已销毁组件', (tester) async {
    final setup = _Setup();
    await mountHome(
      tester,
      const Size(390, 844),
      profile: _profile,
      setupAction: setup,
    );
    await tester.tap(find.byType(HomeConnectButton));
    setup.requests.last.completeError(StateError('测试授权失败'));
    await tester.pump();
    expect(find.text('操作未完成，请查看详情后重试'), findsOneWidget);
    await tester.tap(find.text('详情'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('测试授权失败'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextButton),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byType(HomeConnectButton));
    await tester.pumpWidget(const SizedBox());
    setup.requests.last.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(640, 320),
    const Size(1280, 800),
  ]) {
    testWidgets('线路弹窗适配长名称和双倍字体 ${size.width}', (tester) async {
      await mountHome(
        tester,
        size,
        textScale: 2,
        profile: _profile,
        groups: _groups,
      );
      await tester.ensureVisible(find.text('更换'));
      await tester.tap(find.text('更换'));
      await tester.pumpAndSettle();
      expect(find.byType(RetroRoutesDialog), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(_nodes.last.name),
        100,
        scrollable: find
            .descendant(
              of: find.byType(RetroRoutesDialog),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('线路选择调用官方动作，成功前不保存，失败后可重试', (tester) async {
    final proxies = _Proxies();
    final profiles = _Profiles();
    await mountHome(
      tester,
      const Size(390, 844),
      profile: _profile,
      groups: _groups,
      proxiesAction: proxies,
      profilesAction: profiles,
    );
    await tester.tap(find.text('更换'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('测试节点'));
    await tester.pump();
    expect(proxies.requests, [('线路组', '测试节点')]);
    expect(profiles.selections, isEmpty);
    proxies.request!.completeError(StateError('测试内核拒绝'));
    await tester.pumpAndSettle();
    expect(find.textContaining('测试内核拒绝'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('测试节点'));
    proxies.request!.complete();
    await tester.pumpAndSettle();
    expect(profiles.selections, [('线路组', '测试节点')]);
    expect(find.byType(RetroRoutesDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('自动策略组不提供虚假的单节点选择', (tester) async {
    final proxies = _Proxies();
    await mountHome(
      tester,
      const Size(390, 844),
      profile: _profile,
      groups: [
        const Group(
          name: '自动组',
          type: GroupType.URLTest,
          hidden: false,
          all: _nodes,
        ),
      ],
      proxiesAction: proxies,
    );
    await tester.tap(find.text('更换'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('测试节点'));
    expect(proxies.requests, isEmpty);
    expect(find.text('自动策略组，请在完整代理设置中管理'), findsWidgets);
  });

  testWidgets('直连模式先解释并允许切换模式，不错误跳转导入配置', (tester) async {
    final container = await mountHome(
      tester,
      const Size(390, 844),
      profile: _profile,
      groups: _groups,
    );
    container
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith(mode: Mode.direct));
    await tester.pumpAndSettle();
    await tester.tap(find.text('更换'));
    await tester.pumpAndSettle();
    expect(find.textContaining('直连模式不使用代理线路'), findsOneWidget);
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('规则')),
    );
    await tester.pumpAndSettle();
    expect(container.read(patchClashConfigProvider).mode, Mode.rule);
    expect(find.byType(RetroRoutesDialog), findsOneWidget);
  });
}
