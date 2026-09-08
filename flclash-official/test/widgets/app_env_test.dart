import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/manager/app_manager.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('正式环境配置不显示预发布角标', (tester) async {
    final environment =
        jsonDecode(File('env.example.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(environment['APP_ENV'], 'stable');
    globalState.appEnv = environment['APP_ENV'] as String;
    expect(globalState.isPre, isFalse);
    await tester.pumpWidget(
      const AppEnvManager(child: SizedBox(key: ValueKey('stable-content'))),
    );
    expect(find.byKey(const ValueKey('stable-content')), findsOneWidget);
    expect(find.byType(Banner), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
