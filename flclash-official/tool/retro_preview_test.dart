import 'dart:io';

import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/views/dashboard/classic_home.dart';
import 'package:fl_clash/views/dashboard/widgets/retro_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/pages/retro_home_test.dart' show mountHome;

void main() {
  setUpAll(() async {
    final font = Platform.environment['RETRO_PREVIEW_FONT'];
    if (font == null) throw StateError('请通过 RETRO_PREVIEW_FONT 指定中文字体文件');
    final data = ByteData.sublistView(await File(font).readAsBytes());
    for (final family in ['JetBrainsMono', 'Roboto', 'Ahem']) {
      await (FontLoader(family)..addFont(Future.value(data))).load();
    }
    final icons = Platform.environment['RETRO_PREVIEW_ICONS'];
    if (icons == null) {
      throw StateError('请通过 RETRO_PREVIEW_ICONS 指定 Material 图标字体');
    }
    await (FontLoader('MaterialIcons')..addFont(
          Future.value(ByteData.sublistView(await File(icons).readAsBytes())),
        ))
        .load();
  });

  for (final variant in [
    ('phone', const Size(390, 844)),
    ('landscape', const Size(844, 390)),
    ('tablet', const Size(1280, 800)),
  ]) {
    testWidgets('渲染复古主页 ${variant.$1}', (tester) async {
      await mountHome(tester, variant.$2);
      await expectLater(
        find.byType(ClassicHomeView),
        matchesGoldenFile('../docs/ui/retro-${variant.$1}.png'),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('渲染线路弹窗示例数据', (tester) async {
    await mountHome(
      tester,
      const Size(390, 844),
      profile: const Profile(
        id: 1,
        label: '演示配置',
        currentGroupName: '线路选择',
        autoUpdateDuration: Duration.zero,
        selectedMap: {'线路选择': '香港 · 示例线路'},
      ),
      groups: const [
        Group(
          name: '线路选择',
          type: GroupType.Selector,
          hidden: false,
          all: [
            Proxy(name: '香港 · 示例线路', type: 'Shadowsocks'),
            Proxy(name: '新加坡 · 示例线路', type: 'Trojan'),
            Proxy(name: '日本 · 长名称节点显示与换行示例', type: 'VMess'),
          ],
        ),
      ],
    );
    await tester.tap(find.text('更换'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(RetroRoutesDialog),
      matchesGoldenFile('../docs/ui/retro-routes.png'),
    );
    expect(tester.takeException(), isNull);
  });
}
