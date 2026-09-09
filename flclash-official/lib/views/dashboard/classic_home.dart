import 'dart:math' as math;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/home_motion.dart';
import 'widgets/retro_dashboard.dart';

const _blue = Color(0xFF3E5D9C);

class ClassicHomeView extends ConsumerWidget {
  final ValueChanged<PageLabel>? onOpenPage;

  const ClassicHomeView({super.key, this.onOpenPage});

  void _openPage(BuildContext context, WidgetRef ref, PageLabel page) {
    if (onOpenPage != null) {
      onOpenPage!(page);
      return;
    }
    ref.read(currentPageLabelProvider.notifier).toPage(page);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.appLocalizations;
    final running = ref.watch(isStartProvider);
    final groups = ref.watch(currentGroupsStateProvider).value;
    final mode = ref.watch(
      patchClashConfigProvider.select((value) => value.mode),
    );
    return HomeMotion(
      running: running,
      child: Scaffold(
        backgroundColor: _blue,
        appBar: AppBar(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          centerTitle: true,
          toolbarHeight: math.max(
            48,
            MediaQuery.textScalerOf(context).scale(20) + 20,
          ),
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'VPN',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          actions: [
            PopupMenuButton<Mode>(
              tooltip: strings.outboundMode,
              initialValue: mode,
              icon: const Icon(Icons.settings_outlined),
              onSelected: (value) =>
                  ref.read(setupActionProvider.notifier).changeMode(value),
              itemBuilder: (_) => [
                for (final item in Mode.values)
                  CheckedPopupMenuItem(
                    value: item,
                    checked: item == mode,
                    child: Text(switch (item) {
                      Mode.rule => strings.rule,
                      Mode.global => strings.global,
                      Mode.direct => strings.direct,
                    }),
                  ),
              ],
            ),
          ],
        ),
        drawer: Drawer(
          width: math.min(300, MediaQuery.sizeOf(context).width * .85),
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  height: 90,
                  color: _blue,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(24),
                  child: const Text(
                    'VPN',
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                ),
                for (final item in [
                  (
                    Icons.dashboard_outlined,
                    strings.dashboard,
                    PageLabel.dashboard,
                  ),
                  (Icons.folder_open, strings.profiles, PageLabel.profiles),
                  if (groups.isNotEmpty)
                    (Icons.public, strings.proxies, PageLabel.proxies),
                  (Icons.link, strings.connections, PageLabel.connections),
                  (Icons.build_outlined, strings.tools, PageLabel.tools),
                ])
                  ListTile(
                    leading: Icon(item.$1),
                    title: Text(item.$2),
                    onTap: () {
                      Navigator.of(context).pop();
                      _openPage(context, ref, item.$3);
                    },
                  ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 1120,
                    minHeight: constraints.maxHeight,
                  ),
                  child: RetroDashboardPanel(
                    provideMotion: false,
                    onOpenPage: (page) => _openPage(context, ref, page),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
